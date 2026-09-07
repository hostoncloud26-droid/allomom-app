import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:allomom/config/colors.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';
import 'package:allomom/services/sq_lite/services/report_db_service.dart';
import 'package:allomom/repositories/user_session_manager.dart';

/// Developer harness for the local pregnancy-care tables.
///
/// Exercises full create / read / update / delete against `pregnancies`,
/// `pregnancy_anc_schedule`, `vaccinations`, `report_checklists`, `reports`
/// and `report_attachments` so the schema can be verified on-device without
/// waiting on the API.
class TestPregnancyPage extends StatefulWidget {
  const TestPregnancyPage({super.key});

  @override
  State<TestPregnancyPage> createState() => _TestPregnancyPageState();
}

class _TestPregnancyPageState extends State<TestPregnancyPage>
    with SingleTickerProviderStateMixin {
  static const _statuses = ['pending', 'done', 'missed'];
  static const _uuid = Uuid();
  static final _dateFmt = DateFormat('dd MMM yyyy');

  final _care = PregnancyCareDbService.instance;
  final _health = HealthDbService.instance;
  final _reportDb = ReportDbService.instance;

  late final TabController _tabs = TabController(length: 4, vsync: this);

  bool _loading = true;

  List<Pregnancy> _pregnancies = [];
  String? _pregnancyId;

  List<PregnancyAncScheduleData> _ancVisits = [];
  List<Vaccination> _vaccinations = [];
  List<ReportChecklist> _checklists = [];

  List<Report> _reports = [];
  String? _reportId;
  List<ReportAttachment> _attachments = [];

  String get _userId => UserSessionManager.instance.userId;
  String get _healthId => UserSessionManager.instance.healthDataId;

  Pregnancy? get _pregnancy => _pregnancies.cast<Pregnancy?>().firstWhere(
    (p) => p?.id == _pregnancyId,
    orElse: () => null,
  );

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  // ---------------------- LOADING ----------------------

  Future<void> _loadAll() async {
    setState(() => _loading = true);

    final pregnancies = await _health.getAllPregnancies();
    final reports = await _reportDb.getAllReports();

    // Keep the current selections if they still exist, else fall back to the
    // newest row so the child tabs always have a parent to work against.
    final pregnancyId = pregnancies.any((p) => p.id == _pregnancyId)
        ? _pregnancyId
        : (pregnancies.isNotEmpty ? pregnancies.first.id : null);
    final reportId = reports.any((r) => r.id == _reportId)
        ? _reportId
        : (reports.isNotEmpty ? reports.first.id : null);

    _pregnancies = pregnancies;
    _pregnancyId = pregnancyId;
    _reports = reports;
    _reportId = reportId;

    await _loadChildren();

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadChildren() async {
    final pregnancyId = _pregnancyId;
    final reportId = _reportId;

    _ancVisits = pregnancyId == null
        ? []
        : await _care.getAncVisits(pregnancyId);
    _vaccinations = await _care.getVaccinations(_userId);
    _checklists = await _care.getReportChecklists(_userId);
    _attachments = reportId == null
        ? []
        : await _care.getReportAttachments(reportId);

    if (mounted) setState(() {});
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: textDark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---------------------- BUILD ----------------------

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Test Pregnancy · Local DB',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2024),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Reload from SQLite',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color(0xFF1E2024),
              size: 22,
            ),
            onPressed: _loadAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: primaryColor,
          unselectedLabelColor: textLight,
          indicatorColor: primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            Tab(text: 'ANC (${_ancVisits.length})'),
            Tab(text: 'Vaccines (${_vaccinations.length})'),
            Tab(text: 'Checklists (${_checklists.length})'),
            Tab(text: 'Attachments (${_attachments.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        onPressed: _addForCurrentTab,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _pregnancyPicker(),
                const Divider(height: 1, color: dividerColor),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _ancTab(),
                      _vaccinationTab(),
                      _checklistTab(),
                      _attachmentTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _addForCurrentTab() {
    switch (_tabs.index) {
      case 0:
        _openAncForm();
        break;
      case 1:
        _openVaccinationForm();
        break;
      case 2:
        _openChecklistForm();
        break;
      case 3:
        _openAttachmentForm();
        break;
    }
  }

  // ---------------------- PREGNANCY SELECTOR ----------------------

  Widget _pregnancyPicker() {
    final pregnancy = _pregnancy;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'PREGNANCY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: textLight,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _openPregnancyForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New'),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (_pregnancies.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'No pregnancies yet — tap New to create one.',
                style: TextStyle(fontSize: 13, color: textMedium),
              ),
            )
          else ...[
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _pregnancies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = _pregnancies[i];
                  final selected = p.id == _pregnancyId;
                  return ChoiceChip(
                    selected: selected,
                    label: Text(
                      p.lmpDate == null
                          ? 'LMP —'
                          : 'LMP ${_dateFmt.format(p.lmpDate!)}',
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : textMedium,
                    ),
                    selectedColor: primaryColor,
                    backgroundColor: surfaceLight,
                    showCheckmark: false,
                    side: BorderSide.none,
                    onSelected: (_) async {
                      setState(() => _pregnancyId = p.id);
                      await _loadChildren();
                    },
                  );
                },
              ),
            ),
            if (pregnancy != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _pill(
                          'EDD',
                          pregnancy.edDate == null
                              ? '—'
                              : _dateFmt.format(pregnancy.edDate!),
                        ),
                        _pill('Status', pregnancy.status),
                        _pill(
                          'G/P',
                          '${pregnancy.gravidity}/${pregnancy.parity}',
                        ),
                        if ((pregnancy.riskStatus ?? '').isNotEmpty)
                          _pill('Risk', pregnancy.riskStatus!),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit pregnancy',
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color: textMedium,
                    ),
                    onPressed: () => _openPregnancyForm(existing: pregnancy),
                  ),
                  IconButton(
                    tooltip: 'Delete pregnancy',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: dangerRed,
                    ),
                    onPressed: () => _deletePregnancy(pregnancy),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: accentLight,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        '$label · $value',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: textMedium,
        ),
      ),
    );
  }

  // ---------------------- TABS ----------------------

  Widget _ancTab() {
    if (_pregnancyId == null) {
      return _empty('Create a pregnancy first — ANC visits belong to one.');
    }
    if (_ancVisits.isEmpty) {
      return _empty('No ANC visits yet. Tap Add to schedule one.');
    }
    return _list(
      _ancVisits.map((v) {
        return _RowCard(
          title:
              'ANC-${v.visitNumber}'
              '${v.trimester == null ? '' : '  ·  T${v.trimester}'}',
          status: v.status,
          synced: v.synced,
          lines: [
            'Scheduled: ${_dateFmt.format(v.scheduledDate)}',
            if (v.actualDate != null)
              'Actual: ${_dateFmt.format(v.actualDate!)}',
            if (v.weightKg != null) 'Weight: ${v.weightKg} kg',
            if ((v.bp ?? '').isNotEmpty) 'BP: ${v.bp}',
            if (v.fundalHeightCm != null)
              'Fundal height: ${v.fundalHeightCm} cm',
            if (v.fetalHeartRate != null) 'FHR: ${v.fetalHeartRate} bpm',
            if ((v.notes ?? '').isNotEmpty) 'Notes: ${v.notes}',
          ],
          onEdit: () => _openAncForm(existing: v),
          onDelete: () => _confirmDelete(
            'ANC-${v.visitNumber}',
            () => _care.deleteAncVisit(v.id),
          ),
        );
      }).toList(),
    );
  }

  Widget _vaccinationTab() {
    if (_vaccinations.isEmpty) {
      return _empty('No vaccinations recorded. Tap Add to create one.');
    }
    return _list(
      _vaccinations.map((v) {
        return _RowCard(
          title: '${v.vaccineName}  ·  Dose ${v.doseNumber}',
          status: v.status,
          synced: v.synced,
          lines: [
            'Scheduled: ${_dateFmt.format(v.scheduledDate)}',
            if (v.administeredDate != null)
              'Administered: ${_dateFmt.format(v.administeredDate!)}',
            if ((v.batchNumber ?? '').isNotEmpty) 'Batch: ${v.batchNumber}',
            if ((v.administeredBy ?? '').isNotEmpty) 'By: ${v.administeredBy}',
            v.pregnancyId == null
                ? 'Scope: general / child vaccine'
                : 'Scope: maternal (this pregnancy)',
            if ((v.notes ?? '').isNotEmpty) 'Notes: ${v.notes}',
          ],
          onEdit: () => _openVaccinationForm(existing: v),
          onDelete: () => _confirmDelete(
            v.vaccineName,
            () => _care.deleteVaccination(v.id),
          ),
        );
      }).toList(),
    );
  }

  Widget _checklistTab() {
    if (_checklists.isEmpty) {
      return _empty('No report checklist items. Tap Add to create one.');
    }
    return _list(
      _checklists.map((c) {
        return _RowCard(
          title: c.reportName,
          status: c.status,
          synced: c.synced,
          lines: [
            if ((c.category ?? '').isNotEmpty) 'Category: ${c.category}',
            'Due: ${c.dueDate == null ? '—' : _dateFmt.format(c.dueDate!)}',
            if (c.completedDate != null)
              'Completed: ${_dateFmt.format(c.completedDate!)}',
            if ((c.filePath ?? '').isNotEmpty) 'File: ${c.filePath}',
            if ((c.resultSummary ?? '').isNotEmpty)
              'Result: ${c.resultSummary}',
            c.pregnancyId == null ? 'Scope: general' : 'Scope: this pregnancy',
            if ((c.notes ?? '').isNotEmpty) 'Notes: ${c.notes}',
          ],
          onEdit: () => _openChecklistForm(existing: c),
          onDelete: () => _confirmDelete(
            c.reportName,
            () => _care.deleteReportChecklist(c.id),
          ),
        );
      }).toList(),
    );
  }

  Widget _attachmentTab() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'PARENT REPORT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: textLight,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _openReportForm,
                    icon: const Icon(Icons.note_add_outlined, size: 17),
                    label: const Text('New report'),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (_reports.isEmpty)
                const Text(
                  'No reports yet — create one to attach files to.',
                  style: TextStyle(fontSize: 13, color: textMedium),
                )
              else
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _reports.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final r = _reports[i];
                      final selected = r.id == _reportId;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(r.reportType),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : textMedium,
                        ),
                        selectedColor: primaryColor,
                        backgroundColor: surfaceLight,
                        showCheckmark: false,
                        side: BorderSide.none,
                        onSelected: (_) async {
                          setState(() => _reportId = r.id);
                          await _loadChildren();
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, color: dividerColor),
        Expanded(
          child: _reportId == null
              ? _empty('Create a report first — attachments belong to one.')
              : _attachments.isEmpty
              ? _empty('No attachments yet. Tap Add to create one.')
              : _list(
                  _attachments.map((a) {
                    return _RowCard(
                      title: a.fileName ?? 'Attachment',
                      status: a.cloudUrl == null ? 'local only' : 'uploaded',
                      statusColor: a.cloudUrl == null
                          ? warningAmber
                          : successGreen,
                      synced: a.synced,
                      lines: [
                        'Local: ${a.localPath}',
                        'Cloud: ${a.cloudUrl ?? 'not uploaded'}',
                        if ((a.mimeType ?? '').isNotEmpty)
                          'Type: ${a.mimeType}',
                        if (a.fileSizeBytes != null)
                          'Size: ${a.fileSizeBytes} bytes',
                      ],
                      onEdit: () => _openAttachmentForm(existing: a),
                      onDelete: () => _confirmDelete(
                        a.fileName ?? 'attachment',
                        () => _care.deleteReportAttachment(a.id),
                      ),
                      trailingAction: a.cloudUrl == null
                          ? _RowAction(
                              label: 'Mark uploaded',
                              icon: Icons.cloud_upload_outlined,
                              onTap: () async {
                                await _care.markAttachmentUploaded(
                                  a.id,
                                  'https://cdn.example.com/${a.id}',
                                );
                                await _loadChildren();
                                _toast('Marked as uploaded');
                              },
                            )
                          : null,
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _list(List<Widget> children) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: children,
    );
  }

  Widget _empty(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13.5, color: textLight, height: 1.5),
        ),
      ),
    );
  }

  // ---------------------- DELETE ----------------------

  Future<void> _confirmDelete(String label, Future<void> Function() run) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete row?'),
        content: Text('This permanently removes "$label" from the local DB.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: dangerRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await run();
    await _loadChildren();
    _toast('Deleted');
  }

  Future<void> _deletePregnancy(Pregnancy pregnancy) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete pregnancy?'),
        content: const Text(
          'This also deletes its ANC visits, and any vaccinations and '
          'checklist items scoped to it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: dangerRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    await _care.deleteAllForPregnancy(pregnancy.id);
    await _health.deletePregnancy(pregnancy.id);
    _pregnancyId = null;
    await _loadAll();
    _toast('Pregnancy deleted');
  }

  // ---------------------- FORMS ----------------------

  Future<void> _openPregnancyForm({Pregnancy? existing}) async {
    final lmp = _ValueHolder<DateTime?>(existing?.lmpDate);
    final edd = _ValueHolder<DateTime?>(existing?.edDate);
    final status = _ValueHolder<String>(existing?.status ?? 'active');
    final gravidity = TextEditingController(
      text: (existing?.gravidity ?? 0).toString(),
    );
    final parity = TextEditingController(
      text: (existing?.parity ?? 0).toString(),
    );
    final risk = TextEditingController(text: existing?.riskStatus ?? '');

    final saved = await _sheet(
      title: existing == null ? 'New pregnancy' : 'Edit pregnancy',
      fields: (rebuild) => [
        _dateRow('LMP date', lmp, rebuild),
        _dateRow('EDD date', edd, rebuild),
        _dropdownRow('Status', status, const [
          'active',
          'completed',
          'miscarried',
        ], rebuild),
        _textRow('Gravida', gravidity, keyboard: TextInputType.number),
        _textRow('Para', parity, keyboard: TextInputType.number),
        _textRow('Risk status', risk, hint: 'e.g. low / high'),
      ],
      onSave: () async {
        if (lmp.value == null) {
          _toast('LMP date is required');
          return false;
        }
        final row = PregnanciesCompanion(
          id: drift.Value(existing?.id ?? _uuid.v7()),
          healthId: drift.Value(_healthId.isEmpty ? null : _healthId),
          lmpDate: drift.Value(lmp.value),
          edDate: drift.Value(
            edd.value ?? lmp.value!.add(const Duration(days: 280)),
          ),
          status: drift.Value(status.value),
          gravidity: drift.Value(int.tryParse(gravidity.text.trim()) ?? 0),
          parity: drift.Value(int.tryParse(parity.text.trim()) ?? 0),
          riskStatus: drift.Value(
            risk.text.trim().isEmpty ? null : risk.text.trim(),
          ),
          synced: const drift.Value(0),
        );
        await _health.savePregnancy(row);
        _pregnancyId = row.id.value;
        return true;
      },
    );

    if (saved) {
      await _loadAll();
      _toast(existing == null ? 'Pregnancy created' : 'Pregnancy updated');
    }
  }

  Future<void> _openAncForm({PregnancyAncScheduleData? existing}) async {
    final pregnancyId = _pregnancyId;
    if (pregnancyId == null) {
      _toast('Create a pregnancy first');
      return;
    }

    final visitNumber = TextEditingController(
      text: (existing?.visitNumber ?? _ancVisits.length + 1).toString(),
    );
    final trimester = TextEditingController(
      text: existing?.trimester?.toString() ?? '',
    );
    final scheduled = _ValueHolder<DateTime?>(
      existing?.scheduledDate ?? DateTime.now(),
    );
    final actual = _ValueHolder<DateTime?>(existing?.actualDate);
    final status = _ValueHolder<String>(existing?.status ?? 'pending');
    final weight = TextEditingController(
      text: existing?.weightKg?.toString() ?? '',
    );
    final bp = TextEditingController(text: existing?.bp ?? '');
    final fundal = TextEditingController(
      text: existing?.fundalHeightCm?.toString() ?? '',
    );
    final fhr = TextEditingController(
      text: existing?.fetalHeartRate?.toString() ?? '',
    );
    final notes = TextEditingController(text: existing?.notes ?? '');

    final saved = await _sheet(
      title: existing == null ? 'New ANC visit' : 'Edit ANC visit',
      fields: (rebuild) => [
        _textRow('Visit number', visitNumber, keyboard: TextInputType.number),
        _textRow('Trimester (1-3)', trimester, keyboard: TextInputType.number),
        _dateRow('Scheduled date', scheduled, rebuild),
        _dateRow('Actual date', actual, rebuild),
        _dropdownRow('Status', status, _statuses, rebuild),
        _textRow('Weight (kg)', weight, keyboard: TextInputType.number),
        _textRow('BP', bp, hint: '120/80'),
        _textRow('Fundal height (cm)', fundal, keyboard: TextInputType.number),
        _textRow('Fetal heart rate', fhr, keyboard: TextInputType.number),
        _textRow('Notes', notes, maxLines: 3),
      ],
      onSave: () async {
        if (scheduled.value == null) {
          _toast('Scheduled date is required');
          return false;
        }
        final row = PregnancyAncScheduleCompanion(
          id: drift.Value(existing?.id ?? ''),
          pregnancyId: drift.Value(pregnancyId),
          visitNumber: drift.Value(int.tryParse(visitNumber.text.trim()) ?? 1),
          trimester: drift.Value(int.tryParse(trimester.text.trim())),
          scheduledDate: drift.Value(scheduled.value!),
          actualDate: drift.Value(actual.value),
          status: drift.Value(status.value),
          weightKg: drift.Value(double.tryParse(weight.text.trim())),
          bp: drift.Value(bp.text.trim().isEmpty ? null : bp.text.trim()),
          fundalHeightCm: drift.Value(double.tryParse(fundal.text.trim())),
          fetalHeartRate: drift.Value(int.tryParse(fhr.text.trim())),
          notes: drift.Value(
            notes.text.trim().isEmpty ? null : notes.text.trim(),
          ),
        );
        if (existing == null) {
          await _care.createAncVisit(row);
        } else {
          await _care.updateAncVisit(row);
        }
        return true;
      },
    );

    if (saved) {
      await _loadChildren();
      _toast(existing == null ? 'ANC visit added' : 'ANC visit updated');
    }
  }

  Future<void> _openVaccinationForm({Vaccination? existing}) async {
    final name = TextEditingController(text: existing?.vaccineName ?? '');
    final dose = TextEditingController(
      text: (existing?.doseNumber ?? 1).toString(),
    );
    final scheduled = _ValueHolder<DateTime?>(
      existing?.scheduledDate ?? DateTime.now(),
    );
    final administered = _ValueHolder<DateTime?>(existing?.administeredDate);
    final status = _ValueHolder<String>(existing?.status ?? 'pending');
    final batch = TextEditingController(text: existing?.batchNumber ?? '');
    final by = TextEditingController(text: existing?.administeredBy ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    // Maternal vaccines link to the selected pregnancy; general ones don't.
    final maternal = _ValueHolder<bool>(
      existing == null ? _pregnancyId != null : existing.pregnancyId != null,
    );

    final saved = await _sheet(
      title: existing == null ? 'New vaccination' : 'Edit vaccination',
      fields: (rebuild) => [
        _textRow('Vaccine name', name, hint: 'TT, Tdap, BCG ...'),
        _textRow('Dose number', dose, keyboard: TextInputType.number),
        _dateRow('Scheduled date', scheduled, rebuild),
        _dateRow('Administered date', administered, rebuild),
        _dropdownRow('Status', status, _statuses, rebuild),
        _switchRow(
          'Maternal (link to pregnancy)',
          maternal,
          rebuild,
          enabled: _pregnancyId != null,
          subtitle: _pregnancyId == null
              ? 'No pregnancy selected — saved as a general vaccine.'
              : null,
        ),
        _textRow('Batch number', batch),
        _textRow('Administered by', by),
        _textRow('Notes', notes, maxLines: 3),
      ],
      onSave: () async {
        if (name.text.trim().isEmpty) {
          _toast('Vaccine name is required');
          return false;
        }
        if (scheduled.value == null) {
          _toast('Scheduled date is required');
          return false;
        }
        final row = VaccinationsCompanion(
          id: drift.Value(existing?.id ?? ''),
          userId: drift.Value(_userId.isEmpty ? null : _userId),
          pregnancyId: drift.Value(
            maternal.value && _pregnancyId != null ? _pregnancyId : null,
          ),
          vaccineName: drift.Value(name.text.trim()),
          doseNumber: drift.Value(int.tryParse(dose.text.trim()) ?? 1),
          scheduledDate: drift.Value(scheduled.value!),
          administeredDate: drift.Value(administered.value),
          status: drift.Value(status.value),
          batchNumber: drift.Value(
            batch.text.trim().isEmpty ? null : batch.text.trim(),
          ),
          administeredBy: drift.Value(
            by.text.trim().isEmpty ? null : by.text.trim(),
          ),
          notes: drift.Value(
            notes.text.trim().isEmpty ? null : notes.text.trim(),
          ),
        );
        if (existing == null) {
          await _care.createVaccination(row);
        } else {
          await _care.updateVaccination(row);
        }
        return true;
      },
    );

    if (saved) {
      await _loadChildren();
      _toast(existing == null ? 'Vaccination added' : 'Vaccination updated');
    }
  }

  Future<void> _openChecklistForm({ReportChecklist? existing}) async {
    final name = TextEditingController(text: existing?.reportName ?? '');
    final category = _ValueHolder<String>(existing?.category ?? 'blood');
    final due = _ValueHolder<DateTime?>(existing?.dueDate ?? DateTime.now());
    final completed = _ValueHolder<DateTime?>(existing?.completedDate);
    final status = _ValueHolder<String>(existing?.status ?? 'pending');
    final filePath = TextEditingController(text: existing?.filePath ?? '');
    final result = TextEditingController(text: existing?.resultSummary ?? '');
    final notes = TextEditingController(text: existing?.notes ?? '');
    final scoped = _ValueHolder<bool>(
      existing == null ? _pregnancyId != null : existing.pregnancyId != null,
    );

    final saved = await _sheet(
      title: existing == null ? 'New checklist item' : 'Edit checklist item',
      fields: (rebuild) => [
        _textRow('Report name', name, hint: 'CBC, Urine R/E, USG Level II'),
        _dropdownRow('Category', category, const [
          'blood',
          'urine',
          'imaging',
          'other',
        ], rebuild),
        _dateRow('Due date', due, rebuild),
        _dateRow('Completed date', completed, rebuild),
        _dropdownRow('Status', status, _statuses, rebuild),
        _switchRow(
          'Scope to pregnancy',
          scoped,
          rebuild,
          enabled: _pregnancyId != null,
          subtitle: _pregnancyId == null
              ? 'No pregnancy selected — saved as a general item.'
              : null,
        ),
        _textRow('Local file path', filePath),
        _textRow('Result summary', result, maxLines: 2),
        _textRow('Notes', notes, maxLines: 3),
      ],
      onSave: () async {
        if (name.text.trim().isEmpty) {
          _toast('Report name is required');
          return false;
        }
        final row = ReportChecklistsCompanion(
          id: drift.Value(existing?.id ?? ''),
          userId: drift.Value(_userId.isEmpty ? null : _userId),
          pregnancyId: drift.Value(
            scoped.value && _pregnancyId != null ? _pregnancyId : null,
          ),
          reportName: drift.Value(name.text.trim()),
          category: drift.Value(category.value),
          dueDate: drift.Value(due.value),
          completedDate: drift.Value(completed.value),
          status: drift.Value(status.value),
          filePath: drift.Value(
            filePath.text.trim().isEmpty ? null : filePath.text.trim(),
          ),
          resultSummary: drift.Value(
            result.text.trim().isEmpty ? null : result.text.trim(),
          ),
          notes: drift.Value(
            notes.text.trim().isEmpty ? null : notes.text.trim(),
          ),
        );
        if (existing == null) {
          await _care.createReportChecklist(row);
        } else {
          await _care.updateReportChecklist(row);
        }
        return true;
      },
    );

    if (saved) {
      await _loadChildren();
      _toast(existing == null ? 'Checklist item added' : 'Checklist updated');
    }
  }

  /// Attachments need a parent `reports` row, so the harness can mint one.
  Future<void> _openReportForm() async {
    final type = TextEditingController(text: 'Lab Report');
    final description = TextEditingController();

    final saved = await _sheet(
      title: 'New report',
      fields: (rebuild) => [
        _textRow('Report type', type, hint: 'Lab Report, Ultrasound ...'),
        _textRow('Description', description, maxLines: 3),
      ],
      onSave: () async {
        if (type.text.trim().isEmpty) {
          _toast('Report type is required');
          return false;
        }
        final id = _uuid.v7();
        await _reportDb.saveReport(
          ReportsCompanion(
            id: drift.Value(id),
            reportType: drift.Value(type.text.trim()),
            healthDataID: drift.Value(_healthId.isEmpty ? null : _healthId),
            description: drift.Value(
              description.text.trim().isEmpty ? null : description.text.trim(),
            ),
            synced: const drift.Value(0),
          ),
        );
        _reportId = id;
        return true;
      },
    );

    if (saved) {
      await _loadAll();
      _toast('Report created');
    }
  }

  Future<void> _openAttachmentForm({ReportAttachment? existing}) async {
    final reportId = _reportId;
    if (reportId == null) {
      _toast('Create a report first');
      return;
    }

    final localPath = TextEditingController(text: existing?.localPath ?? '');
    final cloudUrl = TextEditingController(text: existing?.cloudUrl ?? '');
    final fileName = TextEditingController(text: existing?.fileName ?? '');
    final mimeType = _ValueHolder<String>(
      existing?.mimeType ?? 'application/pdf',
    );
    final size = TextEditingController(
      text: existing?.fileSizeBytes?.toString() ?? '',
    );

    final saved = await _sheet(
      title: existing == null ? 'New attachment' : 'Edit attachment',
      fields: (rebuild) => [
        _textRow('Local path', localPath, hint: '/data/user/0/.../report.pdf'),
        _textRow('File name', fileName, hint: 'cbc_report.pdf'),
        _dropdownRow('MIME type', mimeType, const [
          'application/pdf',
          'image/png',
          'image/jpeg',
          'text/plain',
        ], rebuild),
        _textRow('Size (bytes)', size, keyboard: TextInputType.number),
        _textRow('Cloud URL', cloudUrl, hint: 'blank until uploaded'),
      ],
      onSave: () async {
        if (localPath.text.trim().isEmpty) {
          _toast('Local path is required');
          return false;
        }
        final row = ReportAttachmentsCompanion(
          id: drift.Value(existing?.id ?? ''),
          reportId: drift.Value(reportId),
          localPath: drift.Value(localPath.text.trim()),
          cloudUrl: drift.Value(
            cloudUrl.text.trim().isEmpty ? null : cloudUrl.text.trim(),
          ),
          fileName: drift.Value(
            fileName.text.trim().isEmpty ? null : fileName.text.trim(),
          ),
          mimeType: drift.Value(mimeType.value),
          fileSizeBytes: drift.Value(int.tryParse(size.text.trim())),
        );
        if (existing == null) {
          await _care.createReportAttachment(row);
        } else {
          await _care.updateReportAttachment(row);
        }
        return true;
      },
    );

    if (saved) {
      await _loadChildren();
      _toast(existing == null ? 'Attachment added' : 'Attachment updated');
    }
  }

  // ---------------------- FORM PRIMITIVES ----------------------

  /// Shows a scrollable bottom-sheet form. [onSave] returns false to keep the
  /// sheet open (validation failed). Resolves true only when a save committed.
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void rebuild() => setSheetState(() {});
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: textDark,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: textLight,
                          ),
                          onPressed: () => Navigator.pop(ctx, false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...fields(rebuild),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final committed = await onSave();
                          if (committed && ctx.mounted) {
                            Navigator.pop(ctx, true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 15,
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
        );
      },
    );
    return result == true;
  }

  Widget _textRow(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(fontSize: 14, color: textDark),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(fontSize: 13, color: textMedium),
          hintStyle: const TextStyle(fontSize: 13, color: textLight),
          filled: true,
          fillColor: surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
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

  Widget _dateRow(
    String label,
    _ValueHolder<DateTime?> holder,
    VoidCallback rebuild,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: holder.value ?? DateTime.now(),
            firstDate: DateTime(2015),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            holder.value = picked;
            rebuild();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          decoration: BoxDecoration(
            color: surfaceLight,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: textMedium),
              ),
              const Spacer(),
              Text(
                holder.value == null
                    ? 'Not set'
                    : _dateFmt.format(holder.value!),
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: holder.value == null ? textLight : textDark,
                ),
              ),
              if (holder.value != null)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 24,
                  ),
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 16,
                    color: textLight,
                  ),
                  onPressed: () {
                    holder.value = null;
                    rebuild();
                  },
                )
              else
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: textLight,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownRow(
    String label,
    _ValueHolder<String> holder,
    List<String> options,
    VoidCallback rebuild,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: options.contains(holder.value) ? holder.value : null,
        isExpanded: true,
        style: const TextStyle(fontSize: 14, color: textDark),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: textMedium),
          filled: true,
          fillColor: surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
        ),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          holder.value = v;
          rebuild();
        },
      ),
    );
  }

  Widget _switchRow(
    String label,
    _ValueHolder<bool> holder,
    VoidCallback rebuild, {
    bool enabled = true,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: surfaceLight,
          borderRadius: BorderRadius.circular(11),
        ),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          activeThumbColor: primaryColor,
          value: enabled && holder.value,
          title: Text(
            label,
            style: const TextStyle(fontSize: 13, color: textMedium),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: textLight),
                ),
          onChanged: enabled
              ? (v) {
                  holder.value = v;
                  rebuild();
                }
              : null,
        ),
      ),
    );
  }
}

/// Mutable box so bottom-sheet fields can write back without a form key.
class _ValueHolder<T> {
  _ValueHolder(this.value);
  T value;
}

class _RowAction {
  const _RowAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _RowCard extends StatelessWidget {
  const _RowCard({
    required this.title,
    required this.status,
    required this.synced,
    required this.lines,
    required this.onEdit,
    required this.onDelete,
    this.statusColor,
    this.trailingAction,
  });

  final String title;
  final String status;
  final int synced;
  final List<String> lines;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Color? statusColor;
  final _RowAction? trailingAction;

  Color get _statusColor {
    if (statusColor != null) return statusColor!;
    switch (status) {
      case 'done':
        return successGreen;
      case 'missed':
        return dangerRed;
      default:
        return warningAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: _statusColor,
                  ),
                ),
              ),
              if (synced == 0)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.sync_problem_rounded,
                    size: 15,
                    color: textLight,
                  ),
                ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 19,
                  color: textLight,
                ),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                  if (v == 'action') trailingAction?.onTap();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (trailingAction != null)
                    PopupMenuItem(
                      value: 'action',
                      child: Row(
                        children: [
                          Icon(trailingAction!.icon, size: 17),
                          const SizedBox(width: 8),
                          Text(trailingAction!.label),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: dangerRed)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 3, right: 8),
              child: Text(
                line,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: textMedium,
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
