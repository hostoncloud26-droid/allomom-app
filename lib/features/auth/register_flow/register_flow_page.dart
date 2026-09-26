// ignore_for_file: unused_import, unused_local_variable
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/family_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_flow.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/baby/baby_form_sheet.dart';
import 'package:allomom/features/main_layout.dart';
import 'package:allomom/repositories/baby_repository.dart';
import 'package:allomom/repositories/pregnancy_state.dart';
import 'package:allomom/services/google_auth_service.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sync/sync_codec.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:allomom/features/auth/register_flow/register_name_page.dart';
import 'package:allomom/features/auth/register_flow/register_status_page.dart';
import 'package:allomom/features/auth/register_flow/register_lmp_timeline_page.dart';
import 'package:allomom/features/auth/register_flow/register_edd_due_date_page.dart';
import 'package:allomom/features/auth/register_flow/register_cycle_prediction_page.dart';
import 'package:allomom/features/auth/register_flow/register_partner_details_page.dart';
import 'package:allomom/features/auth/register_flow/family_details_page.dart';
import 'package:allomom/features/auth/register_flow/kids_details_page.dart';
import 'package:allomom/features/auth/register_flow/dad_family_setup_page.dart';
import 'package:allomom/features/auth/register_flow/join_family_code_page.dart';

enum RegisterStep {
  name,
  status,
  lmp,
  edd,
  cyclePrediction,
  partner,
  family,
  kids,
  dadSetup,
  joinCode,
}

class RegisterFlowPage extends StatefulWidget {
  final RegisterStep initialStep;
  final String userName;
  final String phone;
  final String countryCode;
  final String selectedLanguage;
  final String selectedRole;
  final String status;
  final DateTime? lmpDate;
  final DateTime? eddDate;
  final String? partnerName;
  final String? partnerPhone;
  final String? familyCode;
  final bool registerPregnancyForPartner;

  const RegisterFlowPage({
    super.key,
    this.initialStep = RegisterStep.name,
    this.userName = '',
    this.phone = '9876543210',
    this.countryCode = '+91',
    this.selectedLanguage = 'en',
    this.selectedRole = 'Mom',
    this.status = '',
    this.lmpDate,
    this.eddDate,
    this.partnerName,
    this.partnerPhone,
    this.familyCode,
    this.registerPregnancyForPartner = false,
  });

  @override
  State<RegisterFlowPage> createState() => _RegisterFlowPageState();
}

class _RegisterFlowPageState extends State<RegisterFlowPage> {
  final List<RegisterStep> _stepHistory = [];
  late RegisterStep _currentStep;
  bool _isForward = true;

  // Flow State
  late String _userName;
  late String _selectedRole;
  late String _status;
  DateTime? _lmpDate;
  DateTime? _eddDate;
  int _cycleLength = 28;
  String? _partnerName;
  String? _partnerPhone;
  String? _familyCode;
  late bool _registerPregnancyForPartner;

  // Step 0: Name State
  final TextEditingController _nameController = TextEditingController();
  String? _googleEmail;
  String? _googlePhotoUrl;

  // Step 2: LMP State
  late DateTime _selectedLmpDate;
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;

  // Step 5: Partner State
  final TextEditingController _partnerNameController = TextEditingController();
  final TextEditingController _partnerPhoneController = TextEditingController();

  // Step 6: Family Details State
  bool _hasKids = false;
  bool _isSavingFamily = false;
  bool _isSavingPartner = false;

  // Step 7: Kids State
  List<Baby> _children = const [];
  String? _deletingBabyId;

  // Step 8: Join Code State
  final TextEditingController _joinCodeController = TextEditingController();
  bool _isCheckingCode = false;
  bool _isJoiningCode = false;
  String? _codeErrorMessage;

  // Narration State
  String _narrationKey = NarrationKeys.onbNamePromptMom;

  bool get _isDad => _selectedRole.trim().toLowerCase() == 'dad';
  bool get _isPregnancyFlow {
    final s = _status.toLowerCase().trim();
    if (s.startsWith('pre ') || s.startsWith('pre-')) return false;
    if (s.contains('new')) return false;
    return s.contains('pregnan');
  }

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _stepHistory.add(_currentStep);

    _userName = widget.userName;
    _selectedRole = widget.selectedRole;
    _status = widget.status;
    _lmpDate = widget.lmpDate;
    _eddDate = widget.eddDate;
    _partnerName = widget.partnerName;
    _partnerPhone = widget.partnerPhone;
    _familyCode = widget.familyCode;
    _registerPregnancyForPartner = widget.registerPregnancyForPartner;

    _nameController.text = _userName;
    if (_partnerName != null) _partnerNameController.text = _partnerName!;
    if (_partnerPhone != null) _partnerPhoneController.text = _partnerPhone!;

    final now = _lmpDate ?? DateTime.now();
    _selectedLmpDate = DateTime(now.year, now.month, now.day);
    _dayController = FixedExtentScrollController(
      initialItem: _selectedLmpDate.day - 1,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _selectedLmpDate.month - 1,
    );

    _updateNarrationForStep(_currentStep);

    if (_currentStep == RegisterStep.name) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromGoogle());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _partnerNameController.dispose();
    _partnerPhoneController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  void _say(String key) {
    if (!mounted) return;
    setState(() => _narrationKey = key);
    if (BackgroundAudioController.isReady) {
      BackgroundAudioController.to.playByKey(key, force: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.isEmpty ? 'Something went wrong.' : message),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFFFF4E6A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateNarrationForStep(RegisterStep step) {
    switch (step) {
      case RegisterStep.name:
        _narrationKey = _isDad
            ? NarrationKeys.onbNamePromptDad
            : NarrationKeys.onbNamePromptMom;
        break;
      case RegisterStep.status:
        _narrationKey = NarrationKeys.onbStatus;
        break;
      case RegisterStep.lmp:
        _narrationKey = _isPregnancyFlow
            ? NarrationKeys.pregLmp
            : NarrationKeys.preCycle;
        break;
      case RegisterStep.edd:
        _narrationKey = NarrationKeys.pregEddBubble;
        break;
      case RegisterStep.cyclePrediction:
        _narrationKey = NarrationKeys.preCycleLength;
        break;
      case RegisterStep.partner:
        _narrationKey = _isDad
            ? NarrationKeys.pregPartnerDad
            : NarrationFlowKeys.of(_status).partner;
        break;
      case RegisterStep.family:
        _narrationKey = NarrationFlowKeys.of(_status).kids;
        break;
      case RegisterStep.kids:
        _narrationKey = NarrationFlowKeys.of(_status).kids;
        break;
      case RegisterStep.dadSetup:
        _narrationKey = NarrationKeys.onbNamePromptDad;
        break;
      case RegisterStep.joinCode:
        _narrationKey = NarrationKeys.onbNamePromptDad;
        break;
    }
  }

  void _goToStep(RegisterStep step) {
    if (_currentStep == step) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isForward = true;
      _currentStep = step;
      if (_stepHistory.isEmpty || _stepHistory.last != step) {
        _stepHistory.add(step);
      }
      _updateNarrationForStep(step);
    });
    if (BackgroundAudioController.isReady) {
      BackgroundAudioController.to.playByKey(_narrationKey, force: true);
    }
  }

  void _resetStepState(RegisterStep prevStep) {
    if (prevStep == RegisterStep.name || prevStep == RegisterStep.dadSetup) {
      _status = '';
      _lmpDate = null;
      _eddDate = null;
      _cycleLength = 28;
      _registerPregnancyForPartner = false;
      final now = DateTime.now();
      _selectedLmpDate = DateTime(now.year, now.month, now.day);
    } else if (prevStep == RegisterStep.status) {
      _lmpDate = null;
      _eddDate = null;
      _cycleLength = 28;
      final now = DateTime.now();
      _selectedLmpDate = DateTime(now.year, now.month, now.day);
    } else if (prevStep == RegisterStep.lmp ||
        prevStep == RegisterStep.cyclePrediction) {
      _cycleLength = 28;
    }
  }

  void _handleBackNavigation() {
    if (_stepHistory.length > 1) {
      _stepHistory.removeLast();
      while (_stepHistory.length > 1 && _stepHistory.last == _currentStep) {
        _stepHistory.removeLast();
      }
      final prevStep = _stepHistory.last;
      FocusScope.of(context).unfocus();
      setState(() {
        _isForward = false;
        _resetStepState(prevStep);
        _currentStep = prevStep;
        _updateNarrationForStep(prevStep);
      });
      if (BackgroundAudioController.isReady) {
        BackgroundAudioController.to.playByKey(_narrationKey, force: true);
      }
    } else if (Navigator.canPop(context)) {
      narratedPop(context);
    }
  }

  String get _currentStepTitle {
    switch (_currentStep) {
      case RegisterStep.name:
        return 'Enter Name';
      case RegisterStep.status:
        return 'Select Your Status';
      case RegisterStep.lmp:
        return 'Select LMP Date';
      case RegisterStep.edd:
        return 'Your Due Date';
      case RegisterStep.cyclePrediction:
        return 'Predicted Cycle';
      case RegisterStep.partner:
        return _isDad ? "Mommy's Details" : 'Partner Details';
      case RegisterStep.family:
        return 'Family Details';
      case RegisterStep.kids:
        return 'Children Details';
      case RegisterStep.dadSetup:
        return 'Family Setup';
      case RegisterStep.joinCode:
        return 'Join Family';
    }
  }

  String get _currentSpeechFallback {
    switch (_currentStep) {
      case RegisterStep.name:
        return 'You have such a lovely name! 💕';
      case RegisterStep.status:
        return 'Tell me where we are on this magical journey! ✨';
      case RegisterStep.lmp:
        return _isDad
            ? "When was the first day of Mommy's last\nmenstrual period? 🌸"
            : 'When was the first day of your last\nmenstrual period? 🌸';
      case RegisterStep.edd:
        return 'Yay! I can\'t wait to meet you on your due date! 👶🎉';
      case RegisterStep.cyclePrediction:
        return 'Here is your predicted cycle window! 🌸';
      case RegisterStep.partner:
        return _isDad
            ? 'Tell me a bit about Mommy so we can stay close! 💕'
            : 'Would you like to connect with your partner? 👫';
      case RegisterStep.family:
        return 'Do you have other lovely little ones in your family? 👶';
      case RegisterStep.kids:
        return 'Add your lovely children so I can care for all of them! 👶✨';
      case RegisterStep.dadSetup:
        return 'Welcome Daddy! How would you like to set up your family? 👨‍👩‍👦';
      case RegisterStep.joinCode:
        return 'Enter your family code to connect with Mommy! 🔑';
    }
  }

  // ─── STEP 0: NAME ACTIONS ───
  Future<void> _prefillFromGoogle() async {
    final GoogleSignInAccount? account;
    try {
      account = await GoogleAuthService.signIn();
    } catch (_) {
      return;
    }
    if (account == null || !mounted) return;

    final name = account.displayName?.trim() ?? '';
    final email = account.email.trim();
    final photoUrl = account.photoUrl;

    setState(() {
      if (name.isNotEmpty && _nameController.text.trim().isEmpty) {
        _nameController.text = name;
        _userName = name;
      }
      _googleEmail = email.isEmpty ? null : email;
      _googlePhotoUrl = photoUrl;
    });

    final changes = <String, dynamic>{
      if (_googleEmail != null) 'email': _googleEmail,
      if (_googlePhotoUrl != null) 'profile_picture': _googlePhotoUrl,
    };
    if (changes.isNotEmpty) {
      await MainController.instance.updateProfile(changes);
    }
  }

  void _handleNameNext() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _say(NarrationKeys.onbNameEmpty);
      _showMessage('Please enter your name');
      return;
    }
    _userName = name;
    speak(NarrationKeys.onbNameReaction, force: true);

    if (_isDad) {
      _goToStep(RegisterStep.dadSetup);
    } else {
      _goToStep(RegisterStep.status);
    }
  }

  // ─── STEP 1: STATUS ACTIONS ───
  void _handleStatusSelected(String st) {
    setState(() {
      _status = st;
      switch (st.trim().toLowerCase()) {
        case 'pre pregnancy':
          _narrationKey = NarrationKeys.onbStatusPrePregnancy;
          break;
        case 'new mom':
          _narrationKey = NarrationKeys.onbStatusNewMom;
          break;
        default:
          _narrationKey = NarrationKeys.onbStatusPregnant;
      }
    });
  }

  void _handleStatusNext() {
    if (_status.isEmpty) {
      _say(NarrationKeys.onbStatus);
      _showMessage('Please select an option to continue');
      return;
    }
    speak(NarrationKeys.onbAlmostDone);
    _goToStep(RegisterStep.lmp);
  }

  // ─── STEP 2: LMP ACTIONS ───
  int _getDaysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  DateTime _resolveDate(int month, int day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final daysInCurrentYear = _getDaysInMonth(today.year, month);
    final validDayCurrentYear = day.clamp(1, daysInCurrentYear);
    DateTime candidate = DateTime(today.year, month, validDayCurrentYear);

    if (candidate.isAfter(today)) {
      final daysInPastYear = _getDaysInMonth(today.year - 1, month);
      final validDayPastYear = day.clamp(1, daysInPastYear);
      candidate = DateTime(today.year - 1, month, validDayPastYear);
    }
    return candidate;
  }

  void _onLmpDayChanged(int dayIndex) {
    HapticFeedback.selectionClick();
    final targetDay = dayIndex + 1;
    setState(() {
      _selectedLmpDate = _resolveDate(_selectedLmpDate.month, targetDay);
    });
  }

  void _onLmpMonthChanged(int monthIndex) {
    HapticFeedback.selectionClick();
    final targetMonth = monthIndex + 1;
    setState(() {
      _selectedLmpDate = _resolveDate(targetMonth, _selectedLmpDate.day);
    });
    final maxDays = _getDaysInMonth(_selectedLmpDate.year, targetMonth);
    if (_dayController.hasClients && _dayController.selectedItem >= maxDays) {
      _dayController.jumpToItem(maxDays - 1);
    }
  }

  void _handleLmpCalculate() {
    final lmp = _selectedLmpDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lmp.isAfter(today)) {
      _say(NarrationKeys.pregLmpFutureError);
      _showMessage(
        'Future dates cannot be selected. Please choose a past date.',
        isError: true,
      );
      return;
    }

    final isPreg = _isPregnancyFlow;
    final minDate = isPreg
        ? today.subtract(const Duration(days: 42 * 7))
        : DateTime(today.year - 1, today.month, today.day);

    if (lmp.isBefore(minDate)) {
      _say(NarrationKeys.pregLmpFutureError);
      _showMessage(
        isPreg
            ? 'LMP date must be within the last 42 weeks.'
            : 'LMP date must be within the last 12 months.',
        isError: true,
      );
      return;
    }

    _lmpDate = lmp;
    _eddDate = lmp.add(const Duration(days: 280));

    speak(
      _isPregnancyFlow
          ? NarrationKeys.pregLmpConfirm
          : NarrationKeys.preCycleSaved,
      force: true,
    );

    if (_isPregnancyFlow) {
      _goToStep(RegisterStep.edd);
    } else {
      _goToStep(RegisterStep.cyclePrediction);
    }
  }

  // ─── STEP 3: EDD / CYCLE ACTIONS ───
  void _handleEddConfirm() {
    speak(NarrationKeys.pregEddSaved, force: true);
    if (_isDad) {
      _goToStep(RegisterStep.family);
    } else {
      _goToStep(RegisterStep.partner);
    }
  }

  void _handleCycleConfirm() {
    speak(NarrationKeys.preCycleSaved, force: true);
    _goToStep(RegisterStep.partner);
  }

  // ─── STEP 4: PARTNER ACTIONS ───
  /// Links the partner on the server — creating the household if there is
  /// none yet — so they show up on the family screen and on her other
  /// devices. Going back and saving again edits the same link.
  Future<void> _handlePartnerSave() async {
    final pName = _partnerNameController.text.trim();
    final pPhone = _partnerPhoneController.text.trim();
    if (pName.isEmpty) {
      _showMessage(
        "Please enter ${_isDad ? "Mommy's" : "Partner's"} name",
        isError: true,
      );
      return;
    }
    if (pPhone.length != 10) {
      _showMessage(
        'Please enter a valid 10-digit mobile number',
        isError: true,
      );
      return;
    }

    setState(() => _isSavingPartner = true);
    final family = FamilyController.instance;
    await family.loadFromLocal();
    final error = family.hasPartner
        ? await family.updatePartner(name: pName, phone: pPhone)
        : await family.linkPartner(
            name: pName,
            phone: pPhone,
            role: _isDad ? 'Dad' : 'Mom',
            familyName: _familyNameForPartner,
          );
    if (!mounted) return;
    setState(() => _isSavingPartner = false);

    if (error != null) {
      _showMessage(error, isError: true);
      return;
    }

    _partnerName = pName;
    _partnerPhone = pPhone;
    speak(NarrationKeys.pregPartnerSaved, force: true);
    _goToAfterPartner();
  }

  /// The household's name while the user's own name is not saved yet — the
  /// profile is only written at the end of registration.
  String get _familyNameForPartner {
    final me = _nameController.text.trim();
    return me.isEmpty ? 'My Family' : "$me's Family";
  }

  void _handlePartnerSkip() => _goToAfterPartner();

  /// A new mom has a baby by definition, so she skips the "any kids?"
  /// question and goes straight to adding them.
  void _goToAfterPartner() {
    if (isNewMomRegistrationLabel(_status)) {
      _goToStep(RegisterStep.kids);
      unawaited(_loadChildren());
    } else {
      _goToStep(RegisterStep.family);
    }
  }

  // ─── STEP 5: FAMILY ACTIONS ───
  Future<void> _handleFamilyNext() async {
    if (_hasKids) {
      _goToStep(RegisterStep.kids);
      unawaited(_loadChildren());
    } else {
      await _completeRegistration();
    }
  }

  Future<void> _loadChildren() async {
    final babies = await BabyRepository.instance.getBabies();
    if (!mounted) return;
    setState(() => _children = babies);
    unawaited(MainController.instance.ensureHealthRecord());
  }

  Future<void> _handleChildAdded(String babyId) => _loadChildren();

  Future<void> _handleDeleteChild(Baby baby) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove ${baby.name}?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove ${baby.name}?',
          style: GoogleFonts.poppins(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: const Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF4E6A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _deletingBabyId = baby.id);
      try {
        await BabyRepository.instance.deleteBaby(baby.id);
      } finally {
        if (mounted) {
          _deletingBabyId = null;
          await _loadChildren();
        }
      }
    }
  }

  Future<void> _completeRegistration() async {
    if (isNewMomRegistrationLabel(_status) && _children.isEmpty) {
      _showMessage('Please add at least one child to continue', isError: true);
      return;
    }
    setState(() => _isSavingFamily = true);
    try {
      final isDadRole = _isDad;
      final main = MainController.instance;

      await main.saveRegistration(
        name: _userName,
        gender: isDadRole ? 'male' : 'female',
        markRegistered: false,
      );

      final isPregnant =
          pregnancyStatusForRegistration(
            _status,
            isDad: isDadRole,
            registeringForPartner: _registerPregnancyForPartner,
          ) ==
          pregnantStatus;

      if (isPregnant && _lmpDate != null) {
        await PregnancyController.instance.createPregnancy(
          lmpDate: _lmpDate!,
          eddDate: _eddDate,
        );
      } else if (_lmpDate != null) {
        await main.updateHealthData({'lmp_date': SyncCodec.isoUtc(_lmpDate!)});
      }

      await main.completeRegistration();

      if (!mounted) return;
      speak(NarrationFlowKeys.of(_status).setupDone, force: true);
      _showMessage('Welcome, $_userName! Your family profile is ready.');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingFamily = false);
      _showMessage('Setup error: $e', isError: true);
    }
  }

  // ─── STEP 7: DAD SETUP ACTIONS ───
  void _handleDadJoinByCode() {
    _goToStep(RegisterStep.joinCode);
  }

  void _handleDadRegisterPregnancy() {
    _registerPregnancyForPartner = true;
    _status = 'pregnant';
    _goToStep(RegisterStep.lmp);
  }

  void _handleDadContinue() {
    _goToStep(RegisterStep.family);
  }

  // ─── STEP 8: JOIN CODE ACTIONS ───
  Future<void> _handleJoinFamilyCode() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.length < 6) {
      _showMessage('Please enter a 6-character family code', isError: true);
      return;
    }
    setState(() {
      _isJoiningCode = true;
      _codeErrorMessage = null;
    });

    final error = await FamilyController.instance.joinByCode(
      code,
      role: _selectedRole,
    );
    if (!mounted) return;
    setState(() => _isJoiningCode = false);

    if (error != null) {
      setState(() => _codeErrorMessage = error);
      _showMessage(error, isError: true);
      return;
    }

    _familyCode = code;
    _showMessage('Successfully connected to family!');
    _goToStep(RegisterStep.family);
  }

  double _getStepHeight(RegisterStep step, bool isKeyboardOpen) {
    if (isKeyboardOpen) {
      return 235;
    }
    return 310;
  }

  Widget _buildCurrentStepView(bool isKeyboardOpen) {
    switch (_currentStep) {
      case RegisterStep.name:
        return RegisterNameStepView(
          nameController: _nameController,
          googleEmail: _googleEmail,
          googlePhotoUrl: _googlePhotoUrl,
          onNext: _handleNameNext,
          isKeyboardOpen: isKeyboardOpen,
        );
      case RegisterStep.status:
        return RegisterStatusStepView(
          selectedStatus: _status,
          onStatusSelected: _handleStatusSelected,
          onNext: _handleStatusNext,
        );
      case RegisterStep.lmp:
        return RegisterLmpStepView(
          selectedDate: _selectedLmpDate,
          onDateChanged: (d) => setState(() => _selectedLmpDate = d),
          onCalculate: _handleLmpCalculate,
          isPregnancyFlow: _isPregnancyFlow,
          status: _status,
        );
      case RegisterStep.edd:
        return RegisterEddStepView(
          eddDate: _eddDate ?? DateTime.now().add(const Duration(days: 280)),
          narrationKey: _narrationKey,
          onHintSelected: _say,
          onConfirm: _handleEddConfirm,
        );
      case RegisterStep.cyclePrediction:
        return RegisterCyclePredictionStepView(
          lmpDate: _lmpDate ?? DateTime.now(),
          cycleLength: _cycleLength,
          narrationKey: _narrationKey,
          onHintSelected: _say,
          onCycleLengthChanged: (len) => setState(() => _cycleLength = len),
          onNext: _handleCycleConfirm,
        );
      case RegisterStep.partner:
        return RegisterPartnerStepView(
          partnerNameController: _partnerNameController,
          partnerPhoneController: _partnerPhoneController,
          partnerWord: _isDad ? 'Mommy' : 'Daddy',
          isDad: _isDad,
          onSave: _handlePartnerSave,
          onSkip: _handlePartnerSkip,
          isSaving: _isSavingPartner,
          isKeyboardOpen: isKeyboardOpen,
        );
      case RegisterStep.family:
        return FamilyDetailsStepView(
          hasKids: _hasKids,
          onHasKidsChanged: (val) => setState(() => _hasKids = val),
          isLoading: _isSavingFamily,
          onNext: _handleFamilyNext,
        );
      case RegisterStep.kids:
        return KidsDetailsStepView(
          children: _children,
          onChildAdded: _handleChildAdded,
          onNarrate: _say,
          onAddCancelled: () => _say(NarrationFlowKeys.of(_status).kids),
          onDeleteChild: _handleDeleteChild,
          deletingChildId: _deletingBabyId,
          isLoading: _isSavingFamily,
          isNewMom: isNewMomRegistrationLabel(_status),
          onComplete: _completeRegistration,
        );
      case RegisterStep.dadSetup:
        return DadFamilySetupStepView(
          onJoinByCode: _handleDadJoinByCode,
          onRegisterPregnancy: _handleDadRegisterPregnancy,
          onContinue: _handleDadContinue,
          partnerWord: 'Mommy',
        );
      case RegisterStep.joinCode:
        return JoinFamilyCodeStepView(
          codeController: _joinCodeController,
          isChecking: _isCheckingCode,
          isJoining: _isJoiningCode,
          errorMessage: _codeErrorMessage,
          onJoin: _handleJoinFamilyCode,
          onCancel: _handleBackNavigation,
          isKeyboardOpen: isKeyboardOpen,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return PopScope(
      canPop: _stepHistory.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F7),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    children: [
                      // ═══════════════════════════════════════════════════════
                      // ─── SECTION 1: TOP APP BAR & ANIMATED BABY BANNER ───
                      // ═══════════════════════════════════════════════════════
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _handleBackNavigation,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: Color(0xFF1E2024),
                                  size: 24,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _currentStepTitle,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E2024),
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                      SizedBox(height: isKeyboardOpen ? 4 : 12),

                      // Animated Baby Avatar Section
                      Expanded(
                        child: BabyPrompt(
                          compact: isKeyboardOpen,
                          expand: true,
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          narrationKey: _narrationKey,
                          text: _currentSpeechFallback,
                        ),
                      ),

                      // ═══════════════════════════════════════════════════════
                      // ─── SECTION 2: BOTTOM CONTAINER WITH SLIDE TRANSITION ─
                      // ═══════════════════════════════════════════════════════
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          20,
                          isKeyboardOpen ? 16 : 24,
                          20,
                          (isKeyboardOpen ? 16 : 24) +
                              MediaQuery.paddingOf(context).bottom,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, -4),
                            ),
                          ],
                        ),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          alignment: Alignment.topCenter,
                          child: SizedBox(
                            height: _getStepHeight(
                              _currentStep,
                              isKeyboardOpen,
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 320),
                              switchInCurve: Curves.easeInOutCubic,
                              switchOutCurve: Curves.easeInOutCubic,
                              transitionBuilder: (child, animation) {
                                final bool isIncoming =
                                    child.key == ValueKey(_currentStep);
                                final inTween = Tween<Offset>(
                                  begin: _isForward
                                      ? const Offset(1.0, 0.0)
                                      : const Offset(-1.0, 0.0),
                                  end: Offset.zero,
                                );
                                final outTween = Tween<Offset>(
                                  begin: _isForward
                                      ? const Offset(-1.0, 0.0)
                                      : const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                );

                                return SlideTransition(
                                  position: (isIncoming ? inTween : outTween)
                                      .animate(animation),
                                  child: child,
                                );
                              },
                              layoutBuilder: (currentChild, previousChildren) {
                                return Stack(
                                  alignment: Alignment.topCenter,
                                  children: <Widget>[
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                );
                              },
                              child: KeyedSubtree(
                                key: ValueKey(_currentStep),
                                child: _buildCurrentStepView(isKeyboardOpen),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
