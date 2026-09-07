import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/report_db_service.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';
import 'package:allomom/services/report_parser/on_device_report_parser.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class AddReport extends StatefulWidget {
  final String? checklistId;
  final String? checklistName;

  const AddReport({
    super.key,
    this.checklistId,
    this.checklistName,
  });

  @override
  State<AddReport> createState() => _AddReportState();
}

class _AddReportState extends State<AddReport> {
  final List<File> _selectedFiles = [];
  String? reportType;
  bool isSubmitting = false;
  bool _isAnalyzing = false;
  ParsedReportResult? _parsedResult;

  final TextEditingController description = TextEditingController();

  final List<String> reportTypes = [
    'Hemoglobin (Hb) Report',
    'Complete Blood Count (CBC)',
    'Blood Test',
    'Urine Test',
    'Thyroid Report',
    'Blood Glucose / Sugar',
    'Liver Function Test (LFT)',
    'Kidney Function (KFT)',
    'Lipid Profile',
    'Beta HCG Report',
    'Ultrasound Scan',
    'ECG',
    'x-ray',
    'CT Scan',
    'Mammogram',
    'MRI',
    'Lab Test',
    'Others',
  ];

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  bool _isPdf(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  String _getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

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
      // Analyze the most recently selected file
      final targetFile = _selectedFiles.last;
      final parsed = await OnDeviceReportParser.instance.parseReport(targetFile);

      if (!mounted) return;

      setState(() {
        _parsedResult = parsed;
        _isAnalyzing = false;

        // Auto-select detected report type if matching
        if (parsed.detectedReportType.isNotEmpty && reportTypes.contains(parsed.detectedReportType)) {
          reportType = parsed.detectedReportType;
        }

        // Auto-fill description with the generated clinical summary
        description.text = parsed.summary;
      });
    } catch (e) {
      debugPrint('Error running on-device analysis: $e');
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> submit() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an image or PDF report'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (reportType == null || reportType!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a report type'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final session = UserSessionManager.instance;
      final userId = session.userId;
      final healthId = session.healthDataId.isNotEmpty
          ? session.healthDataId
          : (userId.isNotEmpty ? userId : 'health_me');

      final filePaths = _selectedFiles.map((f) => f.path).toList();
      final primaryFile = filePaths.first;

      final Map<String, dynamic> detailData = {
        'files': filePaths,
        'file_count': filePaths.length,
        'has_pdf': filePaths.any((p) => _isPdf(p)),
      };

      if (_parsedResult != null) {
        detailData['ocr_summary'] = _parsedResult!.summary;
        detailData['raw_ocr_text'] = _parsedResult!.rawText;
        detailData['detected_type'] = _parsedResult!.detectedReportType;
        if (_parsedResult!.date != null) detailData['report_date'] = _parsedResult!.date;
        if (_parsedResult!.patientName != null) detailData['patient_name'] = _parsedResult!.patientName;

        // Structured parameters for Test Results view
        _parsedResult!.testResults.forEach((key, val) {
          detailData[key] = val;
        });
      }

      // Local-only: the report is written straight to SQLite with synced = 0.
      final reportId = const Uuid().v4();
      final rRow = ReportsCompanion(
        id: drift.Value(reportId),
        reportType: drift.Value(reportType!),
        description: drift.Value(description.text.trim()),
        imageUrl: drift.Value(primaryFile),
        detail: drift.Value(jsonEncode(detailData)),
        healthDataID: drift.Value(healthId),
        createdBy: drift.Value(userId.isEmpty ? null : userId),
        saved: const drift.Value(true),
        createdAt: drift.Value(DateTime.now()),
        synced: const drift.Value(0),
      );
      await ReportDbService.instance.saveReport(rRow);

      // Record every picked file as an attachment row so the report keeps
      // track of all of them, not just the primary one.
      for (final file in _selectedFiles) {
        await PregnancyCareDbService.instance.createReportAttachment(
          ReportAttachmentsCompanion(
            reportId: drift.Value(reportId),
            localPath: drift.Value(file.path),
            fileName: drift.Value(file.path.split('/').last),
            mimeType: drift.Value(_isPdf(file.path) ? 'application/pdf' : 'image/*'),
            fileSizeBytes: drift.Value(
              file.existsSync() ? file.lengthSync() : null,
            ),
            synced: const drift.Value(0),
          ),
        );
      }

      // Close out the checklist entry this report was filed against.
      final checklistId = widget.checklistId;
      if (checklistId != null && checklistId.isNotEmpty) {
        await PregnancyCareDbService.instance.updateReportChecklist(
          ReportChecklistsCompanion(
            id: drift.Value(checklistId),
            status: const drift.Value('done'),
            completedDate: drift.Value(DateTime.now()),
            filePath: drift.Value(primaryFile),
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report analyzed & saved successfully! 📋✨'),
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
            content: Text('Error saving report: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
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
                'Upload Report Files',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose photos or PDF documents',
                style: GoogleFonts.manrope(
                  fontSize: 12.5,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    sublabel: 'Take photo',
                    color: const Color(0xFFFF3B5C),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _pickFromCamera();
                    },
                  ),
                  _buildSourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    sublabel: 'Multi images',
                    color: const Color(0xFF3898EC),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      _pickFromGallery();
                    },
                  ),
                  _buildSourceButton(
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

  Widget _buildSourceButton({
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
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: const Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _selectedFiles.add(File(picked.path));
        });
        _runOnDeviceAnalysis();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final pickedList = await picker.pickMultiImage(imageQuality: 85);
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
          SnackBar(content: Text('Error selecting images: $e')),
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
        final newFiles = result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
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
          SnackBar(content: Text('Error selecting document: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: AppBar(
        title: Text(
          'Add Report',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF1E2024),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E2024), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.checklistId != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF3B5C).withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Lab Test Checklist',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF3B5C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.checklistName ?? '',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Upload / Preview Section
            if (_selectedFiles.isEmpty)
              _buildEmptyUploadCard()
            else
              _buildSelectedFilesSection(),

            // On-Device OCR Analysis Status / Results Card
            if (_isAnalyzing)
              _buildScanningCard()
            else if (_parsedResult != null)
              _buildOcrInsightsCard(),

            const SizedBox(height: 24),

            // Report Type Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Report Type',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                if (_parsedResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Auto-detected by OCR',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: reportType,
                  hint: Text(
                    'Select Type of Report',
                    style: GoogleFonts.manrope(color: const Color(0xFF94A3B8), fontSize: 14),
                  ),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                  items: reportTypes.map((t) {
                    return DropdownMenuItem<String>(
                      value: t,
                      child: Text(
                        t,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E2024),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => reportType = val),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description / Clinical Notes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Description / Clinical Notes',
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
                        color: const Color(0xFFFF3B5C),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
              ),
              child: TextFormField(
                controller: description,
                maxLines: 4,
                style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1E2024)),
                decoration: InputDecoration(
                  hintText: 'Enter clinical observations, lab values, or doctor remarks...',
                  hintStyle: GoogleFonts.manrope(color: const Color(0xFF94A3B8), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B5C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: isSubmitting ? null : submit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'ADD REPORT',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
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
        border: Border.all(color: const Color(0xFFFF3B5C).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(color: Color(0xFFFF3B5C), strokeWidth: 2.2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'On-Device OCR Parsing...',
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF3B5C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Extracting medical values and analyzing report offline',
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
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
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                const SizedBox(width: 6),
                Text(
                  'Identified Report: ${res.detectedReportType}',
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2024),
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
          if (res.testResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: res.testResults.entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFF3B5C).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${entry.key} = ${entry.value}',
                    style: GoogleFonts.manrope(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF3B5C),
                    ),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFFFECEF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload_rounded, size: 36, color: Color(0xFFFF3B5C)),
            ),
            const SizedBox(height: 16),
            Text(
              'Upload Medical Report or PDF',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: const Color(0xFF1E2024),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to choose camera, multi-images or PDF files\nAI On-Device OCR extracts test findings automatically',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 12,
                height: 1.4,
                color: const Color(0xFF94A3B8),
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
                  'Attached Files',
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
                    color: const Color(0xFFFFECEF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_selectedFiles.length}',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFFF3B5C),
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
                  color: const Color(0xFFFF3B5C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, size: 16, color: Color(0xFFFF3B5C)),
                    const SizedBox(width: 4),
                    Text(
                      'Add More',
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF3B5C),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
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
                          color: const Color(0xFF1E2024),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$fileSize • PDF Document',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF3B5C), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: Colors.white,
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
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFECEF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, size: 24, color: Color(0xFFFF3B5C)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add More',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: const Color(0xFF64748B),
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
              color: Colors.white,
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
                              color: const Color(0xFF1E2024),
                            ),
                          ),
                          if (fileSize.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              fileSize,
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                color: const Color(0xFF94A3B8),
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
}
