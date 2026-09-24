import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import 'package:allomom/features/reports/controller/reports_drive_controller.dart';
import 'package:allomom/features/reports/widgets/report_file_picker.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/report_db_service.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';
import 'package:allomom/services/report_parser/on_device_report_parser.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';

class AddReport extends StatefulWidget {
  final String? checklistId;
  final String? checklistName;

  const AddReport({super.key, this.checklistId, this.checklistName});

  @override
  State<AddReport> createState() => _AddReportState();
}

class _AddReportState extends State<AddReport> {
  final List<File> _selectedFiles = [];
  final TextEditingController reportName = TextEditingController();
  bool isSubmitting = false;
  bool _isAnalyzing = false;
  ParsedReportResult? _parsedResult;

  final TextEditingController description = TextEditingController();

  AppPalette get _p => context.palette;
  Color get _ink => _p.pick(const Color(0xFF1E2024), _p.textPrimary);
  Color get _slate => _p.pick(const Color(0xFF64748B), _p.textSecondary);
  Color get _body => _p.pick(const Color(0xFF475569), _p.textSecondary);
  Color get _muted => _p.pick(const Color(0xFF94A3B8), _p.textMuted);
  Color get _line => _p.pick(const Color(0xFFF0F1F5), _p.border);

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
    reportName.dispose();
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
      final parsed = await OnDeviceReportParser.instance.parseReport(
        targetFile,
      );

      if (!mounted) return;

      setState(() {
        _parsedResult = parsed;
        _isAnalyzing = false;

        // Auto-fill detected report name if the user hasn't typed one
        if (reportName.text.trim().isEmpty &&
            parsed.detectedReportType.isNotEmpty &&
            reportTypes.contains(parsed.detectedReportType)) {
          reportName.text = parsed.detectedReportType;
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

    if (reportName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a report name'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final session = MainController.instance;
      final userId = session.userId;
      final healthId = ReportDbService.localHealthScope(
        healthDataId: session.healthDataId,
        userId: userId,
      );

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
        if (_parsedResult!.date != null)
          detailData['report_date'] = _parsedResult!.date;
        if (_parsedResult!.patientName != null)
          detailData['patient_name'] = _parsedResult!.patientName;

        // Structured parameters for Test Results view
        _parsedResult!.testResults.forEach((key, val) {
          detailData[key] = val;
        });
      }

      // Local-only: the report is written straight to SQLite with synced = 0.
      final reportId = const Uuid().v4();
      final rRow = ReportsCompanion(
        id: drift.Value(reportId),
        reportType: drift.Value(reportName.text.trim()),
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
      //
      // The id is generated here rather than left to the database: it is also
      // the id the file is uploaded under, so a retry after a dropped upload
      // finds the same row instead of putting a second copy in the user's
      // Drive. (`report_attachments.id` has no default either, so an absent
      // one fails the insert outright.)
      for (final file in _selectedFiles) {
        await PregnancyCareDbService.instance.createReportAttachment(
          ReportAttachmentsCompanion(
            id: drift.Value(const Uuid().v4()),
            reportId: drift.Value(reportId),
            localPath: drift.Value(file.path),
            fileName: drift.Value(file.path.split('/').last),
            mimeType: drift.Value(reportMimeTypeFor(file.path)),
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
        // The checklist tracks whether a test is done; the file itself lives
        // on the report row saved above, which is why there is no path here.
        await PregnancyController.instance.setReportCompleted(
          checklistId,
          DateTime.now(),
        );
      }

      // The report is saved and the user is done; backing it up to Drive is
      // not something they should wait for, and it is a no-op when no Drive is
      // connected.
      ReportsDriveController.instance.syncNow();

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

  Future<void> _showImageSourceSheet() async {
    final picked = await pickReportFiles(context);
    if (picked.isEmpty || !mounted) return;
    setState(() => _selectedFiles.addAll(picked));
    _runOnDeviceAnalysis();
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
      backgroundColor: _p.scaffoldSoft,
      appBar: AppBar(
        title: Text(
          'Add Report',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _ink,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
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
                  color: _p.tint(
                    const Color(0xFFFF3B5C),
                    const Color(0xFFFFECEF),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF3B5C).withValues(alpha: 0.3),
                  ),
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
                        color: _ink,
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

            // On-Device OCR Analysis Status
            if (_isAnalyzing) _buildScanningCard(),

            const SizedBox(height: 24),

            // Report Name Selector
            Text(
              'Report Name',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _body,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: _p.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line, width: 1.2),
              ),
              child: TextFormField(
                controller: reportName,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter report name',
                  hintStyle: GoogleFonts.manrope(color: _muted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description / Clinical Notes
            Text(
              'Description / Clinical Notes',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _body,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _p.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _line, width: 1.2),
              ),
              child: TextFormField(
                controller: description,
                maxLines: 4,
                style: GoogleFonts.manrope(fontSize: 14, color: _ink),
                decoration: InputDecoration(
                  hintText:
                      'Enter clinical observations, lab values, or doctor remarks...',
                  hintStyle: GoogleFonts.manrope(color: _muted, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBottomBar() {
    final hasFiles = _selectedFiles.isNotEmpty;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: _p.card,
        boxShadow: [
          BoxShadow(
            color: _p.pick(Colors.black.withValues(alpha: 0.06), _p.shadow),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF3B5C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            onPressed: isSubmitting
                ? null
                : (hasFiles ? submit : _showImageSourceSheet),
            child: isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    hasFiles ? 'ADD REPORT' : 'UPLOAD REPORT',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanningCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _p.tint(const Color(0xFFFF3B5C), const Color(0xFFFFECEF)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF3B5C).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Color(0xFFFF3B5C),
              strokeWidth: 2.2,
            ),
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
                  style: GoogleFonts.manrope(fontSize: 11.5, color: _slate),
                ),
              ],
            ),
          ),
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
          color: _p.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _line, width: 1.2),
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
              decoration: BoxDecoration(
                color: _p.tint(
                  const Color(0xFFFF3B5C),
                  const Color(0xFFFFECEF),
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                size: 36,
                color: Color(0xFFFF3B5C),
              ),
            ),
            // const SizedBox(height: 14),
            // Text(
            //   'Upload Report',
            //   style: GoogleFonts.manrope(
            //     fontWeight: FontWeight.w800,
            //     fontSize: 16,
            //     color: _ink,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedFilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Attached Files',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _body,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _p.tint(
                  const Color(0xFFFF3B5C),
                  const Color(0xFFFFECEF),
                ),
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
        const SizedBox(height: 12),
        if (_selectedFiles.length == 1)
          _buildSingleFilePreview(_selectedFiles[0], 0)
        else
          _buildMultiFilesPreview(),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B5C),
              backgroundColor: const Color(0xFFFF3B5C).withValues(alpha: 0.08),
              side: const BorderSide(color: Color(0xFFFF3B5C), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _showImageSourceSheet,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              'Add More',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
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
          color: _p.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE11D48).withValues(alpha: 0.4),
            width: 1.5,
          ),
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
                    color: _p.tint(
                      const Color(0xFFE11D48),
                      const Color(0xFFFFE4E6),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Color(0xFFE11D48),
                    size: 36,
                  ),
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
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$fileSize • PDF Document',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _removeFile(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _p.pick(const Color(0xFFF1F5F9), _p.surface),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 18, color: _slate),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => OpenFilex.open(file.path),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: Text(
                  'Preview PDF',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
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
        color: _p.card,
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
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 18,
                ),
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
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
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
        itemCount: _selectedFiles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          final isPdf = _isPdf(file.path);
          final fileName = _getFileName(file.path);
          final fileSize = _getFileSize(file);

          return Container(
            width: 140,
            decoration: BoxDecoration(
              color: _p.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isPdf
                    ? const Color(0xFFE11D48).withValues(alpha: 0.5)
                    : _line,
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
                              color: _p.pick(
                                const Color(0xFFFFE4E6).withValues(alpha: 0.5),
                                const Color(0xFFE11D48).withValues(alpha: 0.12),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.picture_as_pdf_rounded,
                                    color: Color(0xFFE11D48),
                                    size: 36,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
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
                              color: _ink,
                            ),
                          ),
                          if (fileSize.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              fileSize,
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                color: _muted,
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
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
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
