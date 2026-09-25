import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import 'package:allomom/components/baby_bottom_avatar.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_catalog.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

/// What the mother tells us about the birth.
class BirthDetails {
  const BirthDetails({
    required this.deliveryDate,
    required this.deliveryType,
    required this.gender,
    this.weightKg,
    this.photoPath,
  });

  final DateTime deliveryDate;

  /// `birth_records.delivery_type`: `normal` or `c-section`.
  final String deliveryType;

  /// `male` or `female`.
  final String gender;

  final double? weightKg;

  /// Local file path of the first photo; nothing is uploaded.
  final String? photoPath;
}

/// "Welcome your baby": completing a pregnancy, one question at a time.
///
/// 1. When was the baby born.
/// 2. How — delivery type — and who: boy or girl, and the birth weight.
/// 3. The first photo, which can be skipped.
///
/// The baby sits in the sheet above the buttons and says each step's line, so
/// the bottom popup — which would float over the buttons — stays away.
class WelcomeBabySheet extends StatefulWidget {
  const WelcomeBabySheet({super.key, required this.onSubmit});

  /// Saves the birth. Throwing keeps the sheet open so she can retry.
  final Future<void> Function(BirthDetails details) onSubmit;

  /// Opens the sheet; resolves to the details once saved, or null if she
  /// closed it.
  static Future<BirthDetails?> show(
    BuildContext context, {
    required Future<void> Function(BirthDetails details) onSubmit,
  }) {
    return showModalBottomSheet<BirthDetails>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WelcomeBabySheet(onSubmit: onSubmit),
    );
  }

  @override
  State<WelcomeBabySheet> createState() => _WelcomeBabySheetState();
}

class _WelcomeBabySheetState extends State<WelcomeBabySheet> {
  static const _rose = Color(0xFFFF3B5C);
  static final _longDate = DateFormat('EEEE, d MMMM yyyy');

  static const _steps = [
    (
      title: 'When was baby born?',
      subtitle: 'Pick the delivery date',
      icon: Icons.event_available_rounded,
      narration: NarrationKeys.pgBirthDate,
    ),
    (
      title: 'About your baby',
      subtitle: 'Delivery, gender and birth weight',
      icon: Icons.child_care_rounded,
      narration: NarrationKeys.pgBirthDetails,
    ),
    (
      title: "Baby's first photo",
      subtitle: 'Optional — you can add it later',
      icon: Icons.photo_camera_rounded,
      narration: NarrationKeys.pgBirthPhoto,
    ),
  ];

  final _weightController = TextEditingController();

  int _step = 0;
  late DateTime _deliveryDate;
  String? _deliveryType;
  String? _gender;
  String? _photoPath;
  bool _isSubmitting = false;

  AppPalette get _p => context.palette;
  Color get _ink => _p.pick(const Color(0xFF1E2024), _p.textPrimary);
  Color get _inkMuted => _p.pick(const Color(0xFF8E95A5), _p.textMuted);
  Color get _roseSoft => _p.tint(_rose, const Color(0xFFFFF0F4));
  Color get _roseBorder => _p.pick(const Color(0xFFFFD3DC), _p.accentBorder);

  String get _narrationKey => _steps[_step].narration;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _deliveryDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakStep());
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _speakStep() {
    if (mounted) speak(_narrationKey, force: true);
  }

  double? get _weight {
    final raw = _weightController.text.trim().replaceAll(',', '.');
    return raw.isEmpty ? null : double.tryParse(raw);
  }

  /// A weight is optional, but one that is typed must be believable.
  bool get _weightValid {
    if (_weightController.text.trim().isEmpty) return true;
    final w = _weight;
    return w != null && w >= 0.3 && w <= 7;
  }

  bool get _canContinue => switch (_step) {
    1 => _deliveryType != null && _gender != null && _weightValid,
    _ => true,
  };

  void _goTo(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _step = step);
    _speakStep();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1440,
      );
      if (picked != null && mounted) setState(() => _photoPath = picked.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add photo: $e')));
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting || _deliveryType == null || _gender == null) return;
    setState(() => _isSubmitting = true);
    final details = BirthDetails(
      deliveryDate: _deliveryDate,
      deliveryType: _deliveryType!,
      gender: _gender!,
      weightKg: _weight,
      photoPath: _photoPath,
    );
    try {
      await widget.onSubmit(details);
      if (mounted) Navigator.pop(context, details);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not complete the journey. Please try again.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final isLast = _step == _steps.length - 1;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _p.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _p.pick(const Color(0xFFE9EAEF), _p.divider),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildHeader(step.title, step.subtitle, step.icon),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildProgress(),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0.06, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: switch (_step) {
                        0 => _buildDateStep(),
                        1 => _buildDetailsStep(),
                        _ => _buildPhotoStep(),
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildBaby(),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _buildButtons(isLast),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER & PROGRESS ─────────────────────────────────────
  Widget _buildHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: _roseSoft, shape: BoxShape.circle),
          child: Icon(icon, color: _rose, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STEP ${_step + 1} OF ${_steps.length}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: _rose,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              Text(subtitle, style: TextStyle(fontSize: 12, color: _inkMuted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 5,
              decoration: BoxDecoration(
                color: i <= _step ? _rose : _roseSoft,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── STEP 1: DELIVERY DATE ─────────────────────────────────
  Widget _buildDateStep() {
    final today = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _roseSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.cake_rounded, size: 19, color: _rose),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _longDate.format(_deliveryDate),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: _rose, onPrimary: Colors.white),
          ),
          child: CalendarDatePicker(
            initialDate: _deliveryDate,
            // Recorded up to three months after the birth, and up to a week
            // ahead for a planned delivery she is logging early.
            firstDate: today.subtract(const Duration(days: 90)),
            lastDate: today.add(const Duration(days: 7)),
            onDateChanged: (d) => setState(() => _deliveryDate = d),
          ),
        ),
      ],
    );
  }

  // ─── STEP 2: DELIVERY TYPE, GENDER, WEIGHT ─────────────────
  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('DELIVERY TYPE'),
        Row(
          children: [
            Expanded(
              child: _optionCard(
                emoji: '🌸',
                label: 'Normal',
                selected: _deliveryType == 'normal',
                onTap: () => setState(() => _deliveryType = 'normal'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _optionCard(
                emoji: '🏥',
                label: 'C-Section',
                selected: _deliveryType == 'c-section',
                onTap: () => setState(() => _deliveryType = 'c-section'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _label('GENDER'),
        Row(
          children: [
            Expanded(
              child: _optionCard(
                emoji: '👦',
                label: 'Boy',
                selected: _gender == 'male',
                onTap: () => setState(() => _gender = 'male'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _optionCard(
                emoji: '👧',
                label: 'Girl',
                selected: _gender == 'female',
                onTap: () => setState(() => _gender = 'female'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _label('BIRTH WEIGHT (OPTIONAL)'),
        TextField(
          controller: _weightController,
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. 3.2',
            hintStyle: TextStyle(fontSize: 13.5, color: _inkMuted),
            errorText: _weightValid
                ? null
                : 'Enter a weight between 0.3 and 7 kg',
            prefixIcon: const Icon(
              Icons.monitor_weight_rounded,
              size: 19,
              color: _rose,
            ),
            suffixText: 'kg',
            suffixStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _inkMuted,
            ),
            filled: true,
            fillColor: _roseSoft,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _rose, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  // ─── STEP 3: FIRST PHOTO ───────────────────────────────────
  Widget _buildPhotoStep() {
    final photo = _photoPath;
    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickPhoto(ImageSource.gallery),
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _roseSoft,
              border: Border.all(color: _roseBorder, width: 3),
              image: photo == null
                  ? null
                  : DecorationImage(
                      image: FileImage(File(photo)),
                      fit: BoxFit.cover,
                    ),
            ),
            child: photo != null
                ? null
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo_rounded,
                        size: 40,
                        color: _rose,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add photo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _sourceTile(
                icon: Icons.photo_camera_rounded,
                label: 'Camera',
                onTap: () => _pickPhoto(ImageSource.camera),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _sourceTile(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: () => _pickPhoto(ImageSource.gallery),
              ),
            ),
          ],
        ),
        if (photo != null) ...[
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => setState(() => _photoPath = null),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Remove photo'),
            style: TextButton.styleFrom(foregroundColor: _inkMuted),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _p.inputFill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: _inkMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "We'll set up your baby's vaccination schedule and "
                  'milestones from the delivery date.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: _inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── BABY & BUTTONS ────────────────────────────────────────
  Widget _buildBaby() {
    final key = _narrationKey;
    final text = NarrationCatalog.textFor(key) ?? '';
    if (!BackgroundAudioController.isReady) {
      return BabyOnScreen(
        child: BabyLinePopup(text: text, speaking: false, onSpeakerTap: () {}),
      );
    }
    final audio = BackgroundAudioController.to;
    return BabyOnScreen(
      child: Obx(
        () => BabyLinePopup(
          text: text,
          speaking: audio.isSpeaking(key),
          onSpeakerTap: () => audio.replay(key),
        ),
      ),
    );
  }

  Widget _buildButtons(bool isLast) {
    final canGo = _canContinue && !_isSubmitting;
    return Row(
      children: [
        if (_step > 0) ...[
          SizedBox(
            height: 54,
            width: 54,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => _goTo(_step - 1),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: _roseBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: _rose),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: !canGo
                  ? null
                  : isLast
                  ? _submit
                  : () => _goTo(_step + 1),
              style: ElevatedButton.styleFrom(
                backgroundColor: _rose,
                disabledBackgroundColor: _roseBorder,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isLast
                          ? (_photoPath == null
                                ? 'Skip & Complete'
                                : 'Complete Journey')
                          : 'Next',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── SMALL PIECES ──────────────────────────────────────────
  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: _inkMuted,
      ),
    ),
  );

  Widget _optionCard({
    required String emoji,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? _roseSoft : _p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _rose : _roseBorder,
            width: selected ? 1.8 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: selected ? _rose : _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _roseSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _roseBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: _rose),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
