/// Today's Planner, ported from AlloKonnect's `todays_plan_page.dart`: the
/// day's meals, sleep and every Today's Care item on a 24-hour timeline, one
/// row per hour. Meals are dragged to move them (or onto the bin to take them
/// off), care items are tapped to log or tick them off just as on Home, empty
/// hours open Add Plan, and AlloBaby's assistant plans, logs and ticks things
/// off from what she says or types.
///
/// AlloKonnect's tasks, meetings, Google Calendar events and check-ins have
/// no place in Allomom and are left out.
library;

import 'package:allomom/models/vital_shapes.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:allomom/components/floating_baby_speech_overlay.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/my_health/vitals/sleep/sleep_utils.dart';
import 'package:allomom/features/overview_section/todays_care/care_catalogue.dart';
import 'package:allomom/features/overview_section/todays_care/care_day.dart';
import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/features/overview_section/todays_care/planner/todays_plan_data.dart';
import 'package:allomom/features/overview_section/todays_care/planner/todays_planner_ai_manager.dart';
import 'package:allomom/features/overview_section/todays_care/todocare_section.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_meal_sheet.dart';

class TodaysPlanPage extends StatefulWidget {
  const TodaysPlanPage({super.key});

  @override
  State<TodaysPlanPage> createState() => _TodaysPlanPageState();
}

class _TodaysPlanPageState extends State<TodaysPlanPage> {
  static const _plannerIntentKey = 'screen_daily_activity_info';
  static const _fallbackText =
      "Welcome to your daily planner! Here you can track meals, sleep, and care tasks.";

  static const double _hourHeight = 72;
  static const double _timeColumnWidth = 64;

  static const Color _sleepColor = Color(0xFF8B5CF6);
  static const int _dragSnapMinutes = 15;

  // Tiles never draw shorter than this, so they count as at least this long
  // when deciding what overlaps.
  static const int _minTileMinutes = 30;

  // Every tile is given at least this much height so its start and end times
  // fit beside it in the hour column; overlapping tiles are stacked one under
  // another.
  static const double _tileMinHeight = 64;

  // How the day maps to heights, rebuilt every frame from the tiles' resting
  // times. Stretches of the day with short or overlapping tiles are drawn
  // taller.
  _Timeline _timeline = const _Timeline(_hourHeight, [], {});

  // Open an hour above "now" so the current slot is in view from the start.
  final ScrollController _scrollController = ScrollController(
    initialScrollOffset: ((DateTime.now().hour - 1).clamp(0, 23)) * _hourHeight,
  );
  List<PlannedMeal> _meals = [];
  List<SleepSession> _sleep = [];

  // Today's Care for the whole day; its items but the meals are tiles here.
  CareDay _care = CareDay.empty;
  List<CareItem> _careItems = [];
  bool _isLoading = true;
  DateTime _now = DateTime.now();

  // The day on show, at midnight.
  final DateTime _day = DateUtils.dateOnly(DateTime.now());
  bool get _isToday => DateUtils.isSameDay(_day, _now);

  // Bumped on every load, so a slow load no longer wanted is dropped.
  int _loadId = 0;
  Timer? _clock;
  late final HealthVitalsController _vitals = HealthVitalsController.instance;

  final GlobalKey _contentKey = GlobalKey();
  final GlobalKey _viewportKey = GlobalKey();
  final GlobalKey _trashKey = GlobalKey();

  // Drag state: the tile being moved, where it would land, and where on the
  // tile it was grabbed (so it doesn't jump to the finger).
  _DragItem? _drag;
  int _dragMinute = 0;
  double _grabDy = 0;
  Offset? _lastPointer;
  bool _overTrash = false;
  bool _savingDrop = false;
  Timer? _autoScrollTimer;

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  StreamSubscription<RecordState>? _recordState;

  // Voice commands: what the assistant is doing, what it heard, and the
  // actions it's carrying out, shown in a panel over the timeline.
  static const Color _aiColor = Color(0xFFA855F7);
  final TodaysPlannerAiManager _ai = TodaysPlannerAiManager();
  _AiPhase _aiPhase = _AiPhase.idle;
  String _aiTranscript = '';
  String _aiReply = '';
  List<_AiStep> _aiSteps = [];
  Timer? _aiDismissTimer;

  // The sheet AlloBaby opens: listening, or a text field once switched to
  // typing.
  bool _assistantOpen = false;
  bool _typing = false;
  final TextEditingController _aiInput = TextEditingController();
  final FocusNode _aiInputFocus = FocusNode();
  DateTime? _recordingSince;
  Timer? _recordingTicker;
  // How far the popup has been dragged down, to close it past a point.
  double _sheetDrag = 0;

  // The tile an action just changed, flashed once; bumping the tick replays
  // the flash.
  String? _flashKey;
  int _flashTick = 0;

  @override
  void initState() {
    super.initState();
    _load();
    // A pause here while recording means part of the speech is missing.
    _recordState = _recorder.onStateChanged().listen(
      (state) => debugPrint('TodaysPlanPage: recorder $state'),
    );

    // Keep the "now" line moving.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });

    // A meal logged anywhere (Today's Care, the chatbot) shows up here.
    _vitals.addListener(_onVitalsChanged);
  }

  @override
  void dispose() {
    _vitals.removeListener(_onVitalsChanged);
    _vitalsDebounce?.cancel();
    _clock?.cancel();
    _autoScrollTimer?.cancel();
    _aiDismissTimer?.cancel();
    _recordingTicker?.cancel();
    _aiInput.dispose();
    _aiInputFocus.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _recordState?.cancel();
    super.dispose();
  }

  // The controller notifies several times per write; one reload is enough.
  Timer? _vitalsDebounce;
  void _onVitalsChanged() {
    _vitalsDebounce?.cancel();
    _vitalsDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _drag == null && !_savingDrop) _load();
    });
  }

  Future<void> _load() async {
    final loadId = ++_loadId;
    final day = _day;
    // Meals need the sleep first: morning plans follow the wake-up time.
    final sleep = await TodaysPlanData.loadSleep(day);
    final results = await Future.wait([
      TodaysPlanData.loadMeals(day, sleep: sleep),
      CareDay.load(CareDayPart.values),
    ]);
    if (!mounted || loadId != _loadId) return;
    final care = results[1] as CareDay;
    setState(() {
      _meals = results[0] as List<PlannedMeal>;
      _sleep = sleep;
      _care = care;
      _careItems = TodaysPlanData.careItemsOnPlanner(care);
      _isLoading = false;
    });
  }

  void _toast(String message, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? const Color(0xFF10B981) : dangerRed,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  String _hourLabel(int hour) =>
      DateFormat('h a').format(DateTime(2000, 1, 1, hour));

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    final isDark = pal.isDark;
    _timeline = _layoutTimeline();

    return PopScope(
      // Back closes the assistant sheet first.
      canPop: !_assistantOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _closeAssistant();
      },
      child: Scaffold(
        backgroundColor: pal.scaffoldSoft,
        appBar: AppBar(
          backgroundColor: pal.scaffoldSoft,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: pal.textPrimary),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: pal.textPrimary,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Planner",
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: pal.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                DateFormat('EEEE, d MMMM').format(_day),
                style: GoogleFonts.poppins(fontSize: 12, color: pal.textMuted),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_isToday) _buildWelcomeCard(isDark),
            Expanded(child: _buildTimeline(isDark)),
          ],
        ),
      ),
    );
  }

  // ---- Voice -------------------------------------------------------------

  bool get _aiBusy =>
      _aiPhase == _AiPhase.thinking || _aiPhase == _AiPhase.acting;

  /// Starts recording on the first tap; the next stops it and hands the
  /// recording to the assistant.
  Future<void> _toggleRecording() async {
    HapticFeedback.mediumImpact();
    try {
      if (_isRecording) {
        // People tap stop on their last word; keep a moment of tail.
        await Future.delayed(const Duration(milliseconds: 400));
        _recordingTicker?.cancel();
        final path = await _recorder.stop();
        if (mounted) setState(() => _isRecording = false);
        debugPrint('TodaysPlanPage: recording saved at $path');
        if (path != null) {
          await _runCommand(path: path);
        } else {
          _setAiPhase(_AiPhase.idle);
        }
        return;
      }

      if (!await _recorder.hasPermission()) {
        _toast('Microphone permission is needed', success: false);
        return;
      }
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'plan_voice_${DateTime.now().millisecondsSinceEpoch}.wav',
      );
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          // Speech effects gate out stretches of speech on some inputs (the
          // emulator especially); Gemini copes better with the raw signal.
          autoGain: false,
          noiseSuppress: false,
          echoCancel: false,
          // By default recording silently pauses whenever something else
          // takes audio focus (a sound, playback), leaving half a recording.
          audioInterruption: AudioInterruptionMode.none,
          androidConfig: AndroidRecordConfig(
            audioSource: AndroidAudioSource.mic,
            // Switching to a Bluetooth headset mid-recording drops the mic.
            manageBluetooth: false,
          ),
        ),
        path: path,
      );
      _aiDismissTimer?.cancel();
      _recordingSince = DateTime.now();
      _recordingTicker?.cancel();
      _recordingTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
      if (mounted) {
        setState(() {
          _isRecording = true;
          _aiPhase = _AiPhase.listening;
          _aiTranscript = '';
          _aiReply = '';
          _aiSteps = [];
        });
      }
    } catch (e) {
      debugPrint('TodaysPlanPage: recording failed: $e');
      if (mounted) {
        setState(() {
          _isRecording = false;
          _aiPhase = _AiPhase.idle;
        });
      }
    }
  }

  /// Stops a recording in progress without sending it.
  Future<void> _cancelRecording() async {
    _recordingTicker?.cancel();
    try {
      await _recorder.stop();
    } catch (e) {
      debugPrint('TodaysPlanPage: stopping recording failed: $e');
    }
    if (mounted) {
      setState(() {
        _isRecording = false;
        _aiPhase = _AiPhase.idle;
      });
    }
  }

  /// Opens the assistant sheet and starts listening.
  void _openAssistant() {
    HapticFeedback.selectionClick();
    setState(() {
      _assistantOpen = true;
      _typing = false;
    });
    if (!_aiBusy && !_isRecording) _toggleRecording();
  }

  /// Closes the sheet, dropping a recording in progress; the next request
  /// starts a new conversation.
  Future<void> _closeAssistant() async {
    if (!_assistantOpen) return;
    _aiDismissTimer?.cancel();
    _aiInputFocus.unfocus();
    if (!_aiBusy) _ai.resetConversation();
    // Close first: stopping the recorder can take a moment.
    setState(() {
      _assistantOpen = false;
      _typing = false;
      _sheetDrag = 0;
      if (!_aiBusy && !_isRecording) _aiPhase = _AiPhase.idle;
    });
    if (_isRecording) await _cancelRecording();
  }

  Future<void> _switchToTyping() async {
    HapticFeedback.selectionClick();
    _aiDismissTimer?.cancel();
    if (_isRecording) await _cancelRecording();
    if (!mounted) return;
    setState(() => _typing = true);
    _aiInputFocus.requestFocus();
  }

  void _switchToVoice() {
    _aiInputFocus.unfocus();
    setState(() => _typing = false);
    if (!_aiBusy && !_isRecording) _toggleRecording();
  }

  /// Sends what's typed in the sheet to the assistant.
  Future<void> _sendTyped() async {
    final text = _aiInput.text.trim();
    if (text.isEmpty || _aiBusy) return;
    HapticFeedback.lightImpact();
    _aiInput.clear();
    _aiDismissTimer?.cancel();
    setState(() {
      _aiTranscript = '';
      _aiReply = '';
      _aiSteps = [];
    });
    await _runCommand(text: text);
  }

  void _setAiPhase(_AiPhase phase) {
    if (mounted) setState(() => _aiPhase = phase);
  }

  PlannerSnapshot _snapshot() =>
      PlannerSnapshot(day: _day, meals: _meals, care: _care);

  /// Sends the recording at [path] (or the typed [text]) to the assistant,
  /// which works through it by calling planner functions; each change shows
  /// up as a step in the sheet and flashes the tile it touched.
  Future<void> _runCommand({String? path, String? text}) async {
    _setAiPhase(_AiPhase.thinking);
    final String reply;
    try {
      reply = await _ai.run(
        audioPath: path,
        text: text,
        snapshot: _snapshot,
        onTranscript: (transcript) {
          if (mounted) setState(() => _aiTranscript = transcript);
        },
        onActionStart: (action) {
          if (!mounted) return;
          setState(() {
            _aiPhase = _AiPhase.acting;
            _aiSteps = [
              ..._aiSteps,
              _AiStep(action)..status = _AiStepStatus.running,
            ];
          });
        },
        onActionDone: _onAiActionDone,
      );
    } catch (e) {
      debugPrint('TodaysPlanPage: voice command failed: $e');
      if (!mounted) return;
      setState(() {
        _aiPhase = _AiPhase.failed;
        _aiReply = "Couldn't understand that. Try again.";
      });
      _dismissAiLater();
      return;
    }
    if (!mounted) return;

    if (_aiTranscript.isEmpty) {
      setState(() {
        _aiPhase = _AiPhase.failed;
        _aiReply = "Didn't catch that. Try again.";
      });
      _dismissAiLater();
      return;
    }

    final failed = _aiSteps
        .where((s) => s.status == _AiStepStatus.failed)
        .length;
    setState(() {
      // The reply is written after the model saw every result, so it can
      // stand; fall back to a count when it gave none.
      _aiReply = reply.isNotEmpty
          ? reply
          : failed > 0
          ? '${_aiSteps.length - failed} of ${_aiSteps.length} changes made'
          : 'Done';
      _aiPhase = _aiSteps.isNotEmpty && failed == _aiSteps.length
          ? _AiPhase.failed
          : _AiPhase.done;
    });
    // A question waits for the spoken answer rather than disappearing.
    _dismissAiLater(after: _aiAsking ? const Duration(seconds: 45) : null);
  }

  /// Marks the running step done or failed, reloads what the action changed,
  /// and flashes its tile before the model moves on.
  Future<void> _onAiActionDone(
    PlannerAiAction action,
    PlannerActionOutcome outcome,
  ) async {
    await _load();
    if (!mounted) return;
    HapticFeedback.lightImpact();
    final step = _aiSteps.reversed.toList().firstWhereOrNull(
      (s) => s.action == action && s.status == _AiStepStatus.running,
    );
    setState(() {
      step?.status = outcome.ok ? _AiStepStatus.done : _AiStepStatus.failed;
      step?.error = outcome.error;
      if (outcome.tileKey != null) {
        _flashKey = outcome.tileKey;
        _flashTick++;
      }
    });
    if (outcome.tileKey != null) _scrollToTile(outcome.tileKey!);
    // Leave time for the flash before the next change.
    await Future.delayed(const Duration(milliseconds: 750));
  }

  /// Whether the assistant's last reply asks her something.
  bool get _aiAsking =>
      _aiPhase == _AiPhase.done && _aiReply.trim().endsWith('?');

  /// Closes the sheet a while after a spoken request is answered; while
  /// typing it stays open for the next one.
  void _dismissAiLater({Duration? after}) {
    _aiDismissTimer?.cancel();
    if (_typing) return;
    _aiDismissTimer = Timer(after ?? const Duration(seconds: 8), () {
      if (mounted && !_isRecording && !_aiBusy && !_typing) {
        _closeAssistant();
      }
    });
  }

  /// Scrolls to [key]'s tile once the frame showing it is laid out.
  void _scrollToTile(String key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final slot = _timeline.slots[key];
      if (slot != null && mounted) _scrollToMinute(slot.start);
    });
  }

  static const double _controlsBottom = 16;
  static const double _botSize = 68;

  /// Opens Add Plan from now.
  void _addPlanNow() {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final start = _isToday
        ? (now.hour * 60 + now.minute).clamp(0, 1439 - 30).toInt()
        : 9 * 60;
    _showAddPlanSheet(startMinute: start);
  }

  /// Along the bottom edge: Add Plan, and AlloBaby, which opens the
  /// assistant sheet.
  Widget _buildBottomBar(bool isDark) {
    final pal = context.palette;
    return Positioned(
      left: 16,
      right: 16,
      bottom: _controlsBottom,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _botSize,
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _addPlanNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : Colors.white,
                      foregroundColor: pal.textPrimary,
                      elevation: 4,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                        side: BorderSide(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 22),
                    label: Text(
                      'Add Plan',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              _GradientRing(
                active: !_aiBusy,
                size: _botSize,
                child: FloatingActionButton(
                  heroTag: 'plan-speak',
                  tooltip: 'Ask AlloBaby',
                  onPressed: _openAssistant,
                  backgroundColor: isDark
                      ? const Color(0xFF2A2A2A)
                      : Colors.white,
                  // Idle, the gradient ring is the border.
                  shape: !_aiBusy
                      ? const CircleBorder()
                      : CircleBorder(
                          side: BorderSide(
                            color: _aiColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                  child: _aiBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: _aiColor,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/allobaby/AlloMombabySquare.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A 44px round icon button in the assistant capsule.
  Widget _capsuleButton({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required VoidCallback? onPressed,
    Color? background,
    Color? foreground,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            background ??
            (isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFF1F5F9)),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: 22,
        padding: EdgeInsets.zero,
        color:
            foreground ?? (isDark ? Colors.white70 : const Color(0xFF475569)),
        icon: Icon(icon),
      ),
    );
  }

  /// The capsule's centre mic: tap to stop while recording (with the time
  /// so far), a spinner while the assistant works.
  Widget _buildSheetMic() {
    const size = 58.0;
    if (_aiBusy) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _aiColor.withValues(alpha: 0.12),
          border: Border.all(color: _aiColor, width: 2),
        ),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: _aiColor),
        ),
      );
    }

    if (_isRecording) {
      final elapsed = _recordingSince == null
          ? Duration.zero
          : DateTime.now().difference(_recordingSince!);
      return GestureDetector(
        onTap: _toggleRecording,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Pulse(
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${elapsed.inMinutes.toString().padLeft(2, '0')}:'
              '${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleRecording,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [_aiColor, _aiColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _aiColor.withValues(alpha: 0.35),
              blurRadius: 14,
              spreadRadius: 2,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 32),
      ),
    );
  }

  /// What the assistant is doing, above the capsule once there's something
  /// to show: thinking, each action ticking off, then its reply.
  Widget _buildAssistantStatus(bool isDark) {
    final pal = context.palette;

    final title = switch (_aiPhase) {
      _AiPhase.thinking => 'Thinking…',
      _AiPhase.acting => 'Updating your plan…',
      _ => _aiReply.isNotEmpty ? _aiReply : 'Done',
    };

    final Widget badge = switch (_aiPhase) {
      _AiPhase.thinking || _AiPhase.acting => const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      _AiPhase.failed => const Icon(
        Icons.error_outline_rounded,
        color: Colors.white,
        size: 18,
      ),
      _ => const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 18,
      ),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232026) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _aiColor.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _aiPhase == _AiPhase.failed
                      ? Colors.red.shade400
                      : _aiColor,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(key: ValueKey(_aiPhase), child: badge),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    title,
                    key: ValueKey(title),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: pal.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_aiTranscript.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '“$_aiTranscript”',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: pal.textMuted,
              ),
            ),
          ],
          if (_aiAsking) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _Pulse(
                  child: Icon(
                    _typing ? Icons.keyboard_alt_outlined : Icons.mic_rounded,
                    size: 14,
                    color: _aiColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _typing ? 'Type your answer' : 'Tap the mic to answer',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _aiColor,
                  ),
                ),
              ],
            ),
          ],
          if (_aiSteps.isNotEmpty) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (var i = 0; i < _aiSteps.length; i++)
                      _AiStepRow(
                        key: ValueKey('ai-step-$i-${_aiSteps[i].hashCode}'),
                        step: _aiSteps[i],
                        index: i,
                        isDark: isDark,
                        accent: _aiColor,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The popup AlloBaby opens: a fade up from the bottom edge, a pill to
  /// close it, and a floating capsule with the mic in the centre and the
  /// keyboard beside it (or, switched to typing, a text field). What the
  /// assistant is doing shows above it.
  Widget _buildAssistantSheet(bool isDark) {
    final pal = context.palette;
    final open = _assistantOpen;
    final fadeBase = pal.scaffoldSoft;
    final capsuleBg = isDark ? const Color(0xFF18202F) : Colors.white;
    final showStatus =
        _aiPhase == _AiPhase.thinking ||
        _aiPhase == _AiPhase.acting ||
        _aiPhase == _AiPhase.done ||
        _aiPhase == _AiPhase.failed;

    final Widget capsuleContent = _typing
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _capsuleButton(
                icon: Icons.mic_none_rounded,
                tooltip: 'Speak',
                isDark: isDark,
                onPressed: _aiBusy ? null : _switchToVoice,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // The placeholder, scaled down to fit on one line.
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _aiInput,
                      builder: (context, value, _) => value.text.isEmpty
                          ? IgnorePointer(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'e.g. I had idli for breakfast',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: pal.textMuted,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    TextField(
                      controller: _aiInput,
                      focusNode: _aiInputFocus,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendTyped(),
                      style: TextStyle(fontSize: 15, color: pal.textPrimary),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _aiInput,
                builder: (context, value, _) {
                  final canSend = value.text.trim().isNotEmpty && !_aiBusy;
                  return _capsuleButton(
                    icon: _aiBusy
                        ? Icons.hourglass_top_rounded
                        : Icons.arrow_upward_rounded,
                    tooltip: 'Send',
                    isDark: isDark,
                    onPressed: canSend ? _sendTyped : null,
                    background: canSend
                        ? _aiColor
                        : (isDark ? Colors.white12 : Colors.black12),
                    foreground: Colors.white,
                  );
                },
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Keeps the mic centred in the capsule.
              const SizedBox(width: 89),
              _buildSheetMic(),
              const SizedBox(width: 45),
              _capsuleButton(
                icon: Icons.keyboard_alt_outlined,
                tooltip: 'Type instead',
                isDark: isDark,
                onPressed: _aiBusy ? null : _switchToTyping,
              ),
            ],
          );

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !open,
        // Dragged down, the popup follows the finger and closes past a point
        // or on a fling.
        child: GestureDetector(
          onVerticalDragUpdate: (d) =>
              setState(() => _sheetDrag = math.max(0, _sheetDrag + d.delta.dy)),
          onVerticalDragEnd: (d) {
            if (_sheetDrag > 60 || (d.primaryVelocity ?? 0) > 400) {
              _closeAssistant();
            } else {
              setState(() => _sheetDrag = 0);
            }
          },
          child: AnimatedSlide(
            offset: open ? Offset.zero : const Offset(0, 1.1),
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: Transform.translate(
              offset: Offset(0, _sheetDrag),
              child: AnimatedOpacity(
                opacity: open ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.45, 1.0],
                      colors: [
                        fadeBase.withValues(alpha: 0.95),
                        fadeBase.withValues(alpha: 0.65),
                        fadeBase.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tapping the pill closes the popup, which ends the
                            // conversation: the next request starts afresh.
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _closeAssistant,
                              child: Container(
                                margin: const EdgeInsets.only(
                                  top: 8,
                                  bottom: 16,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.45 : 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.18)
                                        : Colors.black.withValues(alpha: 0.1),
                                    width: 0.8,
                                  ),
                                ),
                                child: Icon(
                                  Icons.remove_rounded,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black54,
                                  size: 20,
                                ),
                              ),
                            ),
                            if (showStatus) _buildAssistantStatus(isDark),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: capsuleBg.withValues(
                                  alpha: isDark ? 0.85 : 0.95,
                                ),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : const Color(0xFFCBD5E1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: isDark ? 0.35 : 0.08,
                                    ),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: capsuleContent,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A glow that sweeps once over the tile an action just changed.
  Widget _buildAiFlash(double left, double width) {
    final key = _flashKey;
    final slot = key == null ? null : _timeline.slots[key];
    if (slot == null) {
      return const Positioned(left: 0, top: 0, child: SizedBox.shrink());
    }
    return Positioned(
      key: ValueKey('ai-flash-$_flashTick'),
      top: slot.top + 3,
      left: left,
      width: width,
      height: slot.height - 6,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1500),
          curve: Curves.easeOut,
          builder: (context, t, _) {
            final fade = 1 - t;
            final pop = math.sin(t * math.pi);
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _aiColor.withValues(alpha: fade),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _aiColor.withValues(alpha: 0.5 * fade),
                    blurRadius: 8 + 20 * t,
                    spreadRadius: 6 * t,
                  ),
                ],
              ),
              alignment: Alignment.topRight,
              padding: const EdgeInsets.all(6),
              child: Opacity(
                opacity: fade,
                child: Transform.scale(
                  scale: 0.6 + 0.7 * pop,
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: _aiColor,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Time-of-day greeting with her name, like Today's Care's header.
  Widget _buildWelcomeCard(bool isDark) {
    final pal = context.palette;
    final part = CareDayPart.at(_now);
    final name = MainController.instance.userName.split(' ').first;
    final hour = _now.hour;
    final (icon, iconColor) = hour < 12
        ? (Icons.wb_twilight_rounded, const Color(0xFFF59E0B))
        : hour < 17
        ? (Icons.wb_sunny_rounded, const Color(0xFFFBBF24))
        : hour < 20
        ? (Icons.wb_twilight_rounded, const Color(0xFFF97316))
        : (
            Icons.nightlight_round,
            isDark ? const Color(0xFFA5B4FC) : const Color(0xFF6366F1),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  part.greeting,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: pal.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${name.isNotEmpty ? name : 'Mommy'} 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: pal.textPrimary,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 34, color: iconColor),
        ],
      ),
    );
  }

  Widget _buildTimeline(bool isDark) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    return Stack(
      children: [
        SingleChildScrollView(
          key: _viewportKey,
          controller: _scrollController,
          // The long press owns the gesture while a tile is lifted.
          physics: _drag != null ? const NeverScrollableScrollPhysics() : null,
          padding: const EdgeInsets.only(top: 12, bottom: 112),
          child: SizedBox(
            key: _contentKey,
            // Every child is Positioned, so the Stack must be given its width
            // explicitly or it collapses to nothing.
            width: double.infinity,
            height: _timeline.yFor(24 * 60),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final laneLeft = _timeColumnWidth + 14;
                final laneWidth = constraints.maxWidth - laneLeft - 16;
                final rect = (laneLeft, laneWidth);

                // The dragged tile floats on top of the rest.
                final meals = [
                  ..._meals.where((m) => _mealKey(m) != _drag?.key),
                  ..._meals.where((m) => _mealKey(m) == _drag?.key),
                ];

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final (start, end) in _slotBounds())
                      _buildSlot(start, end, laneLeft, isDark),
                    for (int h = 0; h < 24; h++) _buildHourLabel(h, isDark),
                    for (final slot in _timeline.slots.values)
                      ..._buildSlotTimes(slot, isDark),
                    for (final group in _timeline.groups)
                      ..._buildGroupTimes(group, isDark),
                    for (final session in _sleep)
                      _buildSleepBlock(session, isDark),
                    for (final item in _careItems)
                      _buildCareBlock(item, isDark, rect),
                    for (final meal in meals)
                      _buildMealBlock(meal, isDark, rect),
                    // Above the tiles so it stays visible over them.
                    _buildNowIndicator(),
                    _buildAiFlash(laneLeft, laneWidth),
                    _buildDragTimeBubble(),
                  ],
                );
              },
            ),
          ),
        ),
        _buildTrashZone(),
        if (_drag == null && !_assistantOpen) _buildBottomBar(isDark),
        // Tapping or swiping down outside the popup closes it.
        if (_assistantOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeAssistant,
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) > 0) _closeAssistant();
              },
            ),
          ),
        _buildAssistantSheet(isDark),
        if (!_assistantOpen)
          const FloatingBabySpeechOverlay(
            intentKey: _plannerIntentKey,
            fallbackText: _fallbackText,
            bottom: 0,
          ),
      ],
    );
  }

  /// The hour's label in the time column, on the top edge of its slot.
  Widget _buildHourLabel(int hour, bool isDark) {
    final pal = context.palette;
    final isCurrent = _isToday && hour == _now.hour;
    final minute = hour * 60;
    final top = _timeline.yFor(minute);

    // Beside a tile the column shows the tile's own start and end times
    // instead, so hours there (or close enough to collide) are hidden.
    final groups = _timeline.groups;
    if (groups.any(
      (g) =>
          (minute > g.start && minute < g.end) ||
          (top > _timeline.yFor(g.start) - 16 &&
              top < _timeline.yFor(g.end) + 16),
    )) {
      return const Positioned(left: 0, top: 0, child: SizedBox.shrink());
    }

    return Positioned(
      top: top - 7,
      left: 0,
      width: _timeColumnWidth,
      child: IgnorePointer(
        child: Text(
          _hourLabel(hour),
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? primaryColor : pal.textMuted,
          ),
        ),
      ),
    );
  }

  /// The day cut into slots, one per hour. Tiles sit inside their hour's
  /// slot; hours a tile runs across are joined into one slot.
  List<(int, int)> _slotBounds() {
    final groups = _timeline.groups;
    final bounds = [
      for (int h = 0; h <= 24; h++)
        if (!groups.any((g) => h * 60 > g.start && h * 60 < g.end)) h * 60,
    ];
    return [
      for (var i = 0; i + 1 < bounds.length; i++) (bounds[i], bounds[i + 1]),
    ];
  }

  /// The stretches of [start]–[end] no tile covers, in order. With
  /// [visual], a tile covers as far as it's drawn (short plans are drawn
  /// taller than their time), so the stretches match the empty space.
  List<(int, int)> _freeGaps(int start, int end, {bool visual = false}) {
    int endOf(_Slot slot) => visual
        ? math.max(slot.end, _timeline.minuteAt(slot.top + slot.height).ceil())
        : slot.end;
    final taken = [
      for (final slot in _timeline.slots.values)
        if (endOf(slot) > start && slot.start < end)
          (math.max(slot.start, start), math.min(endOf(slot), end)),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final gaps = <(int, int)>[];
    var cursor = start;
    for (final (s, e) in taken) {
      if (s > cursor) gaps.add((cursor, s));
      cursor = math.max(cursor, e);
    }
    if (cursor < end) gaps.add((cursor, end));
    return gaps;
  }

  /// A rounded slot from [start] to [end]; tapping it opens Add Plan at the
  /// free stretch that was tapped, so a slot part-filled by a plan offers
  /// the time left over.
  Widget _buildSlot(int start, int end, double left, bool isDark) {
    final top = _yFor(start);
    final height = _yFor(end) - top;
    final tileHeight = (height - 4).clamp(0.0, double.infinity).toDouble();
    final gaps = _freeGaps(start, end);

    // The + sits in the tallest stretch left empty below the tiles, if it
    // has room.
    (int, int)? iconGap;
    var iconGapHeight = 0.0;
    for (final gap in _freeGaps(start, end, visual: true)) {
      final h = _yFor(gap.$2) - _yFor(gap.$1);
      if (h > iconGapHeight) {
        iconGap = gap;
        iconGapHeight = h;
      }
    }

    double? tapY;
    void openAtTap() {
      var from = start;
      if (gaps.isNotEmpty) {
        final minute = tapY == null
            ? null
            : _timeline.minuteAt(top + 2 + tapY!);
        // The gap tapped, else the nearest one.
        from = minute == null
            ? gaps.first.$1
            : gaps.reduce((best, gap) {
                double dist((int, int) g) => minute < g.$1
                    ? g.$1 - minute
                    : minute > g.$2
                    ? minute - g.$2
                    : 0;
                return dist(gap) < dist(best) ? gap : best;
              }).$1;
      }
      _showAddPlanSheet(startMinute: from);
    }

    return Positioned(
      top: top + 2,
      left: left,
      right: 16,
      height: tileHeight,
      child: Material(
        color: isDark ? const Color(0xFF1B1B1B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTapDown: (details) => tapY = details.localPosition.dy,
          onTap: _drag != null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  openAtTap();
                },
          // Too short a gap for the icon to fit is still tappable.
          child: iconGap == null || iconGapHeight < 28
              ? null
              : Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top:
                          (_yFor(iconGap.$1) + _yFor(iconGap.$2)) / 2 -
                          (top + 2) -
                          11,
                      child: Icon(
                        Icons.add_rounded,
                        size: 22,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ---- Lanes -------------------------------------------------------------

  String _mealKey(PlannedMeal meal) => 'meal-${meal.type}';
  String _careKey(CareItem item) =>
      TodaysPlanData.careKey(item, _care.hourOf(item));

  /// Care items sit at the top of their hour and count as this long.
  static const int _careMinutes = 30;

  /// [color] as used for text and icons: deepened on light backgrounds so the
  /// bright accent hues stay readable.
  Color _ink(Color color, bool isDark) =>
      isDark ? color : Color.lerp(color, Colors.black, 0.28)!;

  /// Finds tiles whose times overlap and stacks each group one under another
  /// in start order, stretching that part of the day so every tile keeps its
  /// full width and is tall enough for its times. Uses resting positions, so
  /// a tile being dragged doesn't reshuffle the others.
  _Timeline _layoutTimeline() {
    final items =
        <_Slot>[
          for (final meal in _meals)
            _Slot(
              key: _mealKey(meal),
              start: meal.minuteOfDay,
              end: meal.minuteOfDay + meal.durationMinutes,
              color: meal.color,
            ),
          for (final item in _careItems)
            _Slot(
              key: _careKey(item),
              start: _care.hourOf(item) * 60,
              end: _care.hourOf(item) * 60 + _careMinutes,
              color: item.color,
            ),
        ]..sort(
          (a, b) => a.start != b.start
              ? a.start.compareTo(b.start)
              : b.end.compareTo(a.end),
        );

    int shownEnd(_Slot s) =>
        s.end < s.start + _minTileMinutes ? s.start + _minTileMinutes : s.end;

    // Overlapping runs of tiles, in order.
    final runs = <List<_Slot>>[];
    var runEnd = -1;
    for (final item in items) {
      if (item.start >= runEnd) runs.add([]);
      runs.last.add(item);
      if (shownEnd(item) > runEnd) runEnd = shownEnd(item);
    }

    final groups = <_StackGroup>[];
    for (final run in runs) {
      for (final slot in run) {
        slot.height = ((shownEnd(slot) - slot.start) / 60 * _hourHeight)
            .clamp(_tileMinHeight, double.infinity)
            .toDouble();
        slot.stacked = run.length > 1;
      }
      groups.add(
        _StackGroup(
          start: run.first.start,
          end: run.map(shownEnd).reduce((a, b) => a > b ? a : b),
          height: run.fold(0.0, (sum, s) => sum + s.height),
          count: run.length,
        ),
      );
    }

    final timeline = _Timeline(_hourHeight, groups, {
      for (final run in runs)
        for (final slot in run) slot.key: slot,
    });
    for (var i = 0; i < runs.length; i++) {
      var top = timeline.yFor(groups[i].start);
      for (final slot in runs[i]) {
        slot.top = top;
        top += slot.height;
      }
    }
    return timeline;
  }

  /// Top and height of the tile at [key]: its resting slot, or, while it's
  /// being dragged, where [minute] falls, [duration] long.
  (double, double) _tileBox(String key, int minute, int duration) {
    final slot = _timeline.slots[key];
    if (slot != null && key != _drag?.key) {
      return (slot.top + 3, slot.height - 6);
    }
    return (
      _yFor(minute) + 3,
      (duration / 60 * _hourHeight - 6).clamp(28.0, double.infinity).toDouble(),
    );
  }

  /// Whether the tile at [key] has its times shown in the hour column (it's
  /// resting on its own), so the tile itself can leave them out.
  bool _timesInColumn(String key) {
    final slot = _timeline.slots[key];
    return slot != null && !slot.stacked && key != _drag?.key;
  }

  /// "9:00 – 9:30 AM", or "11:30 AM – 12:15 PM" across noon.
  String _rangeLabel(int start, int end) {
    final from = DateTime(2000, 1, 1).add(Duration(minutes: start));
    final to = DateTime(2000, 1, 1).add(Duration(minutes: end % 1440));
    return from.hour < 12 == to.hour < 12
        ? '${DateFormat('h:mm').format(from)} – ${DateFormat('h:mm a').format(to)}'
        : '${DateFormat('h:mm a').format(from)} – ${DateFormat('h:mm a').format(to)}';
  }

  /// A tile's own times at its right edge, for when the column doesn't show
  /// them.
  Widget _tileTime(
    String text,
    Color color,
    bool isDark, {
    bool strong = false,
  }) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Text(
      text,
      maxLines: 1,
      style: TextStyle(
        fontSize: 11,
        fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
        color: strong ? color : context.palette.textMuted,
      ),
    ),
  );

  /// For a stretch holding several tiles, each tile's start time beside it
  /// in the column: the tiles are stacked, so hour labels can't line up
  /// with them.
  List<Widget> _buildGroupTimes(_StackGroup group, bool isDark) {
    if (group.count < 2) return const [];
    return [
      for (final slot in _timeline.slots.values)
        if (slot.stacked &&
            slot.key != _drag?.key &&
            slot.start >= group.start &&
            slot.start < group.end)
          Positioned(
            top: slot.top + 3,
            left: 0,
            width: _timeColumnWidth,
            child: IgnorePointer(
              child: Text(
                _minuteLabel(slot.start),
                textAlign: TextAlign.right,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _ink(slot.color, isDark),
                ),
              ),
            ),
          ),
    ];
  }

  /// Start and end times of a tile resting on its own, in the hour column
  /// beside it.
  List<Widget> _buildSlotTimes(_Slot slot, bool isDark) {
    if (slot.key == _drag?.key || slot.stacked) return const [];
    final muted = context.palette.textMuted;
    Widget label(String text, {required bool start}) => Text(
      text,
      textAlign: TextAlign.right,
      maxLines: 1,
      style: TextStyle(
        fontSize: start ? 11 : 10,
        fontWeight: start ? FontWeight.w700 : FontWeight.w500,
        color: start ? _ink(slot.color, isDark) : muted.withValues(alpha: 0.7),
      ),
    );

    // When the next tile starts right where this one ends, its start time
    // already marks the minute, so the end label would only repeat it.
    final end = slot.end % 1440;
    final endShownByNext =
        _timeline.slots.values.any(
          (other) =>
              other != slot &&
              other.key != _drag?.key &&
              !other.stacked &&
              other.start == end,
        ) ||
        _timeline.groups.any((g) => g.count >= 2 && g.start == end);

    return [
      Positioned(
        top: slot.top + 3,
        left: 0,
        width: _timeColumnWidth,
        child: IgnorePointer(
          child: label(_minuteLabel(slot.start), start: true),
        ),
      ),
      if (!endShownByNext)
        Positioned(
          top: slot.top + slot.height - 17,
          left: 0,
          width: _timeColumnWidth,
          child: IgnorePointer(child: label(_minuteLabel(end), start: false)),
        ),
    ];
  }

  // ---- Dragging ----------------------------------------------------------

  double _yFor(int minuteOfDay) => _timeline.yFor(minuteOfDay);

  String _minuteLabel(int minuteOfDay) => DateFormat(
    'h:mm a',
  ).format(DateTime(2000, 1, 1).add(Duration(minutes: minuteOfDay)));

  void _onDragStart(PlannedMeal meal, LongPressStartDetails d) {
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || _savingDrop) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _drag = _DragItem(
        key: _mealKey(meal),
        minute: meal.minuteOfDay,
        duration: meal.durationMinutes,
        color: meal.color,
        meal: meal,
      );
      _dragMinute = meal.minuteOfDay;
      _grabDy =
          box.globalToLocal(d.globalPosition).dy - _yFor(meal.minuteOfDay);
      _lastPointer = d.globalPosition;
      _overTrash = false;
    });
    _autoScrollTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) => _autoScrollTick(),
    );
  }

  void _onDragUpdate(LongPressMoveUpdateDetails d) {
    _lastPointer = d.globalPosition;
    _updateDragPosition();
  }

  /// Recomputes the dragged tile's time (snapped to 15 min) and whether the
  /// pointer is over the trash zone.
  void _updateDragPosition() {
    final pointer = _lastPointer;
    final box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
    final drag = _drag;
    if (drag == null || pointer == null || box == null) return;

    final top = box.globalToLocal(pointer).dy - _grabDy;
    final raw = _timeline.minuteAt(top).round();
    final snapped = ((raw / _dragSnapMinutes).round() * _dragSnapMinutes)
        .clamp(0, 24 * 60 - drag.duration)
        .toInt();

    final trashBox = _trashKey.currentContext?.findRenderObject() as RenderBox?;
    final overTrash =
        trashBox != null &&
        (trashBox.localToGlobal(Offset.zero) & trashBox.size)
            .inflate(24)
            .contains(pointer);

    if (snapped != _dragMinute || overTrash != _overTrash) {
      if (overTrash && !_overTrash) HapticFeedback.selectionClick();
      setState(() {
        _dragMinute = snapped;
        _overTrash = overTrash;
      });
    }
  }

  /// Scrolls the timeline while the pointer is held near its top/bottom edge.
  void _autoScrollTick() {
    final pointer = _lastPointer;
    final viewport =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (pointer == null || viewport == null || _overTrash) return;
    if (!_scrollController.hasClients) return;

    final local = viewport.globalToLocal(pointer).dy;
    const edge = 72.0;
    double delta = 0;
    if (local < edge) {
      delta = -(edge - local) / 6;
    } else if (local > viewport.size.height - edge) {
      delta = (local - (viewport.size.height - edge)) / 6;
    }
    if (delta == 0) return;

    final position = _scrollController.position;
    final next = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (next != position.pixels) {
      _scrollController.jumpTo(next);
      _updateDragPosition();
    }
  }

  Future<void> _onDragEnd() async {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    final drag = _drag;
    if (drag == null) return;
    final meal = drag.meal;

    if (_overTrash) {
      setState(() => _overTrash = false);
      final removed = await _confirmRemove(meal);
      if (!removed && mounted) setState(() => _drag = null);
      return;
    }

    if (_dragMinute == drag.minute) {
      setState(() => _drag = null);
      return;
    }

    // Keep the tile where it was dropped until the save lands.
    setState(() => _savingDrop = true);
    try {
      await _moveMeal(meal, _dragMinute);
    } finally {
      await _load();
      if (mounted) {
        setState(() {
          _drag = null;
          _savingDrop = false;
        });
      }
    }
  }

  void _onDragCancel() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (!_savingDrop && mounted) {
      setState(() {
        _drag = null;
        _overTrash = false;
      });
    }
  }

  /// Moves [meal] to start at [minuteOfDay], keeping its length: its plan,
  /// and its log's eating time when it's been logged.
  Future<void> _moveMeal(PlannedMeal meal, int minuteOfDay) async {
    if (meal.isPlanned) {
      final shift = minuteOfDay - meal.minuteOfDay;
      await TodaysPlanData.savePlan(
        _day,
        meal.type,
        meal.planStart! + shift,
        meal.planEnd! + shift,
      );
    }

    final vital = meal.logged;
    if (vital == null) return;

    final (eatStart, eatEnd) = meal.eatenWindow!;
    final newAt = DateTime(
      eatStart.year,
      eatStart.month,
      eatStart.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    final newEnd = newAt.add(eatEnd.difference(eatStart));
    await _vitals.updateVitalEntry(
      vitalId: vital.id,
      key: vital.key,
      value: vital.value,
      unit: vital.unit,
      createdAt: newAt,
      userId: MainController.instance.userId,
      data: {
        ...?vital.data,
        'eating_time': DateFormat('h:mm a').format(newAt),
        'time': DateFormat('HH:mm').format(newAt),
        ...MealTimes.toData(newAt, newEnd),
      },
    );
  }

  /// Asks before removing [meal]; a logged meal also has its log deleted.
  /// Returns whether it was removed.
  Future<bool> _confirmRemove(PlannedMeal meal) async {
    final pal = context.palette;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: pal.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove ${meal.title}?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            color: pal.textPrimary,
          ),
        ),
        content: Text(
          meal.isLogged
              ? "This deletes the logged meal and removes it from today's plan."
              : "This removes it from today's plan.",
          style: TextStyle(color: pal.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    setState(() => _savingDrop = true);
    try {
      final vital = meal.logged;
      if (vital != null) {
        await _vitals.deleteVital(vital.id, createdAt: vital.createdAt);
      }
      await TodaysPlanData.removePlan(_day, meal.type);
    } finally {
      await _load();
      if (mounted) {
        setState(() {
          _drag = null;
          _savingDrop = false;
        });
      }
    }
    return true;
  }

  // ---- Tapping a tile ----------------------------------------------------

  /// A meal or activity's actions: log (or edit) the meal, change its time,
  /// or take it off the day.
  Future<void> _openTileSheet(PlannedMeal meal) async {
    HapticFeedback.lightImpact();
    final pal = context.palette;
    final isDark = pal.isDark;
    final color = _ink(meal.color, isDark);

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: pal.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle(isDark)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: meal.color.withValues(alpha: isDark ? 0.22 : 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(meal.icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal.title,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: pal.textPrimary,
                          ),
                        ),
                        Text(
                          _rangeLabel(
                            meal.minuteOfDay,
                            meal.minuteOfDay + meal.durationMinutes,
                          ),
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: pal.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (meal.isLogged)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        meal.calories != null && meal.calories! > 0
                            ? 'Logged · ${meal.calories!.round()} kcal'
                            : 'Logged',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              ),
              if (meal.details.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  meal.details,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: pal.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (meal.careMeal != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(sheetContext).pop('log'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: Icon(
                      meal.isLogged
                          ? Icons.edit_rounded
                          : Icons.restaurant_menu_rounded,
                    ),
                    label: Text(
                      meal.isLogged ? 'Edit what I ate' : 'Log this meal',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  Expanded(
                    child: _sheetAction(
                      icon: Icons.edit_calendar_outlined,
                      label: 'Change time',
                      onPressed: () => Navigator.of(sheetContext).pop('time'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _sheetAction(
                      icon: Icons.delete_outline_rounded,
                      label: 'Remove',
                      color: dangerRed,
                      onPressed: () => Navigator.of(sheetContext).pop('remove'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'log':
        await _logMeal(meal);
      case 'time':
        await _pickPlanTimes(meal.type, from: meal.minuteOfDay, meal: meal);
      case 'remove':
        await _confirmRemove(meal);
    }
  }

  Widget _sheetHandle(bool isDark) => Container(
    width: 36,
    height: 4,
    decoration: BoxDecoration(
      color: isDark ? Colors.white24 : Colors.black12,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _sheetAction({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    final pal = context.palette;
    return SizedBox(
      height: 46,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color ?? pal.textPrimary,
          side: BorderSide(
            color: (color ?? pal.textPrimary).withValues(alpha: 0.3),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, size: 19),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  /// Logs [meal] with Today's Care's meal sheet, or replaces its log when it
  /// has one. It's eaten now today, else at its planned time.
  Future<void> _logMeal(PlannedMeal meal) async {
    final careMeal = meal.careMeal;
    if (careMeal == null) return;
    final log = await CareMealSheet.show(
      context,
      meal: careMeal,
      color: meal.color,
      icon: meal.icon,
    );
    if (log == null || !mounted) return;

    HapticFeedback.mediumImpact();
    final (start, end) =
        meal.eatenWindow ??
        () {
          final now = DateTime.now();
          final start = _isToday
              ? now
              : _day.add(Duration(minutes: meal.planStart ?? 9 * 60));
          return (start, start.add(MealTimes.defaultDuration));
        }();
    final data = TodaysPlannerAiManager.logMealData(
      type: meal.type,
      details: log.details,
      start: start,
      end: end,
      previous: meal.logged?.data,
    );
    final vital = meal.logged;
    final saved = vital != null
        ? await _vitals.updateVitalEntry(
            vitalId: vital.id,
            key: vital.key,
            value: log.calories,
            unit: 'kcal',
            createdAt: start,
            userId: MainController.instance.userId,
            data: data,
          )
        : await _vitals.addVitalEntry(
            key: VitalShapes.food,
            value: log.calories,
            unit: 'kcal',
            createdAt: start,
            userId: MainController.instance.userId,
            data: data,
          );
    await _load();
    if (saved == null) {
      _toast('Could not log ${meal.title.toLowerCase()}', success: false);
    } else {
      _toast('${meal.title} logged · ${log.calories.round()} kcal');
    }
  }

  // ---- Adding plans -------------------------------------------------------

  /// Lets her pick a meal or activity to add. [startMinute] is where the
  /// slot it was opened from starts, if any, and sets the default time.
  Future<void> _showAddPlanSheet({int? startMinute}) async {
    final pal = context.palette;
    final isDark = pal.isDark;

    Widget sectionLabel(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(2, 20, 2, 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: pal.textMuted,
        ),
      ),
    );

    // Options laid out [columns] to a row, padded so every cell is one width.
    Widget optionRow(List<Widget> options, int columns) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < columns; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: i < options.length ? options[i] : const SizedBox.shrink(),
          ),
        ],
      ],
    );

    // Only meals that aren't on the planner (removed from it) are offered;
    // the rest are already there to move or edit. Her own activity joins
    // Today's Care at the hour picked, every day.
    bool missing(String type) => !_meals.any((m) => m.type == type);
    final meals = TodaysPlanData.mealTypes.where(missing).toList();

    final type = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: pal.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _sheetHandle(isDark)),
              const SizedBox(height: 18),
              Text(
                'Add Plan',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: pal.textPrimary,
                ),
              ),
              if (startMinute != null) ...[
                const SizedBox(height: 2),
                Text(
                  'From ${_minuteLabel(startMinute)}',
                  style: TextStyle(fontSize: 13, color: pal.textMuted),
                ),
              ],
              if (meals.isNotEmpty) ...[
                sectionLabel('Meals'),
                optionRow([
                  for (final type in meals) _buildPlanOption(context, type),
                ], 3),
              ],
              sectionLabel('Your care'),
              optionRow([
                _buildOptionCard(
                  context,
                  value: _customActivity,
                  color: primaryColor,
                  icon: Icons.add_task_rounded,
                  title: 'Your own activity',
                  subtitle: 'Added to every day',
                ),
              ], 2),
            ],
          ),
        ),
      ),
    );
    if (type == _customActivity) {
      if (!mounted) return;
      final added = await showAddCareActivity(
        context,
        hour: startMinute == null ? null : startMinute ~/ 60,
      );
      if (added) await _load();
    } else if (type != null) {
      await _pickPlanTimes(type, from: startMinute);
    }
  }

  /// What Add Plan pops with for her own activity.
  static const String _customActivity = 'custom_activity';

  /// The Add Plan card for a meal; pops with its type.
  Widget _buildPlanOption(BuildContext context, String type) =>
      _buildOptionCard(
        context,
        value: type,
        color: TodaysPlanData.mealColor(type),
        icon: TodaysPlanData.mealIcon(type),
        title: TodaysPlanData.mealTitle(type),
        subtitle: 'Not planned',
      );

  /// A tinted, tappable Add Plan card; pops with [value].
  Widget _buildOptionCard(
    BuildContext context, {
    required String value,
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final pal = context.palette;
    final isDark = pal.isDark;
    return Material(
      color: color.withValues(alpha: isDark ? 0.14 : 0.09),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(value),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.22 : 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _ink(color, isDark), size: 19),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: pal.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: pal.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Asks for a start and end time for [type] and saves them as the day's
  /// plan (moving the log too when [meal] has been logged). Defaults to its
  /// reminder time, or [from] when given, keeping the plan's length.
  Future<void> _pickPlanTimes(
    String type, {
    int? from,
    PlannedMeal? meal,
  }) async {
    final existing = meal ?? _meals.firstWhereOrNull((m) => m.type == type);
    final plannedStart =
        existing?.minuteOfDay ?? TodaysPlanData.defaultStart(type);
    final length =
        existing?.durationMinutes ?? TodaysPlanData.defaultPlanMinutes;
    final defaultStart = from ?? plannedStart;

    TimeOfDay toTime(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);
    final title = TodaysPlanData.mealTitle(type);

    final start = await showTimePicker(
      context: context,
      initialTime: toTime(defaultStart),
      helpText: '$title · Start time',
    );
    if (start == null || !mounted) return;
    final startMinute = start.hour * 60 + start.minute;

    final end = await showTimePicker(
      context: context,
      initialTime: toTime((startMinute + length).clamp(0, 1439).toInt()),
      helpText: '$title · End time',
    );
    if (end == null || !mounted) return;
    final endMinute = end.hour * 60 + end.minute;

    if (endMinute <= startMinute) {
      _toast('End time must be after start time', success: false);
      return;
    }

    await TodaysPlanData.savePlan(_day, type, startMinute, endMinute);
    final vital = existing?.logged;
    if (vital != null) {
      final newAt = _day.add(Duration(minutes: startMinute));
      final newEnd = _day.add(Duration(minutes: endMinute));
      await _vitals.updateVitalEntry(
        vitalId: vital.id,
        key: vital.key,
        value: vital.value,
        unit: vital.unit,
        createdAt: newAt,
        userId: MainController.instance.userId,
        data: {
          ...?vital.data,
          'eating_time': DateFormat('h:mm a').format(newAt),
          'time': DateFormat('HH:mm').format(newAt),
          ...MealTimes.toData(newAt, newEnd),
        },
      );
    }
    await _load();
    _scrollToMinute(startMinute);
  }

  void _scrollToMinute(int minuteOfDay) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final target = (_yFor(minuteOfDay) - _hourHeight).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildTrashZone() {
    final visible = _drag != null && !_savingDrop;
    final active = _overTrash;
    const red = Color(0xFFEF4444);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 28,
      child: IgnorePointer(
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1.6),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            child: Center(
              child: AnimatedContainer(
                key: _trashKey,
                duration: const Duration(milliseconds: 140),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: active ? red : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: red.withValues(alpha: 0.6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: active ? Colors.white : red,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      active ? 'Release to remove' : 'Drag here to remove',
                      style: TextStyle(
                        color: active ? Colors.white : red,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Meal tiles --------------------------------------------------------

  /// Tile background: [color] tinted into the page, a little stronger in
  /// light mode so tiles don't wash out against it.
  Color _tileFill(Color color, bool isDark) => Color.alphaBlend(
    color.withValues(alpha: isDark ? 0.15 : 0.18),
    isDark ? const Color(0xFF121212) : Colors.white,
  );

  /// Rounded tile outline; light mode adds a thin edge in the tile's colour.
  ShapeBorder _tileShape(Color color, bool isDark) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: isDark
        ? BorderSide.none
        : BorderSide(color: color.withValues(alpha: 0.35)),
  );

  Widget _buildMealBlock(PlannedMeal meal, bool isDark, (double, double) rect) {
    final pal = context.palette;
    final isDragged = _drag?.key == _mealKey(meal);
    final lifted = isDragged && !_savingDrop;
    final minute = isDragged ? _dragMinute : meal.minuteOfDay;
    final color = _ink(meal.color, isDark);

    final end = (minute + meal.durationMinutes).clamp(0, 1439).toInt();
    final timeText = _rangeLabel(minute, end);

    // Short plans get a single-line tile so nothing overflows.
    final (blockTop, blockHeight) = _tileBox(
      _mealKey(meal),
      minute,
      meal.durationMinutes,
    );
    final timesInColumn = _timesInColumn(_mealKey(meal));
    final compact = blockHeight < 56;
    // A tile sharing its hour with others drops the extras to fit its lane.
    final narrow = rect.$2 < 220;
    final subtitle = meal.isLogged
        ? meal.details
        : meal.isMeal
        ? 'Tap to log'
        : '';
    final showSubtitle = !compact && subtitle.isNotEmpty;

    final tile = Material(
      color: _tileFill(meal.color, isDark),
      elevation: lifted ? 10 : 0,
      shadowColor: Colors.black,
      shape: _tileShape(meal.color, isDark),
      child: InkWell(
        onTap: _drag == null ? () => _openTileSheet(meal) : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(meal.icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            meal.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: pal.textPrimary,
                            ),
                          ),
                        ),
                        if (meal.isLogged && !isDragged) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: color,
                          ),
                        ],
                      ],
                    ),
                    if (showSubtitle) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: pal.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              if (!timesInColumn)
                _tileTime(timeText, color, isDark, strong: isDragged)
              else if (!narrow &&
                  meal.isLogged &&
                  (meal.calories ?? 0) > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '${meal.calories!.round()} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return AnimatedPositioned(
      // Keyed so reordering (dragged tile paints last) keeps the gesture alive.
      key: ValueKey(_mealKey(meal)),
      // Follow the finger directly while dragging; animate snaps otherwise.
      duration: lifted ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      top: blockTop,
      left: rect.$1,
      width: rect.$2,
      height: blockHeight,
      child: GestureDetector(
        onLongPressStart: (d) => _onDragStart(meal, d),
        onLongPressMoveUpdate: _onDragUpdate,
        onLongPressEnd: (_) => _onDragEnd(),
        onLongPressCancel: _onDragCancel,
        child: AnimatedScale(
          scale: lifted ? 1.03 : 1,
          duration: const Duration(milliseconds: 140),
          child: AnimatedOpacity(
            opacity: lifted && _overTrash ? 0.45 : 1,
            duration: const Duration(milliseconds: 120),
            child: tile,
          ),
        ),
      ),
    );
  }

  // ---- Care tiles --------------------------------------------------------

  /// A Today's Care item at its hour. Tapping it does what it does on Home:
  /// log a count, tick it off (or undo), or open its tracker. It stays at
  /// its catalogue hour, so it isn't dragged.
  Widget _buildCareBlock(CareItem item, bool isDark, (double, double) rect) {
    final pal = context.palette;
    final key = _careKey(item);
    final start = _care.hourOf(item) * 60;
    final done = _care.isDone(item);
    final color = _ink(item.color, isDark);
    final (blockTop, blockHeight) = _tileBox(key, start, _careMinutes);
    final compact = blockHeight < 56;
    final subtitle = _care.progressLabel(item) ?? item.subtitle;
    final showSubtitle = !compact && subtitle.isNotEmpty;

    final trailing = switch (item.kind) {
      _ when done => Icons.check_circle_rounded,
      CareActionKind.checkoff => Icons.radio_button_unchecked_rounded,
      CareActionKind.count => Icons.add_circle_outline_rounded,
      _ => Icons.chevron_right_rounded,
    };

    return Positioned(
      key: ValueKey(key),
      top: blockTop,
      left: rect.$1,
      width: rect.$2,
      height: blockHeight,
      child: AnimatedOpacity(
        opacity: done ? 0.7 : 1,
        duration: const Duration(milliseconds: 160),
        child: Material(
          color: _tileFill(item.color, isDark),
          shape: _tileShape(item.color, isDark),
          child: InkWell(
            onTap: _drag == null ? () => _onCareTap(item) : null,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 10, 0),
              child: Row(
                children: [
                  Icon(item.icon, size: 18, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: pal.textPrimary,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: pal.textMuted,
                          ),
                        ),
                        if (showSubtitle) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: pal.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!_timesInColumn(key))
                    _tileTime(_minuteLabel(start), color, isDark),
                  const SizedBox(width: 6),
                  Icon(
                    trailing,
                    size: 20,
                    color: done ? const Color(0xFF10B981) : color,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCareTap(CareItem item) async {
    await CareItemActions.run(
      context,
      item,
      _care,
      onTicked: () {
        if (mounted) setState(() {});
      },
    );
    if (mounted) await _load();
  }

  /// Time bubble in the hour column tracking the dragged tile.
  Widget _buildDragTimeBubble() {
    final drag = _drag;
    if (drag == null || _savingDrop) {
      return const Positioned(left: 0, top: 0, child: SizedBox.shrink());
    }
    return Positioned(
      top: _yFor(_dragMinute) - 9,
      left: 4,
      width: _timeColumnWidth + 4,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: drag.color,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            _minuteLabel(_dragMinute),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  /// Draws a sleep session at its real start/end, clipped to today's hours.
  Widget _buildSleepBlock(SleepSession session, bool isDark) {
    final pal = context.palette;
    final dayStart = _day;
    final dayEnd = dayStart.add(const Duration(days: 1));
    final start = session.start.isBefore(dayStart) ? dayStart : session.start;
    final end = session.end.isAfter(dayEnd) ? dayEnd : session.end;

    final top = _yFor(start.difference(dayStart).inMinutes);
    final height = _yFor(end.difference(dayStart).inMinutes) - top;
    if (height <= 0) {
      return const Positioned(left: 0, top: 0, child: SizedBox.shrink());
    }

    final timeFormat = DateFormat('h:mm a');
    final range =
        '${timeFormat.format(session.start)} – ${timeFormat.format(session.end)}';

    return Positioned(
      top: top + 2,
      left: _timeColumnWidth + 14,
      right: 16,
      height: (height - 4).clamp(4, double.infinity),
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: _sleepColor.withValues(alpha: isDark ? 0.14 : 0.10),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.topLeft,
          // Short naps get no label rather than an overflowing one.
          child: height < 40
              ? null
              : Row(
                  children: [
                    const Icon(
                      Icons.bedtime_rounded,
                      size: 18,
                      color: _sleepColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sleep',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: pal.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '$range · ${SleepUtils.formatSleepDuration(session.minutes)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: pal.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildNowIndicator() {
    if (!_isToday) {
      return const Positioned(left: 0, top: 0, child: SizedBox.shrink());
    }
    final top = _yFor(_now.hour * 60 + _now.minute);

    return Positioned(
      top: top - 5,
      left: _timeColumnWidth + 5,
      right: 12,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.6),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tile being dragged on the timeline.
class _DragItem {
  final String key;

  /// Where the tile rests, in minutes of day, and how long it is.
  final int minute;
  final int duration;
  final Color color;
  final PlannedMeal meal;

  const _DragItem({
    required this.key,
    required this.minute,
    required this.duration,
    required this.color,
    required this.meal,
  });
}

/// A stretch of the day covered by one tile, or by overlapping tiles stacked
/// one under another, drawn [height] tall to fit them.
class _StackGroup {
  final int start;
  final int end;
  final double height;

  /// How many tiles are stacked in the group.
  final int count;

  const _StackGroup({
    required this.start,
    required this.end,
    required this.height,
    required this.count,
  });
}

/// A tile's resting place on the timeline.
class _Slot {
  final String key;
  final int start;
  final int end;
  final Color color;
  double top = 0;
  double height = 0;

  /// Whether the tile shares its stretch with others, so shows its own times
  /// while the column shows the stretch's hours.
  bool stacked = false;

  _Slot({
    required this.key,
    required this.start,
    required this.end,
    required this.color,
  });
}

/// Maps minutes of the day to heights on the timeline and back: an hour is
/// [hourHeight] tall, except where [groups] are stretched to fit their tiles.
class _Timeline {
  final double hourHeight;
  final List<_StackGroup> groups;
  final Map<String, _Slot> slots;

  const _Timeline(this.hourHeight, this.groups, this.slots);

  double get _perMinute => hourHeight / 60;

  double yFor(num minute) {
    var extra = 0.0;
    for (final g in groups) {
      if (minute <= g.start) break;
      final top = g.start * _perMinute + extra;
      if (minute < g.end) {
        return top + (minute - g.start) / (g.end - g.start) * g.height;
      }
      extra += g.height - (g.end - g.start) * _perMinute;
    }
    return minute * _perMinute + extra;
  }

  double minuteAt(double y) {
    var extra = 0.0;
    for (final g in groups) {
      final top = g.start * _perMinute + extra;
      if (y <= top) break;
      if (y < top + g.height) {
        return g.start + (y - top) / g.height * (g.end - g.start);
      }
      extra += g.height - (g.end - g.start) * _perMinute;
    }
    return (y - extra) / _perMinute;
  }
}

enum _AiPhase { idle, listening, thinking, acting, done, failed }

enum _AiStepStatus { pending, running, done, failed }

/// One action from a voice command and how far it has got.
class _AiStep {
  final PlannerAiAction action;
  _AiStepStatus status = _AiStepStatus.pending;
  String? error;

  _AiStep(this.action);
}

/// An action in the voice panel: slides in when it appears, and its icon
/// turns from waiting to a spinner to a tick (or a cross).
class _AiStepRow extends StatelessWidget {
  final _AiStep step;
  final int index;
  final bool isDark;
  final Color accent;

  const _AiStepRow({
    super.key,
    required this.step,
    required this.index,
    required this.isDark,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF10B981);
    final red = Colors.red.shade400;
    final pal = context.palette;
    final muted = pal.textMuted;
    final failed = step.status == _AiStepStatus.failed;

    final Widget status = switch (step.status) {
      _AiStepStatus.pending => Icon(
        Icons.radio_button_unchecked_rounded,
        key: const ValueKey('pending'),
        size: 18,
        color: muted,
      ),
      _AiStepStatus.running => SizedBox(
        key: const ValueKey('running'),
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: accent),
      ),
      _AiStepStatus.done => const Icon(
        Icons.check_circle_rounded,
        key: ValueKey('done'),
        size: 18,
        color: green,
      ),
      _AiStepStatus.failed => Icon(
        Icons.cancel_rounded,
        key: const ValueKey('failed'),
        size: 18,
        color: red,
      ),
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      // Rows arrive one after another.
      duration: Duration(milliseconds: 260 + 90 * index.clamp(0, 6)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(top: 6, right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: switch (step.status) {
            _AiStepStatus.running => accent.withValues(alpha: 0.14),
            _AiStepStatus.done => green.withValues(alpha: 0.10),
            _AiStepStatus.failed => red.withValues(alpha: 0.10),
            _ => (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
          },
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(step.action.icon, size: 16, color: muted),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.action.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: pal.textPrimary,
                      decoration: failed ? TextDecoration.lineThrough : null,
                      decorationColor: muted,
                    ),
                  ),
                  if (failed && step.error != null)
                    Text(
                      step.error!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11.5, color: red),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: status,
            ),
          ],
        ),
      ),
    );
  }
}

/// Gently pulses [child] while it's shown, e.g. the mic while listening.
class _Pulse extends StatefulWidget {
  final Widget child;
  const _Pulse({required this.child});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween(
      begin: 0.85,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
    child: widget.child,
  );
}

/// A gradient ring that sweeps round [child] while [active]; otherwise just
/// [child] at the same size.
class _GradientRing extends StatefulWidget {
  final bool active;
  final double size;
  final Widget child;
  const _GradientRing({
    required this.active,
    required this.size,
    required this.child,
  });

  @override
  State<_GradientRing> createState() => _GradientRingState();
}

class _GradientRingState extends State<_GradientRing>
    with SingleTickerProviderStateMixin {
  static const double _width = 3;
  static const List<Color> _colors = [
    Color(0xFF4285F4),
    Color(0xFFA855F7),
    Color(0xFFEC4899),
    Color(0xFF22D3EE),
    Color(0xFF4285F4),
  ];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _GradientRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inner = SizedBox.square(
      dimension: widget.size - _width * 2,
      child: widget.child,
    );
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.active)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: _colors,
                    transform: GradientRotation(
                      _controller.value * 2 * math.pi,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.35),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
            ),
          inner,
        ],
      ),
    );
  }
}
