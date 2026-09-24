import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/baby/baby_options.dart';
import 'package:allomom/repositories/baby_repository.dart';
import 'package:allomom/services/sync/sync_codec.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';

/// Add / edit form for a baby, shown as a bottom sheet.
///
/// Used from the Babies screen and from the registration flow's kids
/// question, so both produce the same birth record shape.
///
/// Resolves the birth record id on save, or null if the sheet was dismissed.
Future<String?> showBabyFormSheet(
  BuildContext context, {
  Baby? existing,
  String? pregnancyId,
  DateTime? initialDob,
  String title = 'Add your baby',
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BabyFormSheet(
      existing: existing,
      pregnancyId: pregnancyId,
      initialDob: initialDob,
      title: title,
    ),
  );
}

class _BabyFormSheet extends StatefulWidget {
  const _BabyFormSheet({
    this.existing,
    this.pregnancyId,
    this.initialDob,
    required this.title,
  });

  final Baby? existing;
  final String? pregnancyId;
  final DateTime? initialDob;
  final String title;

  @override
  State<_BabyFormSheet> createState() => _BabyFormSheetState();
}

class _BabyFormSheetState extends State<_BabyFormSheet> {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  // Neutral ink, fills and lines follow light / dark mode.
  AppPalette get _p => context.palette;
  Color get _ink => _p.pick(const Color(0xFF1E2024), _p.textPrimary);
  Color get _inkSoft => _p.textSecondary;
  Color get _inkMuted => _p.textMuted;
  Color get _field => _p.inputFill;
  Color get _line => _p.border;

  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.name ?? '',
  );
  late final TextEditingController _weight = TextEditingController(
    text: widget.existing?.weight?.toString() ?? '',
  );

  late DateTime? _dob = widget.existing?.deliveryDate ?? widget.initialDob;
  late String? _gender = widget.existing?.gender;
  late String? _deliveryType = widget.existing?.typeOfDelivery;
  late String? _bloodGroup = widget.existing?.bloodGroup;

  bool _saving = false;

  final FocusNode _nameFocus = FocusNode();

  /// The baby asking for its own details, one field at a time.
  ///
  /// Only for a new record: editing a baby already added is not the moment for
  /// "What name did you give me?".
  late String _narrationKey = NarrationKeys.newBabyName;

  bool get _isEdit => widget.existing != null;

  /// Whether the sheet speaks at all. Editing is a correction, not an
  /// introduction.
  bool get _narrates => !_isEdit;

  @override
  void initState() {
    super.initState();
    // Reacting when she leaves the field rather than on every keystroke, so
    // the line lands on a finished name.
    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus) return;
      if (_name.text.trim().isEmpty) return;
      if (_narrationKey == NarrationKeys.newBabyNameReaction) return;
      _say(NarrationKeys.newBabyNameReaction);
    });
  }

  void _say(String key) {
    if (!mounted || !_narrates) return;
    setState(() => _narrationKey = key);
    if (BackgroundAudioController.isReady) {
      BackgroundAudioController.to.playByKey(key, force: true);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    _say(NarrationKeys.newBabyDob);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? now,
      // A birth date is never in the future, and 18 years back covers any
      // previous child a mother would track here.
      firstDate: DateTime(now.year - 18),
      lastDate: now,
      helpText: "Baby's date of birth",
    );
    if (picked != null) {
      setState(() => _dob = picked);
      // Date answered, so the baby moves on to the next question rather than
      // commenting on the one she has just finished.
      _say(NarrationKeys.newBabyGender);
    }
  }

  Future<void> _save() async {
    final dob = _dob;
    if (dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please pick your baby's date of birth"),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final weight = double.tryParse(_weight.text.trim());
      String babyId;

      if (_isEdit) {
        final existing = widget.existing!;
        babyId = existing.id;
        // Only re-seed the schedule when the date of birth actually moved —
        // it rebuilds every dose and milestone, losing what was ticked off.
        // Changing the date of birth makes the server reschedule every dose
        // and milestone that has not been ticked off, so there is nothing to
        // re-seed from here any more.
        await BabyRepository.instance.updateBaby(babyId, {
          'name': _trimmed(_name.text),
          'delivery_date': SyncCodec.isoUtc(dob),
          'gender': _gender,
          'type_of_delivery': _deliveryType,
          'weight': weight,
          'blood_group': _bloodGroup,
        });
      } else {
        final createdId = await BabyRepository.instance.addBaby(
          dob: dob,
          pregnancyId: widget.pregnancyId,
          babyName: _trimmed(_name.text),
          gender: _gender,
          deliveryType: _deliveryType,
          weight: weight,
          bloodGroup: _bloodGroup,
        );
        if (createdId == null) {
          // The schedules are seeded server-side, so a baby that never reached
          // the server would be a name with no care plan behind it. Better to
          // say so than to leave a half-created record on the device.
          if (!mounted) return;
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not add your baby right now. Please check your '
                'connection and try again.',
              ),
              backgroundColor: Color(0xFFB91C1C),
            ),
          );
          return;
        }
        babyId = createdId;
      }

      if (_narrates) speak(NarrationKeys.newBabySaved, force: true);
      if (mounted) Navigator.pop(context, babyId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save baby: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  static String? _trimmed(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _p.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _p.tint(
                      const Color(0xFFFF3B5C),
                      const Color(0xFFFFF0F4),
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.child_care_rounded,
                    color: Color(0xFFFF3B5C),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.outfit(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      Text(
                        widget.pregnancyId != null
                            ? 'Linked to this pregnancy'
                            : "We'll set up their vaccines & milestones",
                        style: TextStyle(
                          fontSize: 12,
                          color: _inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // The sheet's own baby head card: slim, because a bottom sheet
            // over an open keyboard has no room for the full one.
            if (_narrates) ...[
              BabyPromptBar(
                narrationKey: _narrationKey,
                margin: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 4),

            _label("BABY'S NAME (OPTIONAL)"),
            TextField(
              controller: _name,
              focusNode: _nameFocus,
              textCapitalization: TextCapitalization.words,
              style: TextStyle(color: _p.textPrimary),
              decoration: _fieldDecoration('e.g. Aarav'),
            ),
            const SizedBox(height: 16),

            _label('DATE OF BIRTH'),
            InkWell(
              onTap: _pickDob,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _field,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _dob == null
                        ? context.palette.pick(
                            const Color(0xFFFFC9D4),
                            const Color(0xFF6B2E3A),
                          )
                        : _line,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cake_rounded,
                      size: 18,
                      color: Color(0xFFFF3B5C),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _dob == null ? 'Select date' : _dateFmt.format(_dob!),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _dob == null
                            ? _inkMuted
                            : _ink,
                      ),
                    ),
                    const Spacer(),
                    if (_dob != null)
                      Text(
                        babyAgeLabel(_dob),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _inkSoft,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            _label('GENDER'),
            _chips(
              options: babyGenderOptions,
              selected: _gender,
              onSelected: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 16),

            _label('DELIVERY TYPE'),
            _chips(
              options: deliveryTypeOptions,
              selected: _deliveryType,
              onSelected: (v) => setState(() => _deliveryType = v),
            ),
            const SizedBox(height: 16),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('BIRTH WEIGHT (KG)'),
                      TextField(
                        controller: _weight,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: TextStyle(color: _p.textPrimary),
                        decoration: _fieldDecoration('3.2'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('BLOOD GROUP'),
                      DropdownButtonFormField<String>(
                        initialValue: _bloodGroup,
                        isExpanded: true,
                        dropdownColor: _p.card,
                        style: TextStyle(fontSize: 16, color: _p.textPrimary),
                        decoration: _fieldDecoration('Select'),
                        items: bloodGroupOptions
                            .map(
                              (g) =>
                                  DropdownMenuItem(value: g, child: Text(g)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _bloodGroup = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B5C),
                  disabledBackgroundColor: _p.pick(
                    const Color(0xFFFFC9D4),
                    const Color(0xFFFF3B5C).withValues(alpha: 0.35),
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _isEdit ? 'Save changes' : 'Add baby',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _inkSoft,
      ),
    ),
  );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 13.5, color: _inkMuted),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: _line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: _line),
    ),
    filled: true,
    fillColor: _field,
  );

  Widget _chips({
    required List<({String value, String label})> options,
    required String? selected,
    required ValueChanged<String?> onSelected,
  }) {
    return Wrap(
      spacing: 8,
      children: options.map((option) {
        final isSelected = selected == option.value;
        return ChoiceChip(
          selected: isSelected,
          label: Text(option.label),
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : _p.textSecondary,
          ),
          selectedColor: const Color(0xFFFF3B5C),
          backgroundColor: _p.pick(const Color(0xFFF3F4F6), _p.surface),
          showCheckmark: false,
          side: BorderSide.none,
          // Tapping the selected chip clears it, since both fields are
          // optional on a birth record.
          onSelected: (_) => onSelected(isSelected ? null : option.value),
        );
      }).toList(),
    );
  }
}
