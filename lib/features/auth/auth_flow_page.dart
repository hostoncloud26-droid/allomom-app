// ignore_for_file: unused_import, unused_local_variable
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/auth_controller.dart';
import 'package:allomom/controllers/connection_controller.dart';
import 'package:allomom/controllers/family_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/controllers/theme_controller.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_flow.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/baby/baby_form_sheet.dart';
import 'package:allomom/features/main_layout.dart';
import 'package:allomom/repositories/baby_repository.dart';
import 'package:allomom/repositories/pregnancy_state.dart';
import 'package:allomom/services/app_language.dart';
import 'package:allomom/services/google_auth_service.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sync/sync_codec.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:allomom/features/auth/language_selection_page.dart';
import 'package:allomom/features/auth/contact_number_page.dart';
import 'package:allomom/features/auth/verify_otp_page.dart';
import 'package:allomom/features/auth/role_selection_page.dart';
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

enum AuthFlowStep {
  language,
  contact,
  verifyOtp,
  role,
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

class AuthFlowPage extends StatefulWidget {
  final AuthFlowStep initialStep;
  final String initialLanguage;
  final String initialPhone;
  final String initialCountryCode;
  final String initialRole;
  final String initialName;

  const AuthFlowPage({
    super.key,
    this.initialStep = AuthFlowStep.language,
    this.initialLanguage = 'en',
    this.initialPhone = '',
    this.initialCountryCode = '+91',
    this.initialRole = 'Mom',
    this.initialName = '',
  });

  @override
  State<AuthFlowPage> createState() => _AuthFlowPageState();
}

class _AuthFlowPageState extends State<AuthFlowPage> {
  late final PageController _pageController;
  final List<AuthFlowStep> _stepHistory = [];
  late AuthFlowStep _currentStep;

  // Language state
  String _selectedLanguageCode = 'en';

  // Contact number state
  final TextEditingController _phoneController = TextEditingController();
  final String _countryCode = '+91';
  bool _isLoading = false;

  // OTP state
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _focusedOtpIndex = 0;
  bool _isVerifying = false;
  bool _isResending = false;

  // Role state
  String _selectedRole = 'Mom';

  // Name state
  final TextEditingController _nameController = TextEditingController();
  String? _googleEmail;
  String? _googlePhotoUrl;

  // Status & Medical state
  String _status = '';
  DateTime? _lmpDate;
  DateTime? _eddDate;
  final int _cycleLength = 28;

  // LMP Wheel controllers
  late DateTime _selectedLmpDate;
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;

  // Partner state
  final TextEditingController _partnerNameController = TextEditingController();
  final TextEditingController _partnerPhoneController = TextEditingController();
  String? _partnerName;
  String? _partnerPhone;

  // Family & Kids state
  bool _hasKids = false;
  bool _isSavingRegistration = false;
  List<Baby> _children = const [];

  // Dad Setup state
  bool _registerPregnancyForPartner = false;
  final TextEditingController _joinCodeController = TextEditingController();
  bool _isCheckingCode = false;
  bool _isJoiningCode = false;
  String? _codeErrorMessage;

  // Narration & Speech state
  String _narrationKey = NarrationKeys.onbLang;

  bool get _isDad => _selectedRole.trim().toLowerCase() == 'dad';
  bool get _isPregnancyFlow {
    final s = _status.toLowerCase().trim();
    if (s.startsWith('pre ') || s.startsWith('pre-')) return false;
    if (s.contains('new')) return false;
    return s.contains('pregnan');
  }

  final List<String> _testNumbers = const [
    '9999999999',
    '8888888888',
    '7639744744',
    '1111122222',
    '9363286517',
    '9876543210',
    '1234567890',
  ];

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _stepHistory.add(_currentStep);
    _pageController = PageController(initialPage: _currentStep.index);

    _selectedLanguageCode = widget.initialLanguage;
    _selectedRole = widget.initialRole;
    if (widget.initialPhone.isNotEmpty) {
      _phoneController.text = widget.initialPhone;
    }
    if (widget.initialName.isNotEmpty) {
      _nameController.text = widget.initialName;
    }

    final now = DateTime.now();
    _selectedLmpDate = DateTime(now.year, now.month, now.day);
    _dayController = FixedExtentScrollController(initialItem: _selectedLmpDate.day - 1);
    _monthController = FixedExtentScrollController(initialItem: _selectedLmpDate.month - 1);

    _updateNarrationForStep(_currentStep);

    for (int i = 0; i < 6; i++) {
      _otpFocusNodes[i].addListener(() {
        if (_otpFocusNodes[i].hasFocus) {
          setState(() {
            _focusedOtpIndex = i;
          });
        }
      });
    }

    if (_currentStep == AuthFlowStep.name) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromGoogle());
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _dayController.dispose();
    _monthController.dispose();
    _partnerNameController.dispose();
    _partnerPhoneController.dispose();
    _joinCodeController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
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
        content: Text(
          message.isEmpty ? 'Something went wrong. Please try again.' : message,
        ),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFFFF4E6A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateNarrationForStep(AuthFlowStep step) {
    switch (step) {
      case AuthFlowStep.language:
        _narrationKey = NarrationKeys.onbLang;
        break;
      case AuthFlowStep.contact:
        _narrationKey = NarrationKeys.onbMobile;
        break;
      case AuthFlowStep.verifyOtp:
        _narrationKey = NarrationKeys.onbOtp;
        break;
      case AuthFlowStep.role:
        _narrationKey = _selectedRole.toLowerCase() == 'dad'
            ? NarrationKeys.onbRoleDad
            : NarrationKeys.onbRoleMom;
        break;
      case AuthFlowStep.name:
        _narrationKey = _isDad
            ? NarrationKeys.onbNamePromptDad
            : NarrationKeys.onbNamePromptMom;
        break;
      case AuthFlowStep.status:
        _narrationKey = NarrationKeys.onbStatus;
        break;
      case AuthFlowStep.lmp:
        _narrationKey = _isPregnancyFlow
            ? NarrationKeys.pregLmp
            : NarrationKeys.preCycle;
        break;
      case AuthFlowStep.edd:
        _narrationKey = NarrationKeys.pregEddBubble;
        break;
      case AuthFlowStep.cyclePrediction:
        _narrationKey = NarrationKeys.preCycleLength;
        break;
      case AuthFlowStep.partner:
        _narrationKey = _isDad
            ? NarrationKeys.pregPartnerDad
            : NarrationFlowKeys.of(_status).partner;
        break;
      case AuthFlowStep.family:
        _narrationKey = NarrationFlowKeys.of(_status).kids;
        break;
      case AuthFlowStep.kids:
        _narrationKey = NarrationFlowKeys.of(_status).kids;
        break;
      case AuthFlowStep.dadSetup:
        _narrationKey = NarrationKeys.onbNamePromptDad;
        break;
      case AuthFlowStep.joinCode:
        _narrationKey = NarrationKeys.onbNamePromptDad;
        break;
    }
  }

  void _goToStep(AuthFlowStep step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _currentStep = step;
      _stepHistory.add(step);
      _updateNarrationForStep(step);
    });
    _pageController.animateToPage(
      step.index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    if (BackgroundAudioController.isReady) {
      BackgroundAudioController.to.playByKey(_narrationKey, force: true);
    }
  }

  void _handleBackNavigation() {
    if (_stepHistory.length > 1) {
      _stepHistory.removeLast();
      final prevStep = _stepHistory.last;
      FocusScope.of(context).unfocus();
      setState(() {
        _currentStep = prevStep;
        _updateNarrationForStep(prevStep);
      });
      _pageController.animateToPage(
        prevStep.index,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      if (BackgroundAudioController.isReady) {
        BackgroundAudioController.to.playByKey(_narrationKey, force: true);
      }
    } else if (Navigator.canPop(context)) {
      narratedPop(context);
    }
  }

  String get _currentStepTitle {
    switch (_currentStep) {
      case AuthFlowStep.language:
        return 'Please Select Your Language';
      case AuthFlowStep.contact:
        return 'Set Your Contact Number';
      case AuthFlowStep.verifyOtp:
        return 'Verify Your Number';
      case AuthFlowStep.role:
        return 'Select Your Role';
      case AuthFlowStep.name:
        return 'Enter Name';
      case AuthFlowStep.status:
        return 'Select Your Status';
      case AuthFlowStep.lmp:
        return 'Select LMP Date';
      case AuthFlowStep.edd:
        return 'Your Due Date';
      case AuthFlowStep.cyclePrediction:
        return 'Predicted Cycle';
      case AuthFlowStep.partner:
        return _isDad ? "Mommy's Details" : 'Partner Details';
      case AuthFlowStep.family:
        return 'Family Details';
      case AuthFlowStep.kids:
        return 'Children Details';
      case AuthFlowStep.dadSetup:
        return 'Family Setup';
      case AuthFlowStep.joinCode:
        return 'Join Family';
    }
  }

  String get _currentSpeechFallback {
    switch (_currentStep) {
      case AuthFlowStep.language:
        return 'Hello there! Which language should\nwe speak together? 💬';
      case AuthFlowStep.contact:
        return "What's your mobile number\nso I can stay close? 📱";
      case AuthFlowStep.verifyOtp:
        return 'I just sent a secret 6-digit code to\nyour phone! 🔑';
      case AuthFlowStep.role:
        return 'Yay! Are you my Mommy or my\nDaddy? 👶✨';
      case AuthFlowStep.name:
        return 'You have such a lovely name! 💕';
      case AuthFlowStep.status:
        return 'Tell me where we are on this magical journey! ✨';
      case AuthFlowStep.lmp:
        return _isDad
            ? "When was the first day of Mommy's last\nmenstrual period? 🌸"
            : 'When was the first day of your last\nmenstrual period? 🌸';
      case AuthFlowStep.edd:
        return 'Yay! I can\'t wait to meet you on your due date! 👶🎉';
      case AuthFlowStep.cyclePrediction:
        return 'Here is your predicted cycle window! 🌸';
      case AuthFlowStep.partner:
        return _isDad
            ? 'Tell me a bit about Mommy so we can stay close! 💕'
            : 'Would you like to connect with your partner? 👫';
      case AuthFlowStep.family:
        return 'Do you have other lovely little ones in your family? 👶';
      case AuthFlowStep.kids:
        return 'Add your lovely children so I can care for all of them! 👶✨';
      case AuthFlowStep.dadSetup:
        return 'Welcome Daddy! How would you like to set up your family? 👨‍👩‍👦';
      case AuthFlowStep.joinCode:
        return 'Enter your family code to connect with Mommy! 🔑';
    }
  }

  // ─── STEP 0: LANGUAGE ACTIONS ───
  void _handleLanguageSelected(String code) {
    setState(() {
      _selectedLanguageCode = code;
      _narrationKey = code == 'other'
          ? NarrationKeys.onbLangOther
          : NarrationKeys.onbLang;
    });
  }

  Future<void> _handleLanguageProceed() async {
    await AppLanguage.save(_selectedLanguageCode);
    if (BackgroundAudioController.isReady) {
      await BackgroundAudioController.to.setLanguage(_selectedLanguageCode);
    }
    _goToStep(AuthFlowStep.contact);
  }

  // ─── STEP 1: CONTACT NUMBER ACTIONS ───
  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text
        .trim()
        .replaceAll(' ', '')
        .replaceAll('-', '');
    if (phone.length < 10) {
      _say(NarrationKeys.onbMobileInvalid);
      _showMessage('Please enter a valid 10-digit mobile number');
      return;
    }

    if (!ConnectionController.instance.isInternetAvailable) {
      _say(NarrationKeys.onbMobileInternet);
      _showMessage(
        'This step needs the internet. Please check your connection.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final error = await AuthController.instance.sendOtp(
      phone,
      countryCode: _countryCode,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      _say(
        ConnectionController.instance.isInternetAvailable
            ? NarrationKeys.onbMobileInvalid
            : NarrationKeys.onbMobileInternet,
      );
      _showMessage(error, isError: true);
      return;
    }

    final isTest = _testNumbers.contains(phone);
    _showMessage(
      isTest
          ? 'OTP sent to $_countryCode $phone (test code: 999777)'
          : 'OTP sent to $_countryCode $phone',
    );

    _goToStep(AuthFlowStep.verifyOtp);
  }

  void _handleGoogleSignIn() {
    _say(NarrationKeys.onbMobileGoogle);
    _showMessage(
      'Google sign-in is not available yet. Please continue with your mobile number.',
    );
  }

  // ─── STEP 2: OTP ACTIONS ───
  String get _enteredOtp => _otpControllers.map((c) => c.text.trim()).join();

  Future<void> _handleVerifyOtp() async {
    final otpCode = _enteredOtp;
    if (otpCode.length < 6) {
      _say(NarrationKeys.onbOtpWrong);
      _showMessage('Please enter the full 6-digit code');
      return;
    }

    setState(() => _isVerifying = true);

    final phone = _phoneController.text
        .trim()
        .replaceAll(' ', '')
        .replaceAll('-', '');

    final outcome = await AuthController.instance.verifyOtp(
      phone: phone,
      otp: otpCode,
      countryCode: _countryCode,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (!outcome.success) {
      _say(NarrationKeys.onbOtpWrong);
      _showMessage(outcome.message, isError: true);
      return;
    }

    speak(NarrationKeys.onbOtpSuccess, force: true);

    if (outcome.isRegistered) {
      final name = MainController.instance.userName.trim();
      _showMessage('Welcome back${name.isEmpty ? '' : ', $name'}!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
      return;
    }

    _showMessage("Verified! Let's set up your profile.");
    _goToStep(AuthFlowStep.role);
  }

  Future<void> _handleResendOtp() async {
    setState(() => _isResending = true);

    final phone = _phoneController.text
        .trim()
        .replaceAll(' ', '')
        .replaceAll('-', '');

    final error = await AuthController.instance.resendOtp(
      phone,
      countryCode: _countryCode,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (error != null) {
      _showMessage(error, isError: true);
      return;
    }

    _say(NarrationKeys.onbOtpResend);

    for (final controller in _otpControllers) {
      controller.clear();
    }
    _otpFocusNodes.first.requestFocus();
    _showMessage('A new code is on its way.');
  }

  // ─── STEP 3: ROLE ACTIONS ───
  void _handleRoleSelected(String role) {
    setState(() {
      _selectedRole = role;
      _narrationKey = role.trim().toLowerCase() == 'dad'
          ? NarrationKeys.onbRoleDad
          : NarrationKeys.onbRoleMom;
    });
  }

  void _handleRoleProceed() {
    _prefillFromGoogle();
    _goToStep(AuthFlowStep.name);
  }

  // ─── STEP 4: NAME ACTIONS ───
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
    speak(NarrationKeys.onbNameReaction, force: true);

    if (_isDad) {
      _goToStep(AuthFlowStep.dadSetup);
    } else {
      _goToStep(AuthFlowStep.status);
    }
  }

  // ─── STEP 5: STATUS ACTIONS ───
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
    _goToStep(AuthFlowStep.lmp);
  }

  // ─── STEP 6: LMP ACTIONS ───
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
      _showMessage('Future dates cannot be selected. Please choose a past date.', isError: true);
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

    speak(_isPregnancyFlow ? NarrationKeys.pregLmpConfirm : NarrationKeys.preCycleSaved, force: true);

    if (_isPregnancyFlow) {
      _goToStep(AuthFlowStep.edd);
    } else {
      _goToStep(AuthFlowStep.cyclePrediction);
    }
  }

  // ─── STEP 7: EDD / CYCLE ACTIONS ───
  void _handleEddConfirm() {
    speak(NarrationKeys.pregEddSaved, force: true);
    if (_isDad) {
      _goToStep(AuthFlowStep.family);
    } else {
      _goToStep(AuthFlowStep.partner);
    }
  }

  void _handleCycleConfirm() {
    speak(NarrationKeys.preCycleSaved, force: true);
    if (isNewMomRegistrationLabel(_status)) {
      _loadChildren();
      _goToStep(AuthFlowStep.kids);
    } else {
      _goToStep(AuthFlowStep.partner);
    }
  }

  // ─── STEP 8: PARTNER ACTIONS ───
  void _handlePartnerSave() {
    final pName = _partnerNameController.text.trim();
    final pPhone = _partnerPhoneController.text.trim();
    if (pName.isNotEmpty) _partnerName = pName;
    if (pPhone.isNotEmpty) _partnerPhone = pPhone;
    _goToStep(AuthFlowStep.family);
  }

  void _handlePartnerSkip() {
    _goToStep(AuthFlowStep.family);
  }

  // ─── STEP 9: FAMILY ACTIONS ───
  Future<void> _handleFamilyNext() async {
    if (_hasKids) {
      await _loadChildren();
      _goToStep(AuthFlowStep.kids);
    } else {
      await _completeRegistration();
    }
  }

  Future<void> _loadChildren() async {
    await MainController.instance.ensureHealthRecord();
    final babies = await BabyRepository.instance.getBabies();
    if (!mounted) return;
    setState(() => _children = babies);
  }

  Future<void> _openAddChildSheet() async {
    final babyId = await showBabyFormSheet(context);
    if (babyId != null && mounted) {
      await _loadChildren();
    }
  }

  Future<void> _completeRegistration() async {
    setState(() => _isSavingRegistration = true);
    try {
      final isDadRole = _isDad;
      final main = MainController.instance;

      await main.saveRegistration(
        name: _nameController.text.trim(),
        gender: isDadRole ? 'male' : 'female',
        markRegistered: false,
      );

      final isPregnant = pregnancyStatusForRegistration(
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
        await main.updateHealthData({
          'lmp_date': SyncCodec.isoUtc(_lmpDate!),
        });
      }

      await main.completeRegistration();

      if (!mounted) return;
      speak(NarrationFlowKeys.of(_status).setupDone, force: true);
      _showMessage('Welcome, ${_nameController.text.trim()}! Your family profile is ready.');

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingRegistration = false);
      _showMessage('Setup error: $e', isError: true);
    }
  }

  // ─── STEP 10: DAD SETUP ACTIONS ───
  void _handleDadJoinByCode() {
    _goToStep(AuthFlowStep.joinCode);
  }

  void _handleDadRegisterPregnancy() {
    _registerPregnancyForPartner = true;
    _status = 'pregnant';
    _goToStep(AuthFlowStep.lmp);
  }

  void _handleDadContinue() {
    _goToStep(AuthFlowStep.family);
  }

  // ─── STEP 11: JOIN CODE ACTIONS ───
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

    final error = await FamilyController.instance.joinByCode(code, role: _selectedRole);
    if (!mounted) return;
    setState(() => _isJoiningCode = false);

    if (error != null) {
      setState(() => _codeErrorMessage = error);
      _showMessage(error, isError: true);
      return;
    }

    _showMessage('Successfully connected to family!');
    _goToStep(AuthFlowStep.family);
  }

  double _getStepHeight(AuthFlowStep step, bool isKeyboardOpen) {
    if (isKeyboardOpen) {
      return 235;
    }
    return 310;
  }

  /// Sign-in and registration are drawn for the light theme only — the page
  /// itself paints a light background — so the flow is pinned to it. Left to
  /// follow a dark app theme, the baby card turned dark on a light page and
  /// the status bar icons went white on white.
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: ThemeController.overlayFor(Brightness.light),
        child: Builder(builder: _buildFlow),
      ),
    );
  }

  Widget _buildFlow(BuildContext context) {
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
                            if (_stepHistory.length > 1 || Navigator.canPop(context))
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
                              )
                            else
                              const SizedBox(width: 40),
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

                      // Animated Baby Avatar Section (Stays static in tree, speaks on step change)
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
                      // ─── SECTION 2: BOTTOM CONTAINER WITH PAGEVIEW ───────
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
                            height: _getStepHeight(_currentStep, isKeyboardOpen),
                            child: PageView.builder(
                              controller: _pageController,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: AuthFlowStep.values.length,
                              itemBuilder: (context, index) {
                                final step = AuthFlowStep.values[index];
                                switch (step) {
                                  case AuthFlowStep.language:
                                    return LanguageStepView(
                                      selectedLanguageCode: _selectedLanguageCode,
                                      onLanguageSelected: _handleLanguageSelected,
                                      onProceed: _handleLanguageProceed,
                                    );
                                  case AuthFlowStep.contact:
                                    return ContactNumberStepView(
                                      phoneController: _phoneController,
                                      countryCode: _countryCode,
                                      isLoading: _isLoading,
                                      onSendOtp: _handleSendOtp,
                                      onGoogleSignIn: _handleGoogleSignIn,
                                      isKeyboardOpen: isKeyboardOpen,
                                    );
                                  case AuthFlowStep.verifyOtp:
                                    return VerifyOtpStepView(
                                      phone: _phoneController.text.trim(),
                                      countryCode: _countryCode,
                                      otpControllers: _otpControllers,
                                      otpFocusNodes: _otpFocusNodes,
                                      focusedIndex: _focusedOtpIndex,
                                      isVerifying: _isVerifying,
                                      isResending: _isResending,
                                      onVerifyOtp: _handleVerifyOtp,
                                      onResendOtp: _handleResendOtp,
                                      onWhereCodeTapped: () =>
                                          _say(NarrationKeys.onbOtpWhere),
                                      isKeyboardOpen: isKeyboardOpen,
                                    );
                                  case AuthFlowStep.role:
                                    return RoleSelectionStepView(
                                      selectedRole: _selectedRole,
                                      onRoleSelected: _handleRoleSelected,
                                      onProceed: _handleRoleProceed,
                                    );
                                  case AuthFlowStep.name:
                                    return RegisterNameStepView(
                                      nameController: _nameController,
                                      googleEmail: _googleEmail,
                                      googlePhotoUrl: _googlePhotoUrl,
                                      onNext: _handleNameNext,
                                      isKeyboardOpen: isKeyboardOpen,
                                    );
                                  case AuthFlowStep.status:
                                    return RegisterStatusStepView(
                                      selectedStatus: _status,
                                      onStatusSelected: _handleStatusSelected,
                                      onNext: _handleStatusNext,
                                    );
                                  case AuthFlowStep.lmp:
                                    return RegisterLmpStepView(
                                      selectedDate: _selectedLmpDate,
                                      onDateChanged: (d) => setState(() => _selectedLmpDate = d),
                                      onCalculate: _handleLmpCalculate,
                                      isPregnancyFlow: _isPregnancyFlow,
                                      status: _status,
                                    );
                                  case AuthFlowStep.edd:
                                    return RegisterEddStepView(
                                      eddDate: _eddDate ?? DateTime.now().add(const Duration(days: 280)),
                                      narrationKey: _narrationKey,
                                      onHintSelected: _say,
                                      onConfirm: _handleEddConfirm,
                                    );
                                  case AuthFlowStep.cyclePrediction:
                                    return RegisterCyclePredictionStepView(
                                      lmpDate: _lmpDate ?? DateTime.now(),
                                      cycleLength: _cycleLength,
                                      narrationKey: _narrationKey,
                                      onHintSelected: _say,
                                      onNext: _handleCycleConfirm,
                                    );
                                  case AuthFlowStep.partner:
                                    return RegisterPartnerStepView(
                                      partnerNameController: _partnerNameController,
                                      partnerPhoneController: _partnerPhoneController,
                                      partnerWord: _isDad ? 'Mommy' : 'Daddy',
                                      isDad: _isDad,
                                      onSave: _handlePartnerSave,
                                      onSkip: _handlePartnerSkip,
                                      isKeyboardOpen: isKeyboardOpen,
                                    );
                                  case AuthFlowStep.family:
                                    return FamilyDetailsStepView(
                                      hasKids: _hasKids,
                                      onHasKidsChanged: (val) => setState(() => _hasKids = val),
                                      isLoading: _isSavingRegistration,
                                      onNext: _handleFamilyNext,
                                    );
                                  case AuthFlowStep.kids:
                                    return KidsDetailsStepView(
                                      children: _children,
                                      onAddChild: _openAddChildSheet,
                                      isLoading: _isSavingRegistration,
                                      onComplete: _completeRegistration,
                                    );
                                  case AuthFlowStep.dadSetup:
                                    return DadFamilySetupStepView(
                                      onJoinByCode: _handleDadJoinByCode,
                                      onRegisterPregnancy: _handleDadRegisterPregnancy,
                                      onContinue: _handleDadContinue,
                                      partnerWord: 'Mommy',
                                    );
                                  case AuthFlowStep.joinCode:
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
                              },
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
