import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/pregnancy/widgets/baby_growth_track.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/baby_db_service.dart';

/// One baby's vaccinations or milestones on their own page — the milestone
/// train on top, that list alone under it. Opened from the two boxes in the
/// pregnancy journey's baby view.
class BabyCareTrackPage extends StatefulWidget {
  const BabyCareTrackPage({
    super.key,
    required this.babyId,
    required this.mode,
  });

  final String babyId;

  /// [BabyTrackMode.vaccinations] or [BabyTrackMode.milestones].
  final BabyTrackMode mode;

  @override
  State<BabyCareTrackPage> createState() => _BabyCareTrackPageState();
}

class _BabyCareTrackPageState extends State<BabyCareTrackPage> {
  Baby? _baby;
  List<BabyImmunizationRecord> _doses = const [];
  List<BabyMilestone> _milestones = const [];
  bool _loading = true;

  String get _title => widget.mode == BabyTrackMode.milestones
      ? 'Milestones'
      : 'Vaccination';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = BabyDbService.instance;
    final baby = await db.getBabyById(widget.babyId);
    final doses = await db.getImmunizations(widget.babyId);
    final milestones = await db.getMilestones(widget.babyId);
    if (!mounted) return;
    setState(() {
      _baby = baby;
      _doses = doses;
      _milestones = milestones;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final baby = _baby;

    return Scaffold(
      backgroundColor: p.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: p.scaffoldSoft,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: p.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          baby == null || baby.name.trim().isEmpty
              ? _title
              : "${baby.name.trim()}'s $_title",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: p.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF3B5C)),
            )
          : baby == null
          ? Center(
              child: Text(
                'This baby could not be found.',
                style: TextStyle(color: p.textSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(0xFFFF3B5C),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                children: [
                  BabyGrowthTrack(
                    baby: baby,
                    doses: _doses,
                    milestones: _milestones,
                    mode: widget.mode,
                    onDoseGiven: (dose, given) async {
                      await BabyDbService.instance.markImmunizationGiven(
                        dose.id,
                        given ? DateTime.now() : null,
                      );
                      await _load();
                    },
                    onMilestoneReached: (milestone, reached) async {
                      await BabyDbService.instance.setMilestoneAchieved(
                        milestone.id,
                        reached ? DateTime.now() : null,
                      );
                      await _load();
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

/// The Vaccination and Milestones boxes, styled as Home's quick actions: an
/// icon, a name, and how far through the baby is.
class BabyCareBoxes extends StatelessWidget {
  const BabyCareBoxes({
    super.key,
    required this.dosesGiven,
    required this.dosesTotal,
    required this.milestonesReached,
    required this.milestonesTotal,
    required this.onOpen,
  });

  final int dosesGiven;
  final int dosesTotal;
  final int milestonesReached;
  final int milestonesTotal;
  final ValueChanged<BabyTrackMode> onOpen;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _box(
            context,
            icon: Icons.vaccines_rounded,
            color: const Color(0xFF8B5CF6),
            title: 'Vaccination',
            count: '$dosesGiven/$dosesTotal given',
            onTap: () => onOpen(BabyTrackMode.vaccinations),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _box(
            context,
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Milestones',
            count: '$milestonesReached/$milestonesTotal reached',
            onTap: () => onOpen(BabyTrackMode.milestones),
          ),
        ),
      ],
    );
  }

  Widget _box(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String count,
    required VoidCallback onTap,
  }) {
    final p = context.palette;
    return Container(
      height: 124,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.pick(const Color(0xFFF0F1F5), p.border)),
        boxShadow: [
          BoxShadow(
            color: p.pick(Colors.black.withValues(alpha: 0.03), p.shadow),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: p.tint(color, color.withValues(alpha: 0.10)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: TextStyle(fontSize: 11.5, color: p.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
