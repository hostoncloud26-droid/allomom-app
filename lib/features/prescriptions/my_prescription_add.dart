import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;

import 'package:allomom/services/api/prescription_api.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/prescription_db_service.dart';
import 'package:allomom/local_notification/services/local_reminder_scheduler.dart';
import 'package:allomom/services/prescription_parser/on_device_prescription_parser.dart';

class MyPrescriptionAdd extends StatefulWidget {
  const MyPrescriptionAdd({super.key});

  @override
  State<MyPrescriptionAdd> createState() => _MyPrescriptionAddState();
}

class _MyPrescriptionAddState extends State<MyPrescriptionAdd>
    with TickerProviderStateMixin {
  final List<File> _selectedFiles = [];
  bool isSubmitting = false;
  bool _isAnalyzing = false;
  int _currentStep = 0;
  ParsedPrescriptionResult? _parsedResult;

  final TextEditingController description = TextEditingController();
  DateTime? medicineStartDate;
  final List<_MedicineFormItem> medicines = [_MedicineFormItem()];

  // Design Tokens
  Color get primaryColor => const Color(0xFFFF3B5C);
  Color get primaryGradientEnd => const Color(0xFFFF5277);
  Color get bgColor => const Color(0xFFFBFBFC);
  Color get surfaceLow => const Color(0xFFF1F5F9);
  Color get surfaceLowest => Colors.white;
  Color get surfaceHighest => const Color(0xFFE2E8F0);
  Color get onSurface => const Color(0xFF1E2024);
  Color get onSurfaceVar => const Color(0xFF64748B);
  static const double radiusXL = 28.0;

  BoxShadow get ambientShadow => BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 20,
        offset: const Offset(0, 6),
      );

  @override
  void dispose() {
    description.dispose();
    for (final item in medicines) {
      item.dispose();
    }
    super.dispose();
  }

  bool _isPdf(String path) => path.toLowerCase().endsWith('.pdf');

  String _getFileName(String path) => path.split(Platform.pathSeparator).last;

  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }

  Future<void> _runOnDeviceAnalysis() async {
    if (_selectedFiles.isEmpty) return;

    setState(() => _isAnalyzing = true);
    try {
      final targetFile = _selectedFiles.last;
      final parsed = await OnDevicePrescriptionParser.instance.parsePrescription(targetFile);

      if (!mounted) return;

      setState(() {
        _parsedResult = parsed;
        _isAnalyzing = false;

        // Auto-fill description/summary
        if (parsed.summary.isNotEmpty) {
          description.text = parsed.summary;
        }

        // Auto-populate medicines in the form
        if (parsed.medicines.isNotEmpty) {
          // Dispose any existing items
          for (final item in medicines) {
            item.dispose();
          }
          medicines.clear();

          for (final med in parsed.medicines) {
            final formItem = _MedicineFormItem();
            formItem.nameController.text = med.name;
            formItem.notesController.text = '${med.dosage} • ${med.mealInstruction}';
            formItem.durationDaysController.text = '${med.durationDays}';
            formItem.times = List<TimeOfDay>.from(med.times);
            medicines.add(formItem);
          }
        }
      });

      if (parsed.medicines.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✨ Extracted ${parsed.medicines.length} medications from prescription!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error analyzing prescription: $e');
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> submit() async {
    final startDate = medicineStartDate ?? DateTime.now();
    final preparedMedicines = _buildMedicinePayload(startDate);

    if (preparedMedicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one medicine'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    for (final item in medicines) {
      if (item.times.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please set at least one timing for ${item.nameController.text.isEmpty ? "each medicine" : item.nameController.text}',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => isSubmitting = true);
    try {
      final session = UserSessionManager.instance;
      final primaryFile = _selectedFiles.isNotEmpty ? _selectedFiles.first.path : null;

      final response = await PrescriptionApi.addPrescriptionOneShot({
        'description': description.text.trim().isEmpty ? null : description.text.trim(),
        'imageUrl': primaryFile,
        'medicine_start_date': startDate.toIso8601String(),
        'user_id': session.userId,
        'medicines': preparedMedicines,
      });

      final prescriptionId = response.item is Map
          ? (response.item['id']?.toString() ?? '')
          : 'presc_${DateTime.now().millisecondsSinceEpoch}';

      // Persist to SQLite Drift DB
      final healthId = session.currentHealthData?.id ?? (session.userId.isNotEmpty ? session.userId : 'health_me');
      final desc = description.text.trim().isNotEmpty ? description.text.trim() : 'Prescription';

      final pRow = PrescriptionsCompanion(
        id: drift.Value(prescriptionId),
        healthId: drift.Value(healthId),
        description: drift.Value(desc),
        imageUrl: drift.Value(primaryFile),
        createdAt: drift.Value(DateTime.now()),
      );

      final medRows = <PrescriptionMedicinesCompanion>[];
      for (final item in medicines) {
        final name = item.nameController.text.trim();
        if (name.isEmpty) continue;
        final durationDays = int.tryParse(item.durationDaysController.text.trim()) ?? 7;
        final medId = 'med_${DateTime.now().millisecondsSinceEpoch}_$name';

        final timeStrings = item.times.map((t) {
          final hh = t.hour.toString().padLeft(2, '0');
          final mm = t.minute.toString().padLeft(2, '0');
          return '$hh:$mm';
        }).toList();

        medRows.add(
          PrescriptionMedicinesCompanion(
            id: drift.Value(medId),
            prescriptionId: drift.Value(prescriptionId),
            medicineName: drift.Value(name),
            dosage: drift.Value(item.notesController.text.trim().isNotEmpty ? item.notesController.text.trim() : '1 Tablet'),
            durationDays: drift.Value(durationDays),
            timings: drift.Value(timeStrings.join(',')),
            notes: drift.Value(item.notesController.text.trim()),
            healthId: drift.Value(healthId),
            userId: drift.Value(session.userId),
          ),
        );
      }

      await PrescriptionDbService.instance.savePrescription(pRow, medRows);

      // Schedule local notifications for each dose
      int notifCounter = 0;
      for (final item in medicines) {
        final name = item.nameController.text.trim();
        if (name.isEmpty) continue;
        final durationDays = int.tryParse(item.durationDaysController.text.trim()) ?? 7;

        for (int day = 0; day < durationDays; day++) {
          final currentDay = startDate.add(Duration(days: day));
          for (final time in item.times) {
            final timingDateTime = DateTime(
              currentDay.year,
              currentDay.month,
              currentDay.day,
              time.hour,
              time.minute,
            );

            await LocalReminderScheduler.scheduleMedicationReminder(
              id: notifCounter++,
              medicineName: name,
              dosage: item.notesController.text.trim().isNotEmpty ? item.notesController.text.trim() : '1 Tablet',
              mealInstruction: item.notesController.text.trim(),
              dateTime: timingDateTime,
              timingId: '${prescriptionId}_${name}_$day',
            );
          }
        }
      }

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription & reminders saved successfully! 🎉'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving prescription: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  List<Map<String, dynamic>> _buildMedicinePayload(DateTime startDate) {
    final result = <Map<String, dynamic>>[];
    for (final item in medicines) {
      final name = item.nameController.text.trim();
      if (name.isEmpty) continue;

      final durationDays = int.tryParse(item.durationDaysController.text.trim()) ?? 1;
      final generatedTimings = <String>[];

      for (int i = 0; i < durationDays; i++) {
        final currentDay = startDate.add(Duration(days: i));
        for (final time in item.times) {
          final timingDateTime = DateTime(
            currentDay.year,
            currentDay.month,
            currentDay.day,
            time.hour,
            time.minute,
          );
          generatedTimings.add(timingDateTime.toIso8601String());
        }
      }

      result.add({
        'name': name,
        'notes': item.notesController.text.trim(),
        'timings': generatedTimings,
        'durationDays': durationDays,
      });
    }
    return result;
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Upload Prescription',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose photos or PDF documents',
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  color: onSurfaceVar,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPhotoSourceTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    sublabel: 'Take photo',
                    color: primaryColor,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _pickFromCamera();
                    },
                  ),
                  _buildPhotoSourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    sublabel: 'Multi images',
                    color: const Color(0xFF3898EC),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _pickFromGallery();
                    },
                  ),
                  _buildPhotoSourceTile(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'PDF / Docs',
                    sublabel: 'Upload files',
                    color: const Color(0xFFE11D48),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _pickPdfDocument();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSourceTile({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: onSurfaceVar,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _selectedFiles.add(File(picked.path));
        });
        _runOnDeviceAnalysis();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final pickedList = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (pickedList.isNotEmpty) {
        setState(() {
          for (final item in pickedList) {
            _selectedFiles.add(File(item.path));
          }
        });
        _runOnDeviceAnalysis();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting photos: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _pickPdfDocument() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.isNotEmpty) {
        final newFiles = result.files.where((f) => f.path != null).map((f) => File(f.path!)).toList();
        if (newFiles.isNotEmpty) {
          setState(() {
            _selectedFiles.addAll(newFiles);
          });
          _runOnDeviceAnalysis();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking document: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      if (_selectedFiles.isEmpty) {
        _parsedResult = null;
      }
    });
  }

  void _addMedicine() {
    HapticFeedback.lightImpact();
    setState(() => medicines.add(_MedicineFormItem()));
  }

  void _removeMedicine(int index) {
    if (medicines.length <= 1) return;
    setState(() {
      medicines[index].dispose();
      medicines.removeAt(index);
    });
  }

  Future<void> _pickStartDate() async {
    DateTime initial = medicineStartDate ?? DateTime.now();
    DateTime first = DateTime.now().subtract(const Duration(days: 365));
    DateTime last = DateTime.now().add(const Duration(days: 365 * 2));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => medicineStartDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.manropeTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: onSurface, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Add Prescription',
            style: GoogleFonts.manrope(
              color: onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildStepperHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: _buildCurrentStepContent(),
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    final medCount = medicines.where((m) => m.nameController.text.trim().isNotEmpty).length;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: [
          _stepIndicator(0, 'Upload & OCR'),
          _stepLine(0),
          _stepIndicator(1, medCount > 0 ? 'Medicines ($medCount)' : 'Medicines'),
        ],
      ),
    );
  }

  Widget _stepIndicator(int step, String label) {
    bool isActive = _currentStep >= step;
    bool isCompleted = _currentStep > step;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF10B981)
                : isActive
                    ? primaryColor
                    : surfaceHighest,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : onSurfaceVar,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? primaryColor : onSurfaceVar,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(int step) {
    bool isActive = _currentStep > step;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Container(
          height: 2,
          color: isActive ? primaryColor : surfaceHighest,
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedFiles.isEmpty)
              _buildEmptyUploadCard()
            else
              _buildSelectedFilesSection(),

            if (_isAnalyzing)
              _buildScanningCard()
            else if (_parsedResult != null)
              _buildOcrInsightsCard(),

            const SizedBox(height: 24),
            _buildAdditionalInfoSection(),
            const SizedBox(height: 28),
            _buildInfoCard(
              'On-Device Tablet Extraction',
              'AI recognizes medicine names, strengths (e.g. 500mg), doses, and frequencies automatically.',
              Icons.auto_awesome_rounded,
            ),
            const SizedBox(height: 14),
            _buildInfoCard(
              'Smart Reminders',
              'Medication schedules and push reminders are created for your daily doses.',
              Icons.alarm_on_rounded,
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_parsedResult != null && _parsedResult!.medicines.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Extracted ${_parsedResult!.medicines.length} medications from prescription. You can edit any details below.',
                        style: GoogleFonts.manrope(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            _buildMedicinesList(),
            const SizedBox(height: 20),
            _buildAddMedicineButton(),
            const SizedBox(height: 20),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInfoCard(String title, String desc, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F1F5)),
        boxShadow: [ambientShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: onSurfaceVar, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: primaryColor, strokeWidth: 2.2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'On-Device OCR Scanning Prescription...',
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Extracting tablet names, dosages, and timings offline',
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    color: onSurfaceVar,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOcrInsightsCard() {
    final res = _parsedResult!;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'On-Device OCR Insights',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Offline AI',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _runOnDeviceAnalysis,
                child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.medication_rounded, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 6),
                Text(
                  res.medicines.isNotEmpty
                      ? 'Detected ${res.medicines.length} Medications'
                      : 'No tablets identified automatically',
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            res.summary,
            style: GoogleFonts.manrope(
              fontSize: 12.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
          if (res.medicines.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: res.medicines.map((med) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline, size: 13, color: primaryColor),
                      const SizedBox(width: 5),
                      Text(
                        '${med.name} (${med.frequencyLabel})',
                        style: GoogleFonts.manrope(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyUploadCard() {
    return GestureDetector(
      onTap: _showImageSourceSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: surfaceLowest,
          borderRadius: BorderRadius.circular(radiusXL),
          boxShadow: [ambientShadow],
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_upload_rounded, size: 36, color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Upload Prescription or PDF',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to choose camera, multi-images or PDF files\nAI On-Device OCR extracts tablets, doses & timings automatically',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12,
                height: 1.4,
                color: onSurfaceVar,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTypeBadge(Icons.camera_alt_outlined, 'Camera'),
                const SizedBox(width: 8),
                _buildTypeBadge(Icons.photo_library_outlined, 'Multi-Images'),
                const SizedBox(width: 8),
                _buildTypeBadge(Icons.picture_as_pdf_outlined, 'PDFs'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Attached Prescriptions',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_selectedFiles.length}',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Add More',
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_selectedFiles.length == 1)
          _buildSingleFilePreview(_selectedFiles[0], 0)
        else
          _buildMultiFilesPreview(),
      ],
    );
  }

  Widget _buildSingleFilePreview(File file, int index) {
    final isPdf = _isPdf(file.path);
    final fileName = _getFileName(file.path);
    final fileSize = _getFileSize(file);

    if (isPdf) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceLowest,
          borderRadius: BorderRadius.circular(radiusXL),
          border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.4), width: 1.5),
          boxShadow: [ambientShadow],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE11D48), size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          color: onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$fileSize • PDF Document',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: onSurfaceVar,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeFile(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE11D48),
                  side: const BorderSide(color: Color(0xFFE11D48)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => OpenFilex.open(file.path),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: Text(
                  'Preview PDF',
                  style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: BorderRadius.circular(radiusXL),
        border: Border.all(color: primaryColor, width: 1.5),
        boxShadow: [ambientShadow],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(file, fit: BoxFit.cover),
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: () => _removeFile(index),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
              child: Text(
                fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiFilesPreview() {
    return SizedBox(
      height: 175,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _selectedFiles.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          if (index == _selectedFiles.length) {
            return GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  color: surfaceLowest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFCBD5E1),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded, size: 24, color: primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add More',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: onSurfaceVar,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final file = _selectedFiles[index];
          final isPdf = _isPdf(file.path);
          final fileName = _getFileName(file.path);
          final fileSize = _getFileSize(file);

          return Container(
            width: 140,
            decoration: BoxDecoration(
              color: surfaceLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPdf ? const Color(0xFFE11D48).withValues(alpha: 0.5) : const Color(0xFFF0F1F5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: isPdf
                          ? Container(
                              width: double.infinity,
                              color: const Color(0xFFFFE4E6).withValues(alpha: 0.5),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE11D48), size: 36),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE11D48),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'PDF',
                                      style: GoogleFonts.manrope(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: Image.file(file, fit: BoxFit.cover),
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              color: onSurface,
                            ),
                          ),
                          if (fileSize.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              fileSize,
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                color: onSurfaceVar,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => _removeFile(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomControls() {
    final isLastStep = _currentStep == 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(radiusXL)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _customButton(
                  onPressed: () => setState(() => _currentStep -= 1),
                  label: 'Back',
                  isPrimary: false,
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: _customButton(
              onPressed: isSubmitting ? null : _handleContinue,
              label: isLastStep ? 'Save Prescription' : 'Continue',
              isPrimary: true,
              isLoading: isSubmitting && isLastStep,
            ),
          ),
          if (_currentStep == 0)
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: _customButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  label: 'Skip',
                  isPrimary: false,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleContinue() {
    if (_currentStep == 0) {
      setState(() => _currentStep += 1);
    } else {
      final preparedMedicines = _buildMedicinePayload(medicineStartDate ?? DateTime.now());
      if (preparedMedicines.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one medicine'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      for (final item in medicines) {
        if (item.nameController.text.trim().isNotEmpty && item.times.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please set timings for ${item.nameController.text}'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }
      submit();
    }
  }

  Widget _customButton({
    required VoidCallback? onPressed,
    required String label,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? primaryColor : surfaceLow,
          foregroundColor: isPrimary ? Colors.white : onSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                label,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Doctor / Clinical Notes',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
            ),
            if (_parsedResult != null)
              GestureDetector(
                onTap: () {
                  setState(() {
                    description.text = _parsedResult!.summary;
                  });
                },
                child: Text(
                  'Reset to AI Summary',
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: surfaceLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          ),
          child: TextFormField(
            controller: description,
            maxLines: 3,
            style: GoogleFonts.manrope(fontSize: 14, color: onSurface),
            decoration: InputDecoration(
              hintText: 'Doctor remarks, clinic name, or notes...',
              hintStyle: GoogleFonts.manrope(color: const Color(0xFF94A3B8), fontSize: 13),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Medication Start Date',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickStartDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: surfaceLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: primaryColor, size: 18),
                const SizedBox(width: 12),
                Text(
                  medicineStartDate != null
                      ? DateFormat('EEE, dd MMM yyyy').format(medicineStartDate!)
                      : 'Today (${DateFormat('dd MMM yyyy').format(DateTime.now())})',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: onSurface,
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down_rounded, color: onSurfaceVar),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicinesList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: medicines.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) => _buildMedicineCard(medicines[index], index),
    );
  }

  Widget _buildMedicineCard(_MedicineFormItem item, int index) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceLowest,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
        boxShadow: [ambientShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.medication_rounded, color: primaryColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Medicine #${index + 1}',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
              if (medicines.length > 1)
                GestureDetector(
                  onTap: () => _removeMedicine(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delete_outline_rounded, color: primaryColor, size: 18),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Medicine Name & Strength',
            style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 6),
          _customTextField(
            controller: item.nameController,
            label: 'e.g. Dolo 650mg, Folvite 5mg',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dosage / Meal',
                      style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    _customTextField(
                      controller: item.notesController,
                      label: 'e.g. 1 Tablet • After Food',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Days',
                      style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    _customTextField(
                      controller: item.durationDaysController,
                      label: '7',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Daily Dosage Timings (${item.times.length} times/day)',
            style: GoogleFonts.manrope(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...item.times.asMap().entries.map((entry) {
                final tIndex = entry.key;
                final time = entry.value;
                return GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: time,
                    );
                    if (picked != null) {
                      setState(() {
                        item.times[tIndex] = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: surfaceLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: surfaceHighest),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          time.format(context),
                          style: GoogleFonts.manrope(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: onSurface,
                          ),
                        ),
                        if (item.times.length > 1) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                item.times.removeAt(tIndex);
                              });
                            },
                            child: const Icon(Icons.close_rounded, size: 14, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 12, minute: 0),
                  );
                  if (picked != null) {
                    setState(() {
                      item.times.add(picked);
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 14, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Add Dose',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddMedicineButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: _addMedicine,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          'Add Another Medicine',
          style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _customTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceLow,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.manrope(fontSize: 13.5, fontWeight: FontWeight.w600, color: onSurface),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: GoogleFonts.manrope(fontSize: 12.5, color: const Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }
}

class _MedicineFormItem {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController durationDaysController = TextEditingController(text: '7');
  List<TimeOfDay> times = [const TimeOfDay(hour: 8, minute: 0)];

  void updateFrequency(int count) {
    if (count > times.length) {
      for (int i = times.length; i < count; i++) {
        int hour = 8 + (i * 4);
        if (hour >= 24) hour = hour % 24;
        times.add(TimeOfDay(hour: hour, minute: 0));
      }
    } else if (count < times.length) {
      times = times.sublist(0, count);
    }
  }

  void dispose() {
    nameController.dispose();
    notesController.dispose();
    durationDaysController.dispose();
  }
}
