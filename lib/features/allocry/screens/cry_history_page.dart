import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/allocry/controller/cry_controller.dart';
import 'package:allomom/features/allocry/data/cry_record.dart';
import 'package:allomom/features/allocry/screens/cry_result_page.dart';
import 'package:allomom/features/allocry/widgets/cry_audio_player.dart';

/// Every cry AlloCry has read, newest first.
///
/// The list is the `cry` vitals stream itself — nothing is cached beside it —
/// so a reading saved on the result screen is here the moment she looks, and a
/// delete here removes the vital and its recording together.
class CryHistoryPage extends StatefulWidget {
  const CryHistoryPage({super.key});

  @override
  State<CryHistoryPage> createState() => _CryHistoryPageState();
}

class _CryHistoryPageState extends State<CryHistoryPage> {
  static const Color _pink = Color(0xFFFF4E6A);

  AppPalette get _p => context.palette;

  final CryController _controller = CryController.instance;

  @override
  void initState() {
    super.initState();
    _controller.refreshHistory();
  }

  Future<void> _confirmDelete(CryRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete this reading?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'The ${record.type.heading.toLowerCase()} from '
          '${DateFormat('d MMM, h:mm a').format(record.recordedAt)} and its '
          'recording will be removed.',
          style: GoogleFonts.poppins(fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep', style: GoogleFonts.poppins(color: _p.pick(const Color(0xFF6B7280), _p.textSecondary))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: _pink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _controller.deleteRecord(record);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reading deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _p.background,
      appBar: AppBar(
        backgroundColor: _p.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _pink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Cry History',
          style: GoogleFonts.outfit(
            color: _pink,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      // Rebuilds with the vitals stream, so a reading saved elsewhere in the
      // app shows up here without a manual refresh.
      body: GetBuilder<HealthVitalsController>(
        init: HealthVitalsController.instance,
        builder: (_) {
          final records = _controller.history();
          if (records.isEmpty) return _buildEmpty();

          return RefreshIndicator(
            color: _pink,
            onRefresh: () async {
              await _controller.refreshHistory();
              if (mounted) setState(() {});
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _buildSummary(records),
                const SizedBox(height: 18),
                ..._buildGroupedRecords(records),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _pink.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.graphic_eq_rounded, size: 46, color: _pink),
            ),
            const SizedBox(height: 20),
            Text(
              'No readings yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _p.pick(const Color(0xFF1E2229), _p.textPrimary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Record your baby crying and AlloCry will keep every reading here, '
              'with the audio, so you can spot patterns over time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.6,
                color: _p.pick(const Color(0xFF8C93A3), _p.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(List<CryRecord> records) {
    final breakdown = _controller.typeBreakdown(records);
    final mostCommon = breakdown.entries.first;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFF6F7)),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _p.pick(const Color(0xFFFFE3E8), _p.accentBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 17, color: _pink),
              const SizedBox(width: 8),
              Text(
                'Your baby\'s pattern',
                style: GoogleFonts.outfit(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: _p.pick(const Color(0xFF2C2F38), _p.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${records.length} reading${records.length == 1 ? '' : 's'} · '
            'most often ${mostCommon.key.toLowerCase()}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _p.pick(const Color(0xFF4A4E5A), _p.textSecondary),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: breakdown.entries.map((entry) {
              final type = _controller.describe(entry.key);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _p.card,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: type.color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  '${type.emoji}  ${type.heading.replaceAll(' Crying', '')} · ${entry.value}',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: type.color,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Splits the list under Today / Yesterday / date headings, so a night of
  /// several readings reads as one night.
  List<Widget> _buildGroupedRecords(List<CryRecord> records) {
    final widgets = <Widget>[];
    String? currentHeading;

    for (final record in records) {
      final heading = _dayHeading(record.recordedAt);
      if (heading != currentHeading) {
        currentHeading = heading;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            child: Text(
              heading,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _p.pick(const Color(0xFF9EA3B0), _p.textMuted),
              ),
            ),
          ),
        );
      }
      widgets.add(_buildRecordCard(record));
    }
    return widgets;
  }

  String _dayHeading(DateTime date) {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return DateFormat('EEEE, d MMMM').format(date);
  }

  Widget _buildRecordCard(CryRecord record) {
    final type = record.type;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _p.pick(const Color(0xFFEEF0F4), _p.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Get.to(() => CryResultPage(record: record)),
          onLongPress: () => _confirmDelete(record),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(type.icon, color: type.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.heading,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _p.pick(const Color(0xFF1E2229), _p.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${DateFormat('h:mm a').format(record.recordedAt)}'
                        ' · ${record.confidenceLabel} match',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: _p.pick(const Color(0xFF9EA3B0), _p.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                CryAudioPlayer(
                  audioFile: record.audioFile,
                  color: type.color,
                  compact: true,
                ),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(record),
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 19, color: _p.pick(const Color(0xFFCBD0DC), _p.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
