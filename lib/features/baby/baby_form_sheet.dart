import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/baby/baby_options.dart';
import 'package:allomom/repositories/baby_repository.dart';
import 'package:allomom/services/sync/sync_codec.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';

/// Add / edit form for a baby, shown as a bottom sheet.
///
/// Used from the Babies screen and the pregnancy journey, so every entry
/// point produces the same birth record shape. The registration flow's kids
/// step embeds [BabyFormSteps] directly instead.
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

/// Gender choices offered when adding a baby. "Other" stays in
/// [babyGenderOptions] so records that already hold it still get a label.
final _genderChoices = babyGenderOptions
    .where((o) => o.value != 'other')
    .toList();

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
  AppPalette get _p => context.palette;

  /// The baby asking for its own details, one step at a time.
  String _narrationKey = NarrationKeys.newBabyName;

  /// Editing is a correction, not an introduction, so it stays quiet.
  bool get _narrates => widget.existing == null;

  void _say(String key) {
    if (mounted) setState(() => _narrationKey = key);
    if (BackgroundAudioController.isReady) {
      BackgroundAudioController.to.playByKey(key, force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ink = _p.pick(const Color(0xFF1E2024), _p.textPrimary);

    // The baby peeks over the top of the sheet, hands on the rim.
    return BabySheetPeek(
      child: Container(
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
                        BabyFormSteps.accent,
                        const Color(0xFFFFF0F4),
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.child_care_rounded,
                      color: BabyFormSteps.accent,
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
                            color: ink,
                          ),
                        ),
                        Text(
                          widget.pregnancyId != null
                              ? 'Linked to this pregnancy'
                              : "We'll set up their vaccines & milestones",
                          style: TextStyle(
                            fontSize: 12,
                            color: _p.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              BabyFormSteps(
                existing: widget.existing,
                pregnancyId: widget.pregnancyId,
                initialDob: widget.initialDob,
                onNarrate: _narrates ? _say : null,
                // The sheet's own baby head card: slim, because a bottom
                // sheet over an open keyboard has no room for the full one.
                header: _narrates
                    ? BabySheetPrompt(
                        narrationKey: _narrationKey,
                        margin: EdgeInsets.zero,
                      )
                    : null,
                onSaved: (id) => Navigator.pop(context, id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The add / edit baby form as a three-step stepper: name, date of birth,
/// gender.
///
/// Shown inside [showBabyFormSheet], and embedded inline in the registration
/// flow's kids step, where it fills the step's fixed-height card ([expand]).
class BabyFormSteps extends StatefulWidget {
  const BabyFormSteps({
    super.key,
    this.existing,
    this.pregnancyId,
    this.initialDob,
    required this.onSaved,
    this.onCancel,
    this.onNarrate,
    this.title,
    this.header,
    this.expand = false,
  });

  static const accent = Color(0xFFFF3B5C);

  final Baby? existing;
  final String? pregnancyId;
  final DateTime? initialDob;

  /// Called with the birth record id once it is saved.
  final ValueChanged<String> onSaved;

  /// When set, the first step gets a back button that calls this.
  final VoidCallback? onCancel;

  /// Called with the narration key for each question the baby asks. Null
  /// keeps the form silent.
  final ValueChanged<String>? onNarrate;

  /// Shown above the step bars, e.g. "Add a child".
  final String? title;

  /// Shown between the step bars and the step's field.
  final Widget? header;

  /// Fill the parent's height, pinning the buttons to the bottom.
  final bool expand;

  @override
  State<BabyFormSteps> createState() => _BabyFormStepsState();
}

class _BabyFormStepsState extends State<BabyFormSteps> {
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static const _accent = BabyFormSteps.accent;

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

  late DateTime? _dob = widget.existing?.deliveryDate ?? widget.initialDob;
  late String? _gender =
      _genderChoices.any((o) => o.value == widget.existing?.gender)
      ? widget.existing?.gender
      : null;

  bool _saving = false;

  final FocusNode _nameFocus = FocusNode();

  /// Name, date of birth, gender — one question per step.
  static const _stepCount = 3;
  int _step = 0;

  static const _stepNarration = [
    NarrationKeys.newBabyName,
    NarrationKeys.newBabyDob,
    NarrationKeys.newBabyGender,
  ];

  String? _lastNarration;

  bool get _isEdit => widget.existing != null;

  bool get _hasGender => _gender != null && _gender!.trim().isNotEmpty;

  /// Whether the current step has what it needs to move on. The name is
  /// optional, so its step never blocks.
  bool get _canContinue => switch (_step) {
    0 => true,
    1 => _dob != null,
    _ => _hasGender,
  };

  bool get _isLastStep => _step == _stepCount - 1;

  @override
  void initState() {
    super.initState();
    // Reacting when she leaves the field rather than on every keystroke, so
    // the line lands on a finished name. Moving to the next step also drops
    // focus, and that step's own question wins.
    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus || _step != 0) return;
      if (_name.text.trim().isEmpty) return;
      if (_lastNarration == NarrationKeys.newBabyNameReaction) return;
      _say(NarrationKeys.newBabyNameReaction);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _say(_stepNarration[0]);
    });
  }

  void _say(String key) {
    _lastNarration = key;
    widget.onNarrate?.call(key);
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    FocusScope.of(context).unfocus();
    _say(_stepNarration[step]);
  }

  void _back() {
    if (_step > 0) {
      _goTo(_step - 1);
    } else {
      FocusScope.of(context).unfocus();
      widget.onCancel?.call();
    }
  }

  void _next() {
    if (!_canContinue || _saving) return;
    if (_isLastStep) {
      _save();
    } else {
      _goTo(_step + 1);
    }
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
    if (dob == null || !_hasGender) return;

    setState(() => _saving = true);
    try {
      String babyId;

      if (_isEdit) {
        final existing = widget.existing!;
        babyId = existing.id;
        // Changing the date of birth makes the server reschedule every dose
        // and milestone that has not been ticked off, so there is nothing to
        // re-seed from here any more. Delivery type, weight and blood group
        // are no longer asked here, so they are left as they were.
        await BabyRepository.instance.updateBaby(babyId, {
          'name': _trimmed(_name.text),
          'delivery_date': SyncCodec.isoUtc(dob),
          'gender': _gender,
        });
      } else {
        final createdId = await BabyRepository.instance.addBaby(
          dob: dob,
          pregnancyId: widget.pregnancyId,
          babyName: _trimmed(_name.text),
          gender: _gender,
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

      _say(NarrationKeys.newBabySaved);
      if (mounted) widget.onSaved(babyId);
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
    final body = AnimatedSize(
      duration: const Duration(milliseconds: 220),
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(_step), child: _stepBody()),
      ),
    );

    return Column(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepIndicator(),
        const SizedBox(height: 16),
        if (widget.header != null) ...[
          widget.header!,
          const SizedBox(height: 16),
        ],
        if (widget.expand)
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: body,
            ),
          )
        else
          body,
        SizedBox(height: widget.expand ? 12 : 22),
        _navButtons(),
      ],
    );
  }

  Widget _stepIndicator() {
    final stepText = Text(
      'Step ${_step + 1} of $_stepCount',
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: _inkSoft,
      ),
    );
    final bars = Row(
      children: [
        for (var i = 0; i < _stepCount; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              height: 4,
              decoration: BoxDecoration(
                color: i <= _step
                    ? _accent
                    : _p.pick(const Color(0xFFF1F2F4), _p.surface),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ],
    );

    final title = widget.title;
    if (title == null) {
      return Row(
        children: [
          Expanded(child: bars),
          const SizedBox(width: 12),
          stepText,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
            ),
            stepText,
          ],
        ),
        const SizedBox(height: 10),
        bars,
      ],
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label("BABY'S NAME (OPTIONAL)"),
            TextField(
              controller: _name,
              focusNode: _nameFocus,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _next(),
              style: TextStyle(color: _p.textPrimary),
              decoration: _fieldDecoration('e.g. Aarav'),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        ? _p.pick(
                            const Color(0xFFFFC9D4),
                            const Color(0xFF6B2E3A),
                          )
                        : _line,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cake_rounded, size: 18, color: _accent),
                    const SizedBox(width: 10),
                    Text(
                      _dob == null ? 'Select date' : _dateFmt.format(_dob!),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _dob == null ? _inkMuted : _ink,
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
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('GENDER'),
            Row(
              children: [
                for (final option in _genderChoices) ...[
                  if (option != _genderChoices.first) const SizedBox(width: 10),
                  Expanded(child: _genderTile(option)),
                ],
              ],
            ),
          ],
        );
    }
  }

  Widget _genderTile(({String value, String label}) option) {
    final isSelected = _gender == option.value;
    return GestureDetector(
      onTap: () => setState(() => _gender = option.value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? _p.tint(_accent, const Color(0xFFFFF0F3))
              : _field,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _accent : _line,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          option.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isSelected ? _accent : _ink,
          ),
        ),
      ),
    );
  }

  Widget _navButtons() {
    final enabled = _canContinue && !_saving;
    final showBack = _step > 0 || widget.onCancel != null;
    final label = _isLastStep
        ? (_isEdit ? 'Save changes' : 'Add baby')
        : (_step == 0 && _name.text.trim().isEmpty ? 'Skip' : 'Next');

    return Row(
      children: [
        if (showBack) ...[
          SizedBox(
            height: 52,
            width: 52,
            child: OutlinedButton(
              onPressed: _saving ? null : _back,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: _line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Icon(Icons.arrow_back_rounded, color: _ink, size: 20),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: enabled ? _next : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                disabledBackgroundColor: _p.pick(
                  const Color(0xFFE5E7EB),
                  _accent.withValues(alpha: 0.35),
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
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: enabled ? Colors.white : const Color(0xFF9CA3AF),
                      ),
                    ),
            ),
          ),
        ),
      ],
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
}
