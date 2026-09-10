import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/features/baby/baby_form_sheet.dart';
import 'package:allomom/features/baby/baby_options.dart';
import 'package:allomom/features/pregnancy/widgets/care_schedule_common.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/baby_db_service.dart';

/// One baby's record: their immunisation schedule and milestone checklist,
/// both seeded from the date of birth and editable here.
class BabyDetailPage extends StatefulWidget {
  const BabyDetailPage({
    super.key,
    required this.birthRecordId,
    this.initialTab = 0,
  });

  final String birthRecordId;

  /// 0 = vaccines, 1 = milestones. Lets a caller deep-link to the tab the
  /// mother tapped rather than always landing her on vaccines.
  final int initialTab;

  @override
  State<BabyDetailPage> createState() => _BabyDetailPageState();
}

class _BabyDetailPageState extends State<BabyDetailPage>
    with SingleTickerProviderStateMixin {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  final _db = BabyDbService.instance;
  late final TabController _tabs = TabController(
    length: 2,
    vsync: this,
    initialIndex: widget.initialTab.clamp(0, 1),
  );

  bool _loading = true;
  BirthRecord? _baby;
  List<BabyImmunizationRecord> _doses = [];
  List<BabyMilestone> _milestones = [];

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      // Rebuilds so the FAB label follows the visible tab.
      if (!_tabs.indexIsChanging) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final baby = await _db.getBirthRecordById(widget.birthRecordId);
    final doses = await _db.getImmunizations(widget.birthRecordId);
    final milestones = await _db.getMilestones(widget.birthRecordId);
    if (!mounted) return;
    setState(() {
      _baby = baby;
      _doses = doses;
      _milestones = milestones;
      _loading = false;
    });
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baby = _baby;
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E2024),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          baby?.babyName ?? 'Baby',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E2024),
          ),
        ),
        actions: [
          if (baby != null)
            IconButton(
              tooltip: 'Edit details',
              icon: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF1E2024),
                size: 20,
              ),
              onPressed: () async {
                final id = await showBabyFormSheet(
                  context,
                  existing: baby,
                  title: 'Edit baby',
                );
                if (id != null) await _load();
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFFFF3B5C),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          indicatorColor: const Color(0xFFFF3B5C),
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            Tab(text: 'Vaccines (${_doses.length})'),
            Tab(text: 'Milestones (${_milestones.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tabs.index == 0 ? _addDose : _addMilestone,
        backgroundColor: const Color(0xFFFF3B5C),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          _tabs.index == 0 ? 'Add vaccine' : 'Add milestone',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : baby == null
          ? const Center(child: Text('This baby record no longer exists.'))
          : Column(
              children: [
                _summary(baby),
                const Divider(height: 1, color: Color(0xFFEEEFF4)),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [_doseList(), _milestoneList()],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _summary(BirthRecord baby) {
    final chips = <(String, String)>[
      if (baby.dob != null) ('Born', _dateFmt.format(baby.dob!)),
      if (baby.dob != null) ('Age', babyAgeLabel(baby.dob)),
      if (baby.gender != null) ('Gender', labelForGender(baby.gender)),
      if (baby.deliveryType != null)
        ('Delivery', labelForDeliveryType(baby.deliveryType)),
      if (baby.weight != null) ('Birth wt', '${baby.weight} kg'),
      if (baby.bloodGroup != null) ('Blood', baby.bloodGroup!),
    ];

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips
            .map(
              (c) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F4),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${c.$1} · ${c.$2}',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ---------------------- IMMUNISATIONS ----------------------

  Widget _doseList() {
    if (_doses.isEmpty) {
      return _empty(
        Icons.vaccines_rounded,
        'No vaccines scheduled',
        'Add a dose, or edit the date of birth to rebuild the standard '
            'immunisation schedule.',
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
      itemCount: _doses.length,
      itemBuilder: (_, i) => _doseCard(_doses[i]),
    );
  }

  Widget _doseCard(BabyImmunizationRecord dose) {
    final given = dose.vaccinationDate != null;
    final status = CareStatus.resolve(
      status: given ? 'done' : 'pending',
      date: dose.expectedDate,
    );

    return _card(
      leading: Checkbox(
        value: given,
        activeColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        onChanged: (checked) async {
          if (checked == true) {
            await _db.markImmunizationGiven(dose.id, date: DateTime.now());
          } else {
            await _db.updateImmunization(
              BabyImmunizationRecordsCompanion(
                id: drift.Value(dose.id),
                vaccinationDate: const drift.Value(null),
                vaccinatedBy: const drift.Value(null),
              ),
            );
          }
          await _load();
        },
      ),
      title: dose.vaccineName,
      titleStrikethrough: given,
      status: status,
      showStatus: !given || dose.expectedDate != null,
      lines: [
        if (dose.expectedDate != null)
          'Due ${_dateFmt.format(dose.expectedDate!)}',
        if (given) 'Given ${_dateFmt.format(dose.vaccinationDate!)}',
        if ((dose.vaccinatedBy ?? '').isNotEmpty) 'By ${dose.vaccinatedBy}',
        if (dose.required == false) 'Optional',
      ],
      synced: dose.synced,
      onEdit: () => _openDoseForm(existing: dose),
      onDelete: () => _confirmDelete(
        dose.vaccineName,
        () => _db.deleteImmunization(dose.id),
      ),
    );
  }

  void _addDose() => _openDoseForm();

  Future<void> _openDoseForm({BabyImmunizationRecord? existing}) async {
    final name = TextEditingController(text: existing?.vaccineName ?? '');
    final by = TextEditingController(text: existing?.vaccinatedBy ?? '');
    var expected = existing?.expectedDate ?? _baby?.dob ?? DateTime.now();
    DateTime? givenOn = existing?.vaccinationDate;
    var isRequired = existing?.required ?? true;

    final saved = await _sheet(
      title: existing == null ? 'Add vaccine' : 'Edit vaccine',
      fields: (rebuild) => [
        _text('Vaccine name', name, hint: 'BCG, Pentavalent-1 ...'),
        _dateField('Due date', expected, rebuild, (d) => expected = d!,
            clearable: false),
        _dateField('Given on', givenOn, rebuild, (d) => givenOn = d),
        _switch('Required (core schedule)', isRequired, rebuild, (v) {
          isRequired = v;
        }),
        _text('Vaccinated by', by, hint: 'Dr. Shalini'),
      ],
      onSave: () async {
        if (name.text.trim().isEmpty) {
          _toast('Vaccine name is required');
          return false;
        }
        final row = BabyImmunizationRecordsCompanion(
          id: drift.Value(existing?.id ?? ''),
          birthRecordId: drift.Value(widget.birthRecordId),
          vaccineName: drift.Value(name.text.trim()),
          expectedDate: drift.Value(expected),
          vaccinationDate: drift.Value(givenOn),
          required: drift.Value(isRequired),
          vaccinatedBy: drift.Value(
            by.text.trim().isEmpty ? null : by.text.trim(),
          ),
        );
        if (existing == null) {
          await _db.createImmunization(row);
        } else {
          await _db.updateImmunization(row);
        }
        return true;
      },
    );

    if (saved) {
      await _load();
      _toast(existing == null ? 'Vaccine added' : 'Vaccine updated');
    }
  }

  // ---------------------- MILESTONES ----------------------

  Widget _milestoneList() {
    if (_milestones.isEmpty) {
      return _empty(
        Icons.emoji_events_rounded,
        'No milestones yet',
        'Add a milestone, or edit the date of birth to rebuild the standard '
            'developmental checklist.',
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 100),
      itemCount: _milestones.length,
      itemBuilder: (_, i) => _milestoneCard(_milestones[i]),
    );
  }

  Widget _milestoneCard(BabyMilestone milestone) {
    final status = CareStatus.resolve(
      status: milestone.achieved ? 'done' : 'pending',
      date: milestone.expectedDate,
    );

    return _card(
      leading: Checkbox(
        value: milestone.achieved,
        activeColor: const Color(0xFFF59E0B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        onChanged: (checked) async {
          await _db.setMilestoneAchieved(
            milestone.id,
            achieved: checked ?? false,
          );
          await _load();
        },
      ),
      title: milestone.milestone,
      titleStrikethrough: milestone.achieved,
      status: status,
      // Milestones are guides, not deadlines — an unmet one should not be
      // shouted at the mother as overdue.
      showStatus: milestone.achieved,
      lines: [
        milestone.description,
        if (milestone.expectedDate != null)
          'Usually around ${_dateFmt.format(milestone.expectedDate!)}',
        if (milestone.completed != null)
          'Achieved ${_dateFmt.format(milestone.completed!)}',
      ],
      synced: milestone.synced,
      onEdit: () => _openMilestoneForm(existing: milestone),
      onDelete: () => _confirmDelete(
        milestone.milestone,
        () => _db.deleteMilestone(milestone.id),
      ),
    );
  }

  void _addMilestone() => _openMilestoneForm();

  Future<void> _openMilestoneForm({BabyMilestone? existing}) async {
    final name = TextEditingController(text: existing?.milestone ?? '');
    final description = TextEditingController(
      text: existing?.description ?? '',
    );
    var expected = existing?.expectedDate ?? _baby?.dob ?? DateTime.now();
    DateTime? achievedOn = existing?.completed;

    final saved = await _sheet(
      title: existing == null ? 'Add milestone' : 'Edit milestone',
      fields: (rebuild) => [
        _text('Milestone', name, hint: 'First steps'),
        _text('Description', description, maxLines: 3),
        _dateField('Expected around', expected, rebuild, (d) => expected = d!,
            clearable: false),
        _dateField('Achieved on', achievedOn, rebuild, (d) => achievedOn = d),
      ],
      onSave: () async {
        if (name.text.trim().isEmpty) {
          _toast('Milestone name is required');
          return false;
        }
        if (description.text.trim().isEmpty) {
          _toast('Description is required');
          return false;
        }
        final row = BabyMilestonesCompanion(
          id: drift.Value(existing?.id ?? ''),
          birthRecordId: drift.Value(widget.birthRecordId),
          milestone: drift.Value(name.text.trim()),
          description: drift.Value(description.text.trim()),
          expectedDate: drift.Value(expected),
          achieved: drift.Value(achievedOn != null),
          completed: drift.Value(achievedOn),
        );
        if (existing == null) {
          await _db.createMilestone(row);
        } else {
          await _db.updateMilestone(row);
        }
        return true;
      },
    );

    if (saved) {
      await _load();
      _toast(existing == null ? 'Milestone added' : 'Milestone updated');
    }
  }

  // ---------------------- SHARED UI ----------------------

  Widget _empty(IconData icon, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: const Color(0xFFD1D5DB)),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E2024),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF6B707B),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required Widget leading,
    required String title,
    required bool titleStrikethrough,
    required CareStatus status,
    required bool showStatus,
    required List<String> lines,
    required int synced,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: status.needsAttention && !status.isDone
              ? status.color.withValues(alpha: 0.35)
              : const Color(0xFFEEEFF4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E2024),
                          decoration: titleStrikethrough
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                    if (showStatus) CareStatusChip(status: status),
                    if (synced == 0)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.sync_problem_rounded,
                          size: 14,
                          color: Color(0xFFB6BAC5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      line,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B707B),
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(String label, Future<void> Function() run) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Delete?'),
        content: Text('This removes "$label" from your baby\'s record.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await run();
    await _load();
    _toast('Deleted');
  }

  /// Bottom-sheet form. [onSave] returns false to keep the sheet open when
  /// validation fails; resolves true only once a save committed.
  Future<bool> _sheet({
    required String title,
    required List<Widget> Function(VoidCallback rebuild) fields,
    required Future<bool> Function() onSave,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void rebuild() => setSheetState(() {});
          return Padding(
            padding: EdgeInsets.only(
              left: 22,
              right: 22,
              top: 18,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 22,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E2024),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Color(0xFF9CA3AF),
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...fields(rebuild),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (await onSave() && ctx.mounted) {
                          Navigator.pop(ctx, true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B5C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.outfit(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    return result == true;
  }

  Widget _text(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1E2024)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _dateField(
    String label,
    DateTime? value,
    VoidCallback rebuild,
    ValueChanged<DateTime?> onChanged, {
    bool clearable = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2015),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            onChanged(picked);
            rebuild();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
              Text(
                value == null ? 'Not set' : _dateFmt.format(value),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: value == null
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF1E2024),
                ),
              ),
              if (clearable && value != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 24,
                  ),
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                  onPressed: () {
                    onChanged(null);
                    rebuild();
                  },
                )
              else
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _switch(
    String label,
    bool value,
    VoidCallback rebuild,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeThumbColor: const Color(0xFFFF3B5C),
          value: value,
          title: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          onChanged: (v) {
            onChanged(v);
            rebuild();
          },
        ),
      ),
    );
  }
}
