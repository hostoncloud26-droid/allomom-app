import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/features/baby/baby_options.dart';
import 'package:allomom/repositories/baby_repository.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';

/// Add / edit form for a baby, shown as a bottom sheet.
///
/// Used from the Babies screen and from the registration flow's kids
/// question, so both produce the same birth record shape.
///
/// Resolves the birth record id on save, or null if the sheet was dismissed.
Future<String?> showBabyFormSheet(
  BuildContext context, {
  BirthRecord? existing,
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

  final BirthRecord? existing;
  final String? pregnancyId;
  final DateTime? initialDob;
  final String title;

  @override
  State<_BabyFormSheet> createState() => _BabyFormSheetState();
}

class _BabyFormSheetState extends State<_BabyFormSheet> {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.babyName ?? '',
  );
  late final TextEditingController _weight = TextEditingController(
    text: widget.existing?.weight?.toString() ?? '',
  );

  late DateTime? _dob = widget.existing?.dob ?? widget.initialDob;
  late String? _gender = widget.existing?.gender;
  late String? _deliveryType = widget.existing?.deliveryType;
  late String? _bloodGroup = widget.existing?.bloodGroup;

  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
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
    if (picked != null) setState(() => _dob = picked);
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
        final dobChanged = existing.dob != dob;
        await BabyRepository.instance.updateBaby(
          BirthRecordsCompanion(
            id: drift.Value(babyId),
            babyName: drift.Value(_trimmed(_name.text)),
            dob: drift.Value(dob),
            gender: drift.Value(_gender),
            deliveryType: drift.Value(_deliveryType),
            weight: drift.Value(weight),
            bloodGroup: drift.Value(_bloodGroup),
          ),
          rescheduleFrom: dobChanged ? dob : null,
        );
      } else {
        babyId = await BabyRepository.instance.addBaby(
          dob: dob,
          pregnancyId: widget.pregnancyId,
          babyName: _trimmed(_name.text),
          gender: _gender,
          deliveryType: _deliveryType,
          weight: weight,
          bloodGroup: _bloodGroup,
        );
      }

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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF0F4),
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
                          color: const Color(0xFF1E2024),
                        ),
                      ),
                      Text(
                        widget.pregnancyId != null
                            ? 'Linked to this pregnancy'
                            : "We'll set up their vaccines & milestones",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _label("BABY'S NAME (OPTIONAL)"),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
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
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _dob == null
                        ? const Color(0xFFFFC9D4)
                        : const Color(0xFFE5E7EB),
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
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF1E2024),
                      ),
                    ),
                    const Spacer(),
                    if (_dob != null)
                      Text(
                        babyAgeLabel(_dob),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
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
                  disabledBackgroundColor: const Color(0xFFFFC9D4),
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
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF6B7280),
      ),
    ),
  );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF9CA3AF)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
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
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
          selectedColor: const Color(0xFFFF3B5C),
          backgroundColor: const Color(0xFFF3F4F6),
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
