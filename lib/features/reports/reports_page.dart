import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/services/api/report_api.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/sq_lite/services/report_db_service.dart';
import 'package:allomom/features/reports/add_report.dart';
import 'package:allomom/features/reports/view_report.dart';

class ReportsPage extends StatefulWidget {
  final bool showAppBar;

  const ReportsPage({
    super.key,
    this.showAppBar = true,
  });

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

typedef ReportListPage = ReportsPage;

class _ReportsPageState extends State<ReportsPage> {
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _skip = 0;
  static const int _limit = 10;

  String _summary = '';
  bool _isLoadingSummary = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _fetchMoreReports();
      }
    }
  }

  Future<void> _loadInitialData() async {
    _loadCachedReports();
    await Future.wait([
      _fetchReports(refresh: true),
      _fetchSummary(),
    ]);
  }

  Future<void> _loadCachedReports() async {
    try {
      final session = UserSessionManager.instance;
      final healthId = session.currentHealthData?.id ?? (session.userId.isNotEmpty ? session.userId : 'health_me');
      final localRows = await ReportDbService.instance.getReports(healthId);

      if (localRows.isNotEmpty && mounted && _reports.isEmpty) {
        setState(() {
          _reports = localRows.map((r) {
            Map<String, dynamic> detailMap = {};
            if (r.detail != null && r.detail!.isNotEmpty) {
              try {
                detailMap = Map<String, dynamic>.from(jsonDecode(r.detail!));
              } catch (_) {}
            }
            return {
              'id': r.id,
              'report_type': r.reportType,
              'description': r.description,
              'imageUrl': r.imageUrl,
              'detail': detailMap,
              'createdAt': r.createdAt.toIso8601String(),
            };
          }).toList();
        });
        _updateSummaryFromReports();
      }
    } catch (_) {}
  }

  void _updateSummaryFromReports() {
    if (!mounted) return;
    if (_summary.isNotEmpty && !_summary.startsWith('No reports')) return;
    if (_reports.isEmpty) return;

    final summaries = <String>[];
    for (final r in _reports) {
      final detail = r['detail'];
      if (detail is Map && detail['ocr_summary'] != null && detail['ocr_summary'].toString().isNotEmpty) {
        summaries.add(detail['ocr_summary'].toString());
      } else if (r['description'] != null && r['description'].toString().isNotEmpty) {
        summaries.add('${r['report_type'] ?? 'Report'}: ${r['description']}');
      }
    }

    if (summaries.isNotEmpty) {
      setState(() {
        _summary = summaries.take(2).join(' • ');
      });
    }
  }

  Future<void> _fetchSummary() async {
    if (!mounted) return;
    setState(() => _isLoadingSummary = true);
    try {
      final res = await ReportApi.getReportsSummary();
      if (res.success && res.item is Map) {
        final text = res.item['summary']?.toString() ?? '';
        if (mounted && text.isNotEmpty) setState(() => _summary = text);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingSummary = false);
        _updateSummaryFromReports();
      }
    }
  }

  Future<void> _fetchReports({bool refresh = false}) async {
    if (refresh) {
      _skip = 0;
      _hasMore = true;
    }

    if (!mounted) return;
    setState(() => _isLoading = refresh ? true : _isLoading);

    try {
      final response = await ReportApi.getReports(skip: _skip, limit: _limit);

      if (response.success && response.items != null) {
        final List fetched = response.items is List ? response.items : [];
        final items = fetched.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        if (mounted) {
          setState(() {
            if (refresh) {
              _reports = items;
            } else {
              _reports.addAll(items);
            }
            _skip += items.length;
            _hasMore = items.length >= _limit;
          });
        }
      }
    } catch (e) {
      // Fallback: stay on cached reports
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _updateSummaryFromReports();
      }
    }
  }

  Future<void> _fetchMoreReports() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);

    try {
      final response = await ReportApi.getReports(skip: _skip, limit: _limit);
      if (response.success && response.items != null) {
        final List fetched = response.items is List ? response.items : [];
        final items = fetched.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        if (mounted) {
          setState(() {
            _reports.addAll(items);
            _skip += items.length;
            _hasMore = items.length >= _limit;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _fetchReports(refresh: true),
      _fetchSummary(),
    ]);
  }

  List<String> _extractReportFiles(Map<String, dynamic> report) {
    final List<String> files = [];
    final rawDetail = report['detail'];
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

    final mainImg = report['imageUrl']?.toString();
    if (files.isEmpty && mainImg != null && mainImg.isNotEmpty) {
      files.add(mainImg);
    }
    return files;
  }

  bool _isPdf(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  Widget _buildImageThumbnail(Map<String, dynamic> report) {
    final files = _extractReportFiles(report);
    final path = files.isNotEmpty ? files.first : (report['imageUrl']?.toString() ?? '');
    final hasPdf = files.any((f) => _isPdf(f)) || _isPdf(path);

    if (path.isEmpty) {
      return Container(
        height: 76,
        width: 76,
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.description_outlined, color: Color(0xFFFF3B5C), size: 30),
      );
    }

    Widget content;
    if (hasPdf) {
      content = Container(
        height: 76,
        width: 76,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE4E6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE11D48), size: 30),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFE11D48),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'PDF',
                style: GoogleFonts.manrope(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (path.startsWith('http')) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          path,
          height: 76,
          width: 76,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    } else if (File(path).existsSync()) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path),
          height: 76,
          width: 76,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
        ),
      );
    } else {
      content = _buildPlaceholder();
    }

    if (files.length > 1) {
      return Stack(
        children: [
          content,
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+${files.length}',
                style: GoogleFonts.manrope(
                  color: Colors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return content;
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 76,
      width: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                'My Reports',
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
            )
          : null,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'report_list_add_report_fab',
        backgroundColor: const Color(0xFFFF3B5C),
        elevation: 4,
        onPressed: () async {
          final added = await Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const AddReport()),
          );
          if (added == true) {
            _refresh();
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Add Report',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: const Color(0xFFFF3B5C),
        child: _isLoading && _reports.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B5C)))
            : _reports.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      _buildSummaryCard(),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.18),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFECEF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.file_copy_outlined, size: 48, color: Color(0xFFFF3B5C)),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'No reports found',
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E2024),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Scan and upload your first medical report',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    itemCount: _reports.length + 1 + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildSummaryCard();
                      }

                      final reportIndex = index - 1;

                      if (reportIndex == _reports.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: CircularProgressIndicator(color: Color(0xFFFF3B5C), strokeWidth: 2),
                          ),
                        );
                      }

                      final report = _reports[reportIndex];
                      return _buildReportCard(report);
                    },
                  ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    if (_isLoadingSummary && _summary.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF0F1F5)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF3B5C)),
            ),
            const SizedBox(width: 12),
            Text(
              'Analyzing health reports...',
              style: GoogleFonts.manrope(fontSize: 13, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    if (_summary.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF3B5C).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3B5C).withValues(alpha: 0.04),
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
              const Icon(Icons.auto_awesome, color: Color(0xFFFF3B5C), size: 18),
              const SizedBox(width: 8),
              Text(
                'AI Health Summary',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFFF3B5C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _summary,
            style: GoogleFonts.manrope(
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final reportType = report['report_type']?.toString() ?? 'Report';
    final desc = report['description']?.toString() ?? '';
    final createdAtStr = report['createdAt']?.toString() ?? '';
    final dateDisplay = createdAtStr.contains('T') ? createdAtStr.split('T')[0] : createdAtStr;

    final files = _extractReportFiles(report);
    final hasPdf = files.any((f) => _isPdf(f)) || _isPdf(report['imageUrl']?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () async {
            final changed = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => ViewReport(reportDetails: report),
              ),
            );
            if (changed == true) {
              _refresh();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageThumbnail(report),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    reportType,
                                    style: GoogleFonts.manrope(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1E2024),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (hasPdf) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFE4E6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'PDF',
                                      style: GoogleFonts.manrope(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFE11D48),
                                      ),
                                    ),
                                  ),
                                ] else if (files.length > 1) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${files.length} files',
                                      style: GoogleFonts.manrope(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (dateDisplay.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.event_outlined, size: 12, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    dateDisplay,
                                    style: GoogleFonts.manrope(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        desc.isNotEmpty ? desc : 'No description available',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.manrope(
                          fontSize: 12.5,
                          height: 1.4,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
