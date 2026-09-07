import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';

import 'package:allomom/services/sq_lite/services/report_db_service.dart';
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
  late List<String> _files;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _files = _extractFiles(widget.reportDetails);
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

    final ocrSummary = details['ocr_summary']?.toString();

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
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: AppBar(
        title: Text(
          'Report Details',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: () => _deleteReport(context),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF1E2024)),
            onPressed: () async {
              final updated = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => EditReport(reportDetails: widget.reportDetails),
                ),
              );
              if (updated == true && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
          ),
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

            // Report Type Heading
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF0F1F5)),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFECEF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.medical_information_outlined, color: Color(0xFFFF3B5C), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reportType,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E2024),
                          ),
                        ),
                      ),
                      if (_files.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _files.any((f) => _isPdf(f)) ? Icons.picture_as_pdf_outlined : Icons.attachment_rounded,
                                size: 13,
                                color: const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_files.length} ${_files.length == 1 ? 'file' : 'files'}',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFF0F1F5)),
                  const SizedBox(height: 12),
                  Text(
                    'Clinical Description',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      height: 1.5,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            if (ocrSummary != null && ocrSummary.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.04),
                      blurRadius: 14,
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'On-Device OCR Analysis',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                        const Spacer(),
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ocrSummary,
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (filteredResults.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF0F1F5)),
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
                        color: const Color(0xFF1E2024),
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
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              entry.value.toString(),
                              style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E2024),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F1F5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 8),
            Text(
              'No document or image attached',
              style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF94A3B8)),
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
                color: const Color(0xFF64748B),
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
                      color: isSelected ? const Color(0xFFFF3B5C) : const Color(0xFFCBD5E1),
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
                      color: isSelected ? const Color(0xFFFF3B5C) : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isPdf
                      ? Container(
                          color: const Color(0xFFFFE4E6),
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
          color: Colors.white,
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
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4E6),
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
                color: const Color(0xFF1E2024),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'PDF Medical Report',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F1F5)),
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
