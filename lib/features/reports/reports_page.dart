import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  final List<Map<String, dynamic>> _reports = [
    {
      'title': 'Blood Test',
      'subtitle': 'CBC + Hb',
      'date': '12 Aug 2026',
      'icon': Icons.water_drop_rounded,
      'iconColor': const Color(0xFFFF4E6A),
      'iconBg': const Color(0xFFFFF0F3),
    },
    {
      'title': 'Ultrasound',
      'subtitle': 'Growth Scan',
      'date': '06 Aug 2026',
      'icon': Icons.pregnant_woman_rounded,
      'iconColor': const Color(0xFF9333EA),
      'iconBg': const Color(0xFFF3E8FF),
    },
    {
      'title': 'Urine Test',
      'subtitle': 'Routine Examination',
      'date': '28 Jul 2026',
      'icon': Icons.science_rounded,
      'iconColor': const Color(0xFFD97706),
      'iconBg': const Color(0xFFFEF3C7),
    },
    {
      'title': 'Thyroid Profile',
      'subtitle': 'T3, T4, TSH',
      'date': '15 Jul 2026',
      'icon': Icons.shield_rounded,
      'iconColor': const Color(0xFF2563EB),
      'iconBg': const Color(0xFFDBEAFE),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── TOP APP BAR ───
              _buildTopBar(context),
              const SizedBox(height: 20),

              // ─── REPORTS TITLE & ADD BUTTON ───
              _buildSectionTitleRow(context),
              const SizedBox(height: 18),

              // ─── STATS SUMMARY CARD ───
              _buildStatsCard(),
              const SizedBox(height: 24),

              // ─── RECENT REPORTS HEADER ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Reports',
                    style: GoogleFonts.outfit(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1C1A),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Showing all 12 reports')),
                      );
                    },
                    child: Text(
                      'See all',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF4E6A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ─── REPORT CARDS LIST ───
              ..._reports.map((report) => _buildReportItemCard(context, report)),

              const SizedBox(height: 20),

              // ─── ADD REPORT UPLOAD BUTTON CARD ───
              _buildAddReportCard(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ─── TOP BAR ───
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDECEF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF1E2024),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Health Reports',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E2024),
              ),
            ),
          ],
        ),
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFFF4E6A),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ],
    );
  }

  // ─── SECTION TITLE ROW ───
  Widget _buildSectionTitleRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reports',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E2024),
              ),
            ),
            Text(
              'All your health reports',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                color: const Color(0xFF7A7E85),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => _showAddReportModal(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4E6A),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4E6A).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // ─── STATS SUMMARY CARD ───
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          // Stat 1: Total reports
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD8E0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: Color(0xFFFF4E6A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_reports.length + 8}',
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    Text(
                      'Total reports',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF7A7E85),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider
          Container(
            height: 40,
            width: 1,
            color: const Color(0xFFFFD2DC),
          ),
          const SizedBox(width: 16),

          // Stat 2: Reports this month
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Color(0xFF16A34A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '3',
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    Text(
                      'Reports this\nmonth',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF7A7E85),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── REPORT ITEM CARD ───
  Widget _buildReportItemCard(BuildContext context, Map<String, dynamic> item) {
    final icon = item['icon'] as IconData;
    final iconColor = item['iconColor'] as Color;
    final iconBg = item['iconBg'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          item['title'] as String,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E2024),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              item['subtitle'] as String,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF7A7E85),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item['date'] as String,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: const Color(0xFFA0A5AF),
              ),
            ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF4A4E58),
          size: 22,
        ),
        onTap: () {
          _showReportDetailsDialog(context, item);
        },
      ),
    );
  }

  // ─── ADD REPORT CARD ───
  Widget _buildAddReportCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddReportModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFD2DC), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFDE0E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                color: Color(0xFFFF4E6A),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Report',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF4E6A),
                    ),
                  ),
                  Text(
                    'Upload PDF / image',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF7A7E85),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFFF4E6A),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDetailsDialog(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item['iconBg'] as Color,
                shape: BoxShape.circle,
              ),
              child: Icon(item['icon'] as IconData, color: item['iconColor'] as Color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['title'] as String,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test Details: ${item['subtitle']}', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 6),
            Text('Date: ${item['date']}', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${item['title']}_Report.pdf',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text('2.4 MB', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.poppins(color: const Color(0xFFFF4E6A), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAddReportModal(BuildContext context) {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Upload Medical Report',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E2024),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Report Title',
                hintText: 'e.g. Glucose Tolerance Test',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subtitleController,
              decoration: InputDecoration(
                labelText: 'Doctor / Lab / Category',
                hintText: 'e.g. Apollo Diagnostics',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD2DC), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: Color(0xFFFF4E6A), size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Select PDF or Image from device',
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF7A7E85)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    setState(() {
                      _reports.insert(0, {
                        'title': titleController.text.trim(),
                        'subtitle': subtitleController.text.trim().isEmpty
                            ? 'Lab Report'
                            : subtitleController.text.trim(),
                        'date': 'Today',
                        'icon': Icons.description_rounded,
                        'iconColor': const Color(0xFFFF4E6A),
                        'iconBg': const Color(0xFFFFF0F3),
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report uploaded successfully!')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4E6A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Upload Report',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
