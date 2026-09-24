import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import 'package:allomom/features/reports/controller/reports_drive_controller.dart';
import 'package:allomom/features/reports/widgets/report_file_picker.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/report_db_service.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';
import 'package:drift/drift.dart' as drift;

class EditReport extends StatefulWidget {
  final Map<String, dynamic> reportDetails;

  const EditReport({super.key, required this.reportDetails});

  @override
  State<EditReport> createState() => _EditReportState();
}

/// One file shown on the edit screen.
///
/// [attachment] is null for a file picked on this screen and not yet saved,
/// and for reports from before files were tracked as rows. [path] is empty
/// while a Drive-only file is still being fetched.
class _EditFile {
  String path;
  final ReportAttachment? attachment;

  _EditFile(this.path, {this.attachment});

  String get name {
    final fromRow = attachment?.fileName;
    if (fromRow != null && fromRow.isNotEmpty) return fromRow;
    return path.split(Platform.pathSeparator).last;
  }

  bool get isPdf =>
      (attachment?.mimeType == 'application/pdf') ||
      name.toLowerCase().endsWith('.pdf');
}

class _EditReportState extends State<EditReport> {
  late TextEditingController reportNameController;
  late TextEditingController descriptionController;
  bool isSaving = false;

  final List<_EditFile> _files = [];
  final List<ReportAttachment> _removed = [];
  bool _loadingFiles = true;

  AppPalette get _p => context.palette;
  Color get _ink => _p.pick(const Color(0xFF1E2024), _p.textPrimary);
  Color get _body => _p.pick(const Color(0xFF475569), _p.textSecondary);
  Color get _muted => _p.pick(const Color(0xFF94A3B8), _p.textMuted);
  Color get _line => _p.pick(const Color(0xFFF0F1F5), _p.border);

  String get _reportId => widget.reportDetails['id']?.toString() ?? '';

  Map<String, dynamic> get _detail {
    final raw = widget.reportDetails['detail'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        return Map<String, dynamic>.from(jsonDecode(raw));
      } catch (_) {}
    }
    return {};
  }

  @override
  void initState() {
    super.initState();
    reportNameController = TextEditingController(text: widget.reportDetails['report_type']?.toString() ?? '');
    descriptionController = TextEditingController(text: widget.reportDetails['description']?.toString() ?? '');
    _loadFiles();
  }

  @override
  void dispose() {
    reportNameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    List<ReportAttachment> attachments = const [];
    if (_reportId.isNotEmpty) {
      try {
        attachments = await ReportDbService.instance.attachmentsFor(_reportId);
      } catch (e) {
        debugPrint('EditReport: could not read attachments: $e');
      }
    }
    if (!mounted) return;

    setState(() {
      if (attachments.isNotEmpty) {
        for (final a in attachments) {
          final onDevice = a.localPath.isNotEmpty && File(a.localPath).existsSync();
          _files.add(_EditFile(onDevice ? a.localPath : '', attachment: a));
        }
      } else {
        // Reports saved before files were tracked as rows only have paths.
        final paths = (_detail['files'] as List? ?? [])
            .map((f) => f?.toString() ?? '')
            .where((f) => f.isNotEmpty)
            .toList();
        final mainImg = widget.reportDetails['imageUrl']?.toString() ?? '';
        if (paths.isEmpty && mainImg.isNotEmpty) paths.add(mainImg);
        _files.addAll(paths.map(_EditFile.new));
      }
      _loadingFiles = false;
    });

    // Files held only in Drive are fetched so they can be previewed.
    for (final file in _files.where((f) => f.path.isEmpty && f.attachment != null).toList()) {
      final fetched = await ReportsDriveController.instance.attachmentFile(file.attachment!);
      if (fetched == null || !mounted) continue;
      setState(() => file.path = fetched.path);
    }
  }

  Future<void> _addFiles() async {
    final picked = await pickReportFiles(context);
    if (picked.isEmpty || !mounted) return;
    setState(() => _files.addAll(picked.map((f) => _EditFile(f.path))));
  }

  void _removeFile(_EditFile file) {
    setState(() {
      _files.remove(file);
      if (file.attachment != null) _removed.add(file.attachment!);
    });
  }

  Future<void> _saveReport() async {
    if (_reportId.isEmpty) return;

    if (reportNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a report name'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please keep at least one image or PDF'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isSaving = true);
    try {
      final drive = ReportsDriveController.instance;
      for (final attachment in _removed) {
        await drive.deleteAttachment(attachment);
      }

      // Every file without a row gets one — new picks, and the files of a
      // report from before rows existed. The view screen reads only the rows
      // once any exist, so a legacy report is moved over whole, never half.
      for (final file in _files.where((f) => f.attachment == null && f.path.isNotEmpty && !f.path.startsWith('http'))) {
        final onDisk = File(file.path);
        await PregnancyCareDbService.instance.createReportAttachment(
          ReportAttachmentsCompanion(
            id: drift.Value(const Uuid().v4()),
            reportId: drift.Value(_reportId),
            localPath: drift.Value(file.path),
            fileName: drift.Value(file.name),
            mimeType: drift.Value(reportMimeTypeFor(file.path)),
            fileSizeBytes: drift.Value(onDisk.existsSync() ? onDisk.lengthSync() : null),
            synced: const drift.Value(0),
          ),
        );
      }

      final paths = _files.map((f) => f.path).where((p) => p.isNotEmpty).toList();
      final detail = _detail
        ..['files'] = paths
        ..['file_count'] = _files.length
        ..['has_pdf'] = _files.any((f) => f.isPdf);

      // Local-only: written straight to SQLite with synced = 0.
      final rRow = ReportsCompanion(
        id: drift.Value(_reportId),
        reportType: drift.Value(reportNameController.text.trim()),
        description: drift.Value(descriptionController.text.trim()),
        imageUrl: paths.isNotEmpty ? drift.Value(paths.first) : const drift.Value.absent(),
        detail: drift.Value(jsonEncode(detail)),
      );
      await ReportDbService.instance.updateReport(rRow);

      // New files and removals reach Drive in the background.
      drive.syncNow();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report updated successfully! ✨'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating report: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _p.scaffoldSoft,
      appBar: AppBar(
        title: Text(
          'Edit Report',
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
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAttachmentsSection(),
            const SizedBox(height: 24),

            _label('Report Name'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: _fieldDecoration,
              child: TextFormField(
                controller: reportNameController,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600, color: _ink),
                decoration: InputDecoration(
                  hintText: 'Enter report name',
                  hintStyle: GoogleFonts.manrope(color: _muted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),

            _label('Description / Notes'),
            const SizedBox(height: 8),
            Container(
              decoration: _fieldDecoration,
              child: TextFormField(
                controller: descriptionController,
                maxLines: 5,
                style: GoogleFonts.manrope(fontSize: 14, color: _ink),
                decoration: InputDecoration(
                  hintText: 'Enter clinical description...',
                  hintStyle: GoogleFonts.manrope(color: _muted),
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

  BoxDecoration get _fieldDecoration => BoxDecoration(
        color: _p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line, width: 1.2),
      );

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _body,
        ),
      );

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _label('Attached Files'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _p.tint(const Color(0xFFFF3B5C), const Color(0xFFFFECEF)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_files.length}',
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
        if (_loadingFiles)
          const SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFFFF3B5C)),
            ),
          )
        else if (_files.isNotEmpty)
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _files.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _buildFileTile(_files[index]),
            ),
          ),
        if (!_loadingFiles && _files.isNotEmpty) const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF3B5C),
              backgroundColor: const Color(0xFFFF3B5C).withValues(alpha: 0.08),
              side: const BorderSide(color: Color(0xFFFF3B5C), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _loadingFiles ? null : _addFiles,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: Text(
              'Add More',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileTile(_EditFile file) {
    Widget preview;
    if (file.isPdf) {
      preview = Container(
        color: _p.tint(const Color(0xFFE11D48), const Color(0xFFFFE4E6)),
        child: const Center(
          child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE11D48), size: 36),
        ),
      );
    } else if (file.path.isEmpty) {
      preview = const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF3B5C)),
        ),
      );
    } else if (file.path.startsWith('http')) {
      preview = Image.network(file.path, fit: BoxFit.cover);
    } else {
      preview = Image.file(
        File(file.path),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.broken_image_rounded, color: _muted),
      );
    }

    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: file.isPdf ? const Color(0xFFE11D48).withValues(alpha: 0.5) : _line,
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SizedBox(width: double.infinity, child: preview)),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(fontSize: 11.5, fontWeight: FontWeight.w700, color: _ink),
                ),
              ),
            ],
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _removeFile(file),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            onPressed: isSaving || _loadingFiles ? null : _saveReport,
            child: isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    'SAVE CHANGES',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
