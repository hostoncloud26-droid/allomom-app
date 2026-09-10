import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/features/baby/baby_detail_page.dart';
import 'package:allomom/features/baby/baby_form_sheet.dart';
import 'package:allomom/features/baby/baby_options.dart';
import 'package:allomom/repositories/baby_repository.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/baby_db_service.dart';

/// Every baby the mother has recorded — the one just delivered, and any
/// previous children added during registration or here.
class MyBabiesPage extends StatefulWidget {
  const MyBabiesPage({super.key});

  @override
  State<MyBabiesPage> createState() => _MyBabiesPageState();
}

class _MyBabiesPageState extends State<MyBabiesPage> {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  final _repo = BabyRepository.instance;
  final _db = BabyDbService.instance;

  bool _loading = true;
  List<BirthRecord> _babies = [];

  /// birth record id -> (doses given, doses total, milestones achieved,
  /// milestones total), so each card can show progress without a second load.
  final Map<String, _BabyProgress> _progress = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final babies = await _repo.getBabies();

    _progress.clear();
    for (final baby in babies) {
      final doses = await _db.getImmunizations(baby.id);
      final milestones = await _db.getMilestones(baby.id);
      _progress[baby.id] = _BabyProgress(
        dosesGiven: doses.where((d) => d.vaccinationDate != null).length,
        dosesTotal: doses.length,
        milestonesAchieved: milestones.where((m) => m.achieved).length,
        milestonesTotal: milestones.length,
      );
    }

    if (!mounted) return;
    setState(() {
      _babies = babies;
      _loading = false;
    });
  }

  Future<void> _addBaby() async {
    final id = await showBabyFormSheet(context);
    if (id != null) await _load();
  }

  Future<void> _editBaby(BirthRecord baby) async {
    final id = await showBabyFormSheet(
      context,
      existing: baby,
      title: 'Edit baby',
    );
    if (id != null) await _load();
  }

  Future<void> _deleteBaby(BirthRecord baby) async {
    final name = baby.babyName ?? 'this baby';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Remove $name?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'This also deletes their vaccination schedule, milestones and '
          'health record. This cannot be undone.',
          style: TextStyle(fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _repo.deleteBaby(baby.id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Baby removed'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E2024),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Babies',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E2024),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBaby,
        backgroundColor: const Color(0xFFFF3B5C),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add baby',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _babies.isEmpty
          ? _empty()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                itemCount: _babies.length,
                itemBuilder: (_, i) => _babyCard(_babies[i]),
              ),
            ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0F4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.child_care_rounded,
              size: 38,
              color: Color(0xFFFF3B5C),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No babies added yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your newborn or an older child. We\'ll set up their '
            'vaccination schedule and milestone checklist from their date '
            'of birth.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF6B707B),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _babyCard(BirthRecord baby) {
    final progress = _progress[baby.id] ?? const _BabyProgress.empty();
    final name = baby.babyName ?? 'Baby';
    final isNewborn = baby.pregnancyId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BabyDetailPage(birthRecordId: baby.id),
              ),
            );
            await _load();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF0F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.child_care_rounded,
                        color: Color(0xFFFF3B5C),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E2024),
                                  ),
                                ),
                              ),
                              if (isNewborn) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'This pregnancy',
                                    style: GoogleFonts.poppins(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF059669),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              if (baby.dob != null) _dateFmt.format(baby.dob!),
                              if (baby.dob != null) babyAgeLabel(baby.dob),
                              labelForGender(baby.gender),
                            ].where((s) => s.isNotEmpty && s != '—').join('  ·  '),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF6B707B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: Color(0xFF9CA3AF),
                      ),
                      onSelected: (v) {
                        if (v == 'edit') _editBaby(baby);
                        if (v == 'delete') _deleteBaby(baby);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Remove',
                            style: TextStyle(color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _statTile(
                        icon: Icons.vaccines_rounded,
                        color: const Color(0xFF3898EC),
                        background: const Color(0xFFEDF6FF),
                        label: 'Vaccines',
                        value:
                            '${progress.dosesGiven}/${progress.dosesTotal}',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statTile(
                        icon: Icons.emoji_events_rounded,
                        color: const Color(0xFFF59E0B),
                        background: const Color(0xFFFEF3C7),
                        label: 'Milestones',
                        value:
                            '${progress.milestonesAchieved}/${progress.milestonesTotal}',
                      ),
                    ),
                    if (baby.weight != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statTile(
                          icon: Icons.monitor_weight_rounded,
                          color: const Color(0xFF10B981),
                          background: const Color(0xFFD1FAE5),
                          label: 'Birth wt',
                          value: '${baby.weight} kg',
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required Color color,
    required Color background,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2024),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: const Color(0xFF6B707B),
            ),
          ),
        ],
      ),
    );
  }
}

class _BabyProgress {
  const _BabyProgress({
    required this.dosesGiven,
    required this.dosesTotal,
    required this.milestonesAchieved,
    required this.milestonesTotal,
  });

  const _BabyProgress.empty()
    : dosesGiven = 0,
      dosesTotal = 0,
      milestonesAchieved = 0,
      milestonesTotal = 0;

  final int dosesGiven;
  final int dosesTotal;
  final int milestonesAchieved;
  final int milestonesTotal;
}
