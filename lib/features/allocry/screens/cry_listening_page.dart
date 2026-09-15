import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import 'package:allomom/features/allocry/controller/cry_controller.dart';
import 'package:allomom/features/allocry/screens/cry_not_detected_page.dart';
import 'package:allomom/features/allocry/screens/cry_result_page.dart';

/// The listening screen: microphone open, both models running on the phone.
///
/// Everything the mother sees here comes from the rolling analysis in
/// [CryController] — the coaching line, the "cry detected" state that unlocks
/// Stop, and the automatic finish once a cry is heard.
class CryListeningPage extends StatefulWidget {
  const CryListeningPage({super.key});

  @override
  State<CryListeningPage> createState() => _CryListeningPageState();
}

class _CryListeningPageState extends State<CryListeningPage>
    with SingleTickerProviderStateMixin {
  static const Color _pink = Color(0xFFFF4E6A);

  final CryController _controller = CryController.instance;

  late final AnimationController _pulse;
  late final Worker _stateWatcher;

  bool _leaving = false;

  /// Rotating guidance under the animation, so a long listen is not silent.
  static const List<String> _tips = [
    'High-pitched, intense crying often means pain or an immediate need.',
    'Rhythmic crying that rises and falls can mean your baby is tired.',
    'Short, low-pitched cries every few seconds usually signal hunger.',
    'Whimpering can mean mild discomfort or a wish to be held.',
    'Long, high-pitched screams can be colic or stomach pain.',
    'Sudden, sharp cries may mean your baby is too hot or too cold.',
  ];

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    // The rolling analysis ends the session by itself — as soon as it hears a
    // cry, or when the listening window runs out. Both arrive here.
    _stateWatcher = ever<CrySessionResult?>(_controller.sessionResult, (result) {
      if (result != null) _handleSessionEnd(result);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  Future<void> _begin() async {
    final started = await _controller.startListening();
    if (!mounted) return;
    if (!started) {
      _showMicrophoneUnavailable();
      Navigator.of(context).maybePop();
    }
  }

  void _showMicrophoneUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AlloCry needs microphone access to listen.'),
        backgroundColor: _pink,
      ),
    );
  }

  /// The session ended — by the rolling pass hearing a cry, by the listening
  /// window closing, or by her tapping stop. Any cry is already written to the
  /// vitals stream by the time this runs, so there is nothing to do but show
  /// it. Guarded so only the first outcome navigates.
  void _handleSessionEnd(CrySessionResult result) {
    if (_leaving || !mounted) return;
    _leaving = true;
    if (result.record != null) {
      Get.off(() => CryResultPage(record: result.record!));
    } else {
      Get.off(() => const CryNotDetectedPage());
    }
  }

  /// Ends the listen. The outcome arrives through [_handleSessionEnd] like
  /// the automatic one, so there is only ever one path off this screen.
  void _stop() => _controller.stopAndAnalyze();

  Future<void> _cancel() async {
    _leaving = true;
    await _controller.cancelListening();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _stateWatcher.dispose();
    _pulse.dispose();
    // Leaving mid-session must release the microphone.
    if (!_leaving) _controller.cancelListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancel();
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFF627C), Color(0xFFFF4E6A), Color(0xFFFF8A9E)],
            ),
          ),
          child: SafeArea(
            child: Obx(() {
              if (_controller.modelError.value.isNotEmpty) {
                return _buildModelError();
              }
              if (_controller.state.value == CryListeningState.loadingModel) {
                return _buildLoadingModel();
              }
              if (_controller.state.value == CryListeningState.analyzing) {
                return _buildAnalyzing();
              }
              return _buildListening();
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildModelError() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 56),
          const SizedBox(height: 16),
          Text(
            _controller.modelError.value,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 24),
          _whiteButton('Go back', _cancel),
        ],
      ),
    );
  }

  Widget _buildLoadingModel() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Colors.white),
        const SizedBox(height: 20),
        Text(
          'Warming up AlloCry…',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'The listening model runs on your phone,\nso this works without internet.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzing() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset('assets/animations/Ani8.json', width: 220, height: 220),
        const SizedBox(height: 12),
        Text(
          'Understanding the cry…',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Matching it against the five cry patterns.',
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildListening() {
    final seconds = _controller.elapsedSeconds.value;

    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: _cancel,
            ),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRecordingChip(seconds),
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) => Transform.scale(
                  scale: 1.0 + (_pulse.value * 0.06),
                  child: child,
                ),
                child: Lottie.asset(
                  'assets/animations/Ani7.json',
                  width: 240,
                  height: 240,
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _controller.statusMessage.value,
                    key: ValueKey(_controller.statusMessage.value),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                seconds > 6
                    ? 'Keep going, or tap stop to read it now.'
                    : 'Try to avoid background noise.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 28),
              _buildControls(seconds),
            ],
          ),
        ),
        _buildTip(seconds),
      ],
    );
  }

  Widget _buildRecordingChip(int seconds) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Listening  ${seconds}s',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(int seconds) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop appears once there is enough audio to be worth scoring — a
        // two-second clip would only produce a confident guess about noise.
        // A cry heard by the rolling pass ends the session on its own, so
        // this is for "that is enough, read it now".
        if (seconds > 6) ...[
          _whiteButton('Stop & analyse', _stop, icon: Icons.stop_rounded),
          const SizedBox(width: 14),
        ],
        _outlineButton('Cancel', _cancel),
      ],
    );
  }

  Widget _buildTip(int seconds) {
    final tip = _tips[(seconds ~/ 5) % _tips.length];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  tip,
                  key: ValueKey(tip),
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whiteButton(String label, VoidCallback onTap, {IconData? icon}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon ?? Icons.check_rounded, color: _pink),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          color: _pink,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 6,
      ),
    );
  }

  Widget _outlineButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white, width: 1.4),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    );
  }
}
