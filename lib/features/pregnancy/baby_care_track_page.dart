import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/pregnancy/widgets/baby_growth_track.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/baby_db_service.dart';

/// One baby's vaccinations or milestones on their own page — the milestone
/// train on top, that list alone under it. Opened from the pregnancy
/// journey's baby view: its feature boxes and each list's "Show all".
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
