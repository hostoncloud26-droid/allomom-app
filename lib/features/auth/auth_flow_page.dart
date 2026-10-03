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
import 'package:allomom/features/background_audio/data/narration_catalog.dart';
import 'package:allomom/features/background_audio/data/narration_flow.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/baby/baby_form_sheet.dart';
import 'package:allomom/features/home/allobaby_flow_controller.dart';
import 'package:allomom/features/main_layout.dart';
import 'package:allomom/repositories/baby_repository.dart';
import 'package:allomom/repositories/pregnancy_state.dart';
import 'package:allomom/services/app_language.dart';
import 'package:allomom/services/google_auth_service.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sync/sync_codec.dart';
import 'package:allomom/services/tts_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:allomom/features/auth/language_selection_page.dart';
import 'package:allomom/features/auth/voice_language_selection_page.dart';
import 'package:allomom/features/auth/contact_number_page.dart';
import 'package:allomom/features/auth/verify_otp_page.dart';
import 'package:allomom/features/auth/widgets/otp_channel_sheet.dart';
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
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';

enum AuthFlowStep {
  language,
  voiceLanguage,
  contact,
  otpChannel,
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
  final String? initialVoiceLanguage;
  final String initialPhone;
  final String initialCountryCode;
  final String initialRole;
  final String initialName;

  const AuthFlowPage({
    super.key,
    this.initialStep = AuthFlowStep.language,
    this.initialLanguage = 'en',
    this.initialVoiceLanguage,
    this.initialPhone = '',
    this.initialCountryCode = '+91',
    this.initialRole = 'Mom',
    this.initialName = '',
  });

  @override
  State<AuthFlowPage> createState() => _AuthFlowPageState();
}

class _AuthFlowPageState extends State<AuthFlowPage> {
  final List<AuthFlowStep> _stepHistory = [];
  late AuthFlowStep _currentStep;
  bool _isForward = true;

  final AlloBabyFlowController _baby = AlloBabyFlowController();

  // Language state
  String _selectedLanguageCode = 'en';
  String _selectedVoiceLanguageCode = 'en';

  // Contact number state
  final TextEditingController _phoneController = TextEditingController();
  final String _countryCode = '+91';

  // OTP state
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  int _focusedOtpIndex = 0;
  bool _isVerifying = false;

  /// Where the last code went — [OtpChannel.whatsapp] or [OtpChannel.sms].
  String? _otpChannel;

  /// The channel a send is in flight on, for the verification-method step.
  String? _sendingChannel;

  /// A code has gone to this number, so picking a channel again is a resend.
  bool _otpSent = false;

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
  int _cycleLength = 28;

  // LMP Wheel state
  late DateTime _selectedLmpDate;

  // Partner state
  final TextEditingController _partnerNameController = TextEditingController();
  final TextEditingController _partnerPhoneController = TextEditingController();

  // Family & Kids state
  bool _hasKids = false;
  bool _isSavingRegistration = false;
  bool _isSavingPartner = false;
  List<Baby> _children = const [];
  String? _deletingBabyId;

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

  @override
  void initState() {
    super.initState();
    _baby.addListener(_onBabyChanged);
    _currentStep = widget.initialStep;
    _stepHistory.add(_currentStep);

    final String initialVoice = widget.initialVoiceLanguage ??
        (BackgroundAudioController.isReady &&
                BackgroundAudioController.to.languageCode.value.isNotEmpty
            ? BackgroundAudioController.to.languageCode.value
            : widget.initialLanguage);

    _selectedLanguageCode = widget.initialLanguage;
    _selectedVoiceLanguageCode =
        widget.initialStep == AuthFlowStep.language ? 'en' : initialVoice;

    if (BackgroundAudioController.isReady &&
        widget.initialStep != AuthFlowStep.language &&
        _selectedVoiceLanguageCode.isNotEmpty) {
      BackgroundAudioController.to.setLanguage(_selectedVoiceLanguageCode);
    }
    _selectedRole = widget.initialRole;
    if (widget.initialPhone.isNotEmpty) {
      _phoneController.text = widget.initialPhone;
    }
    if (widget.initialName.isNotEmpty) {
      _nameController.text = widget.initialName;
    }

    final now = DateTime.now();
    _selectedLmpDate = DateTime(now.year, now.month, now.day);

    _updateNarrationForStep(_currentStep);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _say(_narrationKey);
      }
    });

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

  void _stopSpeaking() {
    _baby.stop();
    if (BackgroundAudioController.isReady) {
      BackgroundAudioController.to.stop();
    }
    TtsService().stop();
  }

  void _onBabyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void deactivate() {
    _baby.removeListener(_onBabyChanged);
    _stopSpeaking();
    super.deactivate();
  }

  @override
  void dispose() {
    _baby.removeListener(_onBabyChanged);
    _stopSpeaking();
    _baby.dispose();
    _phoneController.dispose();
    _nameController.dispose();
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
    _baby.start(intentKey: key, resolveHint: false);
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
      case AuthFlowStep.voiceLanguage:
        _narrationKey = NarrationKeys.onbVoiceLang;
        break;
      case AuthFlowStep.contact:
        _narrationKey = NarrationKeys.onbMobile;
        break;
      case AuthFlowStep.otpChannel:
        _narrationKey = NarrationKeys.onbOtpMethod;
        break;
      case AuthFlowStep.verifyOtp:
        _narrationKey = _otpChannel == OtpChannel.sms
            ? NarrationKeys.onbOtpSms
            : NarrationKeys.onbOtpWhatsapp;
        break;
      case AuthFlowStep.role:
        _narrationKey = NarrationKeys.onbRole;
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
        _narrationKey = isNewMomRegistrationLabel(_status) && _children.isEmpty
            ? NarrationKeys.newChildrenList
            : NarrationFlowKeys.of(_status).kids;
        break;
      case AuthFlowStep.dadSetup:
        _narrationKey = NarrationKeys.dadFamilyChoice;
        break;
      case AuthFlowStep.joinCode:
        _narrationKey = NarrationKeys.dadJoinCode;
        break;
    }
  }

  void _goToStep(AuthFlowStep step) {
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
    _say(_narrationKey);
  }

  void _resetStepState(AuthFlowStep prevStep) {
    if (prevStep == AuthFlowStep.name ||
        prevStep == AuthFlowStep.role ||
        prevStep == AuthFlowStep.verifyOtp ||
        prevStep == AuthFlowStep.contact ||
        prevStep == AuthFlowStep.language ||
        prevStep == AuthFlowStep.dadSetup) {
      _status = '';
      _lmpDate = null;
      _eddDate = null;
      _cycleLength = 28;
      _registerPregnancyForPartner = false;
      final now = DateTime.now();
      _selectedLmpDate = DateTime(now.year, now.month, now.day);
    } else if (prevStep == AuthFlowStep.status) {
      _lmpDate = null;
      _eddDate = null;
      _cycleLength = 28;
      final now = DateTime.now();
      _selectedLmpDate = DateTime(now.year, now.month, now.day);
    } else if (prevStep == AuthFlowStep.lmp ||
        prevStep == AuthFlowStep.cyclePrediction) {
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
      _say(_narrationKey);
    } else if (Navigator.canPop(context)) {
      narratedPop(context);
    }
  }

  String get _currentStepTitle {
    switch (_currentStep) {
      case AuthFlowStep.language:
        return 'Please Select Your App Language';
      case AuthFlowStep.voiceLanguage:
        return "Baby's Voice Language";
      case AuthFlowStep.contact:
        return 'Set Your Contact Number';
      case AuthFlowStep.otpChannel:
        return 'Verification Method';
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

  // ─── STEP 0: LANGUAGE ACTIONS ───
  void _handleLanguageSelected(String code) {
    setState(() {
      _selectedLanguageCode = code;
    });
    if (AppLanguage.supported.contains(code)) {
      _say(NarrationKeys.onbLangSelected);
    } else {
      _say(NarrationKeys.onbLangOther);
    }
  }

  Future<void> _handleLanguageProceed() async {
    await AppLanguage.save(_selectedLanguageCode);
    _goToStep(AuthFlowStep.voiceLanguage);
  }

  // ─── STEP 0B: VOICE LANGUAGE ACTIONS ───
  void _handleVoiceLanguageSelected(String code) {
    final clean = code.trim().toLowerCase();
    setState(() {
      _selectedVoiceLanguageCode = clean;
    });
    if (BackgroundAudioController.isReady) {
      BackgroundAudioController.to.setLanguage(clean);
    }
    OfflineChatbotController.instance.setLanguage(clean);
    _say(NarrationKeys.onbLangSelected);
  }

  Future<void> _handleVoiceLanguageProceed() async {
    if (BackgroundAudioController.isReady) {
      BackgroundAudioController.to.setLanguage(_selectedVoiceLanguageCode);
    }
    AppLanguage.saveVoice(_selectedVoiceLanguageCode);
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
      _showMessage('Please enter a valid 10-digit mobile number', isError: true);
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

    // A number typed afresh gets a first send, not a resend.
    _otpSent = false;
    _goToStep(AuthFlowStep.otpChannel);
  }

  // ─── STEP 1b: VERIFICATION METHOD ACTIONS ───
  String get _phoneDigits =>
      _phoneController.text.trim().replaceAll(' ', '').replaceAll('-', '');

  /// Sends the code over [channel]. The first time from this number it is a
  /// send; coming back here from "Resend" it is a resend.
  Future<void> _handleChannelSelected(String channel) async {
    final phone = _phoneDigits;
    final isResend = _otpSent;
    setState(() => _sendingChannel = channel);

    final error = isResend
        ? await AuthController.instance.resendOtp(
            phone,
            countryCode: _countryCode,
            channel: channel,
          )
        : await AuthController.instance.sendOtp(
            phone,
            countryCode: _countryCode,
            channel: channel,
          );

    if (!mounted) return;
    setState(() => _sendingChannel = null);

    if (error != null) {
      _say(
        ConnectionController.instance.isInternetAvailable
            ? NarrationKeys.onbMobileInvalid
            : NarrationKeys.onbMobileInternet,
      );
      _showMessage(error, isError: true);
      return;
    }

    setState(() {
      _otpChannel = channel;
      _otpSent = true;
    });
    for (final controller in _otpControllers) {
      controller.clear();
    }

    _showMessage(
      'OTP sent to $_countryCode $phone via ${OtpChannel.label(channel)}',
    );

    _goToStep(AuthFlowStep.verifyOtp);

    if (isResend) {
      _say(channel == OtpChannel.whatsapp
          ? NarrationKeys.onbOtpResendWhatsapp
          : NarrationKeys.onbOtpResendSms);
    } else {
      _say(channel == OtpChannel.whatsapp
          ? NarrationKeys.onbOtpWhatsapp
          : NarrationKeys.onbOtpSms);
    }
  }

  // ─── STEP 2: OTP ACTIONS ───
  String get _enteredOtp => _otpControllers.map((c) => c.text.trim()).join();

  Future<void> _handleVerifyOtp() async {
    final otpCode = _enteredOtp;
    if (otpCode.length < 6) {
      _say(NarrationKeys.onbOtpWrong);
      _showMessage('Please enter the full 6-digit code', isError: true);
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
      final joined = outcome.joinedFamily;
      // A partner their spouse already set up lands straight in the family
      // rather than in a registration flow asking for it all again.
      _showMessage(
        joined != null
            ? 'Welcome${name.isEmpty ? '' : ', $name'}! ${joined.welcomeMessage}'
            : 'Welcome back${name.isEmpty ? '' : ', $name'}!',
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
      return;
    }

    _showMessage("Verified! Let's set up your profile.");
    _goToStep(AuthFlowStep.role);
  }

  /// Back to the verification-method step, so a code that never arrived on
  /// WhatsApp can be tried over SMS. Picking a channel there resends.
  void _handleResendOtp() => _handleBackNavigation();

  // ─── STEP 3: ROLE ACTIONS ───
  void _handleRoleSelected(String role) {
    final isDad = role.trim().toLowerCase() == 'dad';
    setState(() {
      _selectedRole = role;
    });
    _say(isDad ? NarrationKeys.onbRoleDad : NarrationKeys.onbRoleMom);
    // Saved immediately rather than waiting for the end of registration —
    // screens reached before then (e.g. People's own "Create Family" dialog)
    // read gender off the profile to work out the caller's role, and an
    // unset gender there silently falls back to "mother".
    unawaited(
      MainController.instance.saveRegistration(
        gender: isDad ? 'male' : 'female',
        markRegistered: false,
      ),
    );
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
      _showMessage('Please enter your name', isError: true);
      return;
    }
    _say(NarrationKeys.onbNameReaction);

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
    });
    switch (st.trim().toLowerCase()) {
      case 'pre pregnancy':
        _say(NarrationKeys.onbStatusPrePregnancy);
        break;
      case 'new mom':
        _say(NarrationKeys.onbStatusNewMom);
        break;
      default:
        _say(NarrationKeys.onbStatusPregnant);
    }
  }

  void _handleStatusNext() {
    if (_status.isEmpty) {
      _say(NarrationKeys.onbStatus);
      _showMessage('Please select an option to continue');
      return;
    }
    _say(NarrationKeys.onbAlmostDone);
    _goToStep(AuthFlowStep.lmp);
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

    _say(
      _isPregnancyFlow
          ? NarrationKeys.pregLmpConfirm
          : NarrationKeys.preCycleSaved,
    );

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
    _goToStep(AuthFlowStep.partner);
  }

  // ─── STEP 8: PARTNER ACTIONS ───
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

    _say(NarrationKeys.pregPartnerSaved);
    _goToAfterPartner();
  }

  /// The household's name while the user's own name is not saved yet — the
  /// profile is only written at the end of registration.
  String get _familyNameForPartner {
    final me = _nameController.text.trim();
    return me.isEmpty ? 'My Family' : "$me's Family";
  }

  void _handlePartnerSkip() {
    _say(NarrationKeys.pregPartnerSkip);
    _goToAfterPartner();
  }

  /// A new mom has a baby by definition, so she skips the "any kids?"
  /// question and goes straight to adding them.
  void _goToAfterPartner() {
    if (isNewMomRegistrationLabel(_status)) {
      _goToStep(AuthFlowStep.kids);
      unawaited(_loadChildren());
    } else {
      _goToStep(AuthFlowStep.family);
    }
  }

  // ─── STEP 9: FAMILY ACTIONS ───
  Future<void> _handleFamilyNext() async {
    if (_hasKids) {
      _goToStep(AuthFlowStep.kids);
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
    setState(() => _isSavingRegistration = true);
    try {
      final isDadRole = _isDad;
      final main = MainController.instance;

      await main.saveRegistration(
        name: _nameController.text.trim(),
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
      _say(NarrationFlowKeys.of(_status).setupDone);
      _showMessage(
        'Welcome, ${_nameController.text.trim()}! Your family profile is ready.',
      );

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

  /// A dad either joins his family by code or finishes here. There is nothing
  /// else for him to set up: the pregnancy and the children are Mommy's, and
  /// he sees them from People once they are in the same family.
  Future<void> _handleDadContinue() {
    _say(NarrationKeys.dadFamilySetup);
    return _completeRegistration();
  }

  // ─── STEP 11: JOIN CODE ACTIONS ───
  Future<void> _handleJoinFamilyCode() async {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.length < 6) {
      _say(NarrationKeys.dadJoinWrong);
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
      _say(NarrationKeys.dadJoinWrong);
      setState(() => _codeErrorMessage = error);
      _showMessage(error, isError: true);
      return;
    }

    speak(NarrationKeys.dadJoinSuccess, force: true);
    _showMessage('Successfully connected to family!');
    await _completeRegistration();
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

  Widget _buildCurrentStepView(bool isKeyboardOpen) {
    switch (_currentStep) {
      case AuthFlowStep.language:
        return LanguageStepView(
          selectedLanguageCode: _selectedLanguageCode,
          onLanguageSelected: _handleLanguageSelected,
          onProceed: _handleLanguageProceed,
        );
      case AuthFlowStep.voiceLanguage:
        return VoiceLanguageStepView(
          selectedVoiceLanguageCode: _selectedVoiceLanguageCode,
          onVoiceLanguageSelected: _handleVoiceLanguageSelected,
          onProceed: _handleVoiceLanguageProceed,
        );
      case AuthFlowStep.contact:
        return ContactNumberStepView(
          phoneController: _phoneController,
          countryCode: _countryCode,
          isLoading: false,
          onSendOtp: _handleSendOtp,
          isKeyboardOpen: isKeyboardOpen,
        );
      case AuthFlowStep.otpChannel:
        return OtpChannelStepView(
          phoneLabel: '$_countryCode $_phoneDigits',
          sendingChannel: _sendingChannel,
          onChannelSelected: _handleChannelSelected,
        );
      case AuthFlowStep.verifyOtp:
        return VerifyOtpStepView(
          phone: _phoneController.text.trim(),
          countryCode: _countryCode,
          channel: _otpChannel,
          otpControllers: _otpControllers,
          otpFocusNodes: _otpFocusNodes,
          focusedIndex: _focusedOtpIndex,
          isVerifying: _isVerifying,
          isResending: false,
          onVerifyOtp: _handleVerifyOtp,
          onResendOtp: _handleResendOtp,
          onWhereCodeTapped: () => _say(NarrationKeys.onbOtpWhere),
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
          onCycleLengthChanged: (len) => setState(() => _cycleLength = len),
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
          isSaving: _isSavingPartner,
          isKeyboardOpen: isKeyboardOpen,
        );
      case AuthFlowStep.family:
        return FamilyDetailsStepView(
          hasKids: _hasKids,
          onHasKidsChanged: (val) {
            setState(() => _hasKids = val);
            _say(val ? NarrationKeys.pregKidsYes : NarrationKeys.pregKidsNo);
          },
          isLoading: _isSavingRegistration,
          onNext: _handleFamilyNext,
        );
      case AuthFlowStep.kids:
        return KidsDetailsStepView(
          children: _children,
          onChildAdded: _handleChildAdded,
          onNarrate: _say,
          onAddCancelled: () => _say(NarrationFlowKeys.of(_status).kids),
          onDeleteChild: _handleDeleteChild,
          deletingChildId: _deletingBabyId,
          isLoading: _isSavingRegistration,
          isNewMom: isNewMomRegistrationLabel(_status),
          onComplete: _completeRegistration,
        );
      case AuthFlowStep.dadSetup:
        return DadFamilySetupStepView(
          onJoinByCode: _handleDadJoinByCode,
          onContinue: _handleDadContinue,
          isLoading: _isSavingRegistration,
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
  }

  Widget _buildFlow(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final String targetVoiceLang = _currentStep == AuthFlowStep.language
        ? 'en'
        : (_selectedVoiceLanguageCode.isNotEmpty
            ? _selectedVoiceLanguageCode
            : 'en');
    final String activeLanguageForNarration = (targetVoiceLang != 'en' &&
            !NarrationCatalog.hasRecordedAudio(_narrationKey, targetVoiceLang))
        ? 'en'
        : targetVoiceLang;

    final String currentText = _baby.line.trim().isNotEmpty
        ? _baby.line.trim()
        : (BackgroundAudioController.isReady &&
                BackgroundAudioController.to.currentText.value.trim().isNotEmpty
            ? BackgroundAudioController.to.currentText.value.trim()
            : (BackgroundAudioController.isReady
                ? BackgroundAudioController.to.textFor(_narrationKey, activeLanguageForNarration)
                : (OfflineChatbotController.instance.libraryAudioNow(_narrationKey, activeLanguageForNarration)?.transcription?.trim() ??
                    '')));
    final bool isSpeaking = _baby.isRunning ||
        (BackgroundAudioController.isReady &&
            BackgroundAudioController.to.isPlaying.value);

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
                            if (_stepHistory.length > 1 ||
                                Navigator.canPop(context))
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

                      // Animated Baby Avatar Section (AlloCry pattern)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: BabyHeroBanner(
                            speechText: currentText,
                            bubblePosition: SpeechBubblePosition.topCenter,
                            expand: true,
                            speakingOverride: isSpeaking,
                            onSpeakerTap: () {
                              if (isSpeaking) {
                                _stopSpeaking();
                              } else {
                                _say(_narrationKey);
                              }
                              setState(() {});
                            },
                          ),
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
