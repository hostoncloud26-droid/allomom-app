import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';

import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/report_db_service.dart';
import 'package:allomom/features/reports/controller/reports_drive_controller.dart';
import 'package:allomom/features/reports/edit_report.dart';

class ViewReport extends StatefulWidget {
  final Map<String, dynamic> reportDetails;

  const ViewReport({super.key, required this.reportDetails});

  @override
  State<ViewReport> createState() => _ViewReportState();
}

class _ViewReportState extends State<ViewReport> {
  late PageController _pageController;
  int _currentPage = 0;
  List<String> _files = const [];

  /// True while files held only in the user's Drive are being fetched.
  bool _fetchingFromDrive = false;

  AppPalette get _p => context.palette;
  Color get _ink => _p.pick(const Color(0xFF1E2024), _p.textPrimary);
  Color get _slate => _p.pick(const Color(0xFF64748B), _p.textSecondary);
  Color get _body => _p.pick(const Color(0xFF475569), _p.textSecondary);
  Color get _muted => _p.pick(const Color(0xFF94A3B8), _p.textMuted);
  Color get _line => _p.pick(const Color(0xFFF0F1F5), _p.border);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // Whatever is already on this device, immediately — the screen should not
    // wait on the network to show a report the phone scanned itself.
    _files = _extractFiles(widget.reportDetails);
    _resolveFiles();
  }

  /// Settles which files this report actually has, and where they are.
  ///
  /// The attachment rows are the real answer: `detail.files` only ever held
  /// this device's own paths, so a report restored from Drive — or scanned on
  /// another phone — has none of them. Anything the rows point at but this
  /// device does not hold is pulled from Drive and cached, after which it is
  /// an ordinary local file like any other.
  Future<void> _resolveFiles() async {
    final reportId = widget.reportDetails['id']?.toString() ?? '';
    if (reportId.isEmpty) return;

    List<ReportAttachment> attachments;
    try {
      attachments = await ReportDbService.instance.attachmentsFor(reportId);
    } catch (e) {
      debugPrint('ViewReport: could not read attachments: $e');
      return;
    }
    // Reports saved before files were tracked as rows still have only the
    // paths in `detail`, which is what [_files] already holds.
    if (attachments.isEmpty) return;

    final onDevice = <String>[];
    final inDriveOnly = <ReportAttachment>[];
    for (final attachment in attachments) {
      if (attachment.localPath.isNotEmpty &&
          File(attachment.localPath).existsSync()) {
        onDevice.add(attachment.localPath);
      } else {
        inDriveOnly.add(attachment);
      }
    }

    if (mounted && onDevice.isNotEmpty) {
      setState(() => _files = onDevice);
    }
    if (inDriveOnly.isEmpty) return;

    if (mounted) setState(() => _fetchingFromDrive = true);
    final drive = ReportsDriveController.instance;
    for (final attachment in inDriveOnly) {
      final file = await drive.attachmentFile(attachment);
      if (file == null || !mounted) continue;
      setState(() => _files = [..._files, file.path]);
    }
    if (mounted) setState(() => _fetchingFromDrive = false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _extractFiles(Map<String, dynamic> details) {
    final List<String> files = [];
    final rawDetail = details['detail'];
    Map<String, dynamic>? detailMap;
    if (rawDetail is Map) {
      detailMap = Map<String, dynamic>.from(rawDetail);
    } else if (rawDetail is String && rawDetail.isNotEmpty) {
      try {
        detailMap = Map<String, dynamic>.from(jsonDecode(rawDetail));
      } catch (_) {}
    }

    if (detailMap != null && detailMap['files'] is List) {
      for (var f in detailMap['files']) {
        if (f != null && f.toString().isNotEmpty) {
          files.add(f.toString());
        }
      }
    }

    final mainImg = details['imageUrl']?.toString();
    if (files.isEmpty && mainImg != null && mainImg.isNotEmpty) {
      files.add(mainImg);
    }
    return files;
  }

  bool _isPdf(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  String _getFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _editReport(BuildContext context) async {
    final updated = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => EditReport(reportDetails: widget.reportDetails),
      ),
    );
    if (updated == true && context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _deleteReport(BuildContext context) async {
    final reportId = widget.reportDetails['id']?.toString() ?? '';
    if (reportId.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'Delete Report',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Are you sure you want to delete this health report?',
              style: GoogleFonts.manrope(fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete', style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    try {
      await ReportDbService.instance.deleteReport(reportId);
      // The local row is already gone, so the server has to be told
      // separately. Queued rather than awaited: the user asked for the report
      // to disappear, not to watch a network call.
      ReportsDriveController.instance.queueDelete(reportId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report deleted successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete report: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showFullScreenImage(BuildContext context, String path) {
    if (path.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: _buildImageWidget(path),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.contain);
    } else if (File(path).existsSync()) {
      return Image.file(File(path), fit: BoxFit.contain);
    }
    return const Icon(Icons.broken_image_rounded, size: 64, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    final reportType = widget.reportDetails['report_type']?.toString() ?? 'Report';
    final desc = widget.reportDetails['description']?.toString() ?? 'No description available';
    final rawDetail = widget.reportDetails['detail'];
    Map<String, dynamic> details = {};
    if (rawDetail is Map) {
      details = Map<String, dynamic>.from(rawDetail);
    } else if (rawDetail is String && rawDetail.isNotEmpty) {
      try {
        details = Map<String, dynamic>.from(jsonDecode(rawDetail));
      } catch (_) {}
    }

    // Filter out internal metadata keys from test results
    final filteredResults = Map<String, dynamic>.from(details)
      ..removeWhere((k, _) => [
            'files',
            'file_count',
            'file_names',
            'fileTypes',
            'has_pdf',
            'ocr_summary',
            'raw_ocr_text',
            'detected_type',
            'report_date',
            'patient_name'
          ].contains(k));

    return Scaffold(
      backgroundColor: _p.scaffoldSoft,
      appBar: AppBar(
        title: Text(
          'Report Details',
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
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: _ink),
            color: _p.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (action) {
              if (action == 'edit') _editReport(context);
              if (action == 'delete') _deleteReport(context);
            },
            itemBuilder: (_) => [
              _menuItem('edit', Icons.edit_outlined, 'Edit', _ink),
              _menuItem('delete', Icons.delete_outline_rounded, 'Delete', Colors.redAccent),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media Preview Section
            _buildMediaSection(),

            const SizedBox(height: 24),

            // Report Name & Description
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _p.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _line),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report Name',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reportType,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: _p.pick(const Color(0xFFF0F1F5), _p.divider)),
                  const SizedBox(height: 12),
                  Text(
                    'Clinical Description',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      height: 1.5,
                      color: _body,
                    ),
                  ),
                ],
              ),
            ),
            if (filteredResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _p.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _line),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...filteredResults.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _slate,
                              ),
                            ),
                            Text(
                              entry.value.toString(),
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection() {
    if (_files.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _p.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_fetchingFromDrive)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFFF3B5C),
                ),
              )
            else
              Icon(Icons.description_outlined, size: 48, color: _p.pick(const Color(0xFFCBD5E1), _p.textMuted)),
            const SizedBox(height: 10),
            Text(
              _fetchingFromDrive
                  ? 'Getting this report from your Google Drive…'
                  : 'No document or image attached',
              style: GoogleFonts.manrope(fontSize: 13, color: _muted),
            ),
          ],
        ),
      );
    }

    if (_files.length == 1) {
      return _buildFileItemCard(_files[0]);
    }

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: _files.length,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildFileItemCard(_files[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicator and thumbnails
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attachment ${_currentPage + 1} of ${_files.length}',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _slate,
              ),
            ),
            Row(
              children: List.generate(_files.length, (idx) {
                final isSelected = idx == _currentPage;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      idx,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isSelected ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFF3B5C) : _p.pick(const Color(0xFFCBD5E1), _p.textMuted),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Thumbnails Strip
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _files.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final path = _files[index];
              final isPdf = _isPdf(path);
              final isSelected = index == _currentPage;

              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFFF3B5C) : _p.pick(const Color(0xFFE2E8F0), _p.border),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isPdf
                      ? Container(
                          color: _p.tint(const Color(0xFFE11D48), const Color(0xFFFFE4E6)),
                          child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE11D48), size: 24),
                        )
                      : (path.startsWith('http')
                          ? Image.network(path, fit: BoxFit.cover)
                          : Image.file(File(path), fit: BoxFit.cover)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFileItemCard(String path) {
    final isPdf = _isPdf(path);
    final fileName = _getFileName(path);

    if (isPdf) {
      return Container(
        height: 220,
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _p.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _p.tint(const Color(0xFFE11D48), const Color(0xFFFFE4E6)),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE11D48), size: 40),
            ),
            const SizedBox(height: 12),
            Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF Medical Report',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _muted,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
              onPressed: () => OpenFilex.open(path),
              icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16),
              label: Text(
                'Open / View PDF',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullScreenImage(context, path),
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _p.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _line),
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
            _buildImageWidget(path),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
