import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:allomom/api/api_routes.dart';
import 'package:allomom/api/chatbot_api.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/offline_chatbot/actions/offline_chatbot_actions.dart';
import 'package:allomom/features/offline_chatbot/data/offline_chatbot_profile.dart';
import 'package:allomom/features/offline_chatbot/engine/offline_chatbot_engine.dart';
import 'package:allomom/features/offline_chatbot/model/offline_chatbot_models.dart';
import 'package:allomom/services/app_language.dart';
import 'package:allomom/services/tts_service.dart';

/// One line in the transcript.
class OfflineChatMessage {
  /// Stable identity, so a line can be recognised again across a rebuild.
  final String id;

  final String text;
  final bool fromUser;
  final DateTime timestamp;
  final String? imageUrl;
  final List<String> audioUrls;
  final List<String> options;

  /// A system note — a reset, or an error — rendered differently from a reply.
  final bool isSystem;

  /// True for a line loaded back from a previous session's saved transcript.
  ///
  /// A message built fresh this turn is false here, which is what lets the
  /// Chat bubble's typewriter effect tell "just said" from "read back from
  /// last time she opened this" — a restored conversation should look exactly
  /// as it did when she left it, not retype itself in front of her.
  final bool restored;

  OfflineChatMessage({
    required this.text,
    String? id,
    this.fromUser = false,
    DateTime? timestamp,
    this.imageUrl,
    List<String>? audioUrls,
    List<String>? options,
    this.isSystem = false,
    this.restored = false,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now(),
       audioUrls = audioUrls ?? const [],
       options = options ?? const [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'from_user': fromUser,
    'timestamp': timestamp.toIso8601String(),
    'image_url': imageUrl,
    'audio_urls': audioUrls,
    'options': options,
    'is_system': isSystem,
  };

  factory OfflineChatMessage.fromJson(Map<String, dynamic> json) =>
      OfflineChatMessage(
        id: json['id']?.toString(),
        text: (json['text'] ?? '').toString(),
        fromUser: json['from_user'] == true,
        timestamp:
            DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
            DateTime.now(),
        imageUrl: json['image_url'] as String?,
        audioUrls: _stringList(json['audio_urls']),
        options: _stringList(json['options']),
        isSystem: json['is_system'] == true,
        restored: true,
      );

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw.map((e) => e.toString()).toList();
  }
}

/// Drives the offline bot behind Ask Allo: downloads the intent catalogue,
/// caches it, and runs every turn on device.
///
/// The only network call this makes is [sync] — and one per `ai` step, when a
/// flow has one. Once a catalogue is cached the conversation works with no
/// connectivity at all: matching, flow traversal, conditions and delays are all
/// local, which is the point for a mother on a patchy rural connection.
class OfflineChatbotController extends GetxController {
  static const String _cacheKey = 'allomom_offline_chatbot_bundle';
  static const String _transcriptKey = 'allomom_offline_chatbot_transcript';

  /// The controller the whole app shares, so the Ask Allo tab and the voice
  /// popup are always talking to the same conversation.
  static OfflineChatbotController get instance =>
      Get.isRegistered<OfflineChatbotController>()
      ? Get.find<OfflineChatbotController>()
      : Get.put(OfflineChatbotController(), permanent: true);

  final RxList<OfflineChatMessage> messages = <OfflineChatMessage>[].obs;
  final RxBool isSyncing = false.obs;
  /// Whether the bot has yet to say anything this turn — the waiting
  /// indicator, and nothing more.
  ///
  /// It ends the moment the turn's first line is on screen. What follows is
  /// delivered line by line behind the voice, and each of those lines is
  /// something to show rather than something to wait for.
  final RxBool isTyping = false.obs;

  /// Whether a turn is still being worked out or delivered.
  ///
  /// Outlives [isTyping]: it stays up until the last line has been said, so
  /// anything she sends meanwhile queues behind the turn instead of racing it.
  final RxBool isBusy = false.obs;

  /// The line the baby is on — the one being read out, or the last one she
  /// said.
  ///
  /// What Ask Allo shows, because the end of the transcript is a different
  /// thing: a turn restored from her last visit is read out again without
  /// being reprinted, and a screen following the transcript would sit on that
  /// turn's last line while the baby is still on its first. The transcript is
  /// the log; this is what is being said.
  final RxnString currentLine = RxnString();
  final RxString error = ''.obs;
  final RxString langCode = ''.obs;
  final Rxn<DateTime> lastSynced = Rxn<DateTime>();

  /// The intent key to automatically trigger on app open if present in the
  /// downloaded intents for the active language. Defaults to 'inital'.
  // ignore: non_constant_identifier_names
  String inital_intent_key = 'initial';

  /// Aliases for convenience and standard naming conventions.
  // ignore: non_constant_identifier_names
  String get initial_intent_key => inital_intent_key;
  // ignore: non_constant_identifier_names
  set initial_intent_key(String val) => inital_intent_key = val;
  String get initialIntentKey => inital_intent_key;
  set initialIntentKey(String val) => inital_intent_key = val;

  /// Options the step the flow is waiting on offers, as tappable chips.
  final RxList<String> activeOptions = <String>[].obs;

  /// Whether Ask Allo is showing the keyboard composer or the voice bar.
  final RxBool isKeyboardMode = false.obs;

  /// Whether the bot is speaking its reply, so the baby can animate along.
  final RxBool isSpeaking = false.obs;

  /// Whether speech or reply is currently being generated/synthesised.
  final RxBool isGenerating = false.obs;

  /// Something the voice input needs to say — that it did not catch the words,
  /// or that the phone cannot listen at all.
  ///
  /// It goes in the baby's speech bubble rather than a snackbar: the bubble is
  /// where she talks, a bar sliding over the bottom of the screen is the app
  /// interrupting, and while the voice sheet is open the bottom is exactly
  /// where she cannot read it.
  final RxString voiceNotice = ''.obs;
  Timer? _voiceNoticeTimer;

  BotBundle? bundle;
  OfflineChatbotEngine? _engine;

  /// Completes once the catalogue cached on the phone has been read (or found
  /// missing), so readers outside the chat can wait for it on a cold start.
  final Completer<void> _cacheLoaded = Completer<void>();
  final BotSession _session = BotSession();
  final TtsService _tts = TtsService();

  /// Identifies the turn being delivered, so a reset or a newer message
  /// abandons whatever segments are still queued behind a delay.
  int _delivery = 0;

  bool get hasBundle => bundle != null && !bundle!.isEmpty;

  /// The languages the catalogue can be downloaded in.
  ///
  /// Read from the bundle already on the phone rather than fetched: the server
  /// ships the language list inside every download, so the picker works with no
  /// connection, and [loadLanguages] only has to reach out when there is no
  /// catalogue yet.
  List<BotLanguage> get availableLanguages =>
      bundle?.languages ?? const <BotLanguage>[];

  int get intentCount => bundle?.intents.length ?? 0;

  String get flowLabel =>
      _session.isActive ? (_session.flowName ?? 'In a flow') : 'Idle';

  Map<String, dynamic> get sessionData => _session.data;

  /// The catalogue being read off the phone (or downloaded), so a screen that
  /// opens before it is ready can wait for it instead of finding no engine.
  Future<void>? _bootstrapFuture;

  /// Completes once there is a catalogue to answer from, if there is going to
  /// be one. Awaiting it is what lets Ask Allo open on the week's message even
  /// when the page is the first thing the app shows.
  Future<void> get ready => _bootstrapFuture ?? Future<void>.value();

  @override
  void onInit() {
    super.onInit();
    _tts.init();
    _tts.isSpeakingNotifier.addListener(_onSpeakingChanged);
    _tts.isGeneratingNotifier.addListener(_onGeneratingChanged);
    _bootstrapFuture = _bootstrap();
    unawaited(_bootstrapFuture!);
  }

  @override
  void onClose() {
    _voiceNoticeTimer?.cancel();
    _tts.isSpeakingNotifier.removeListener(_onSpeakingChanged);
    _tts.isGeneratingNotifier.removeListener(_onGeneratingChanged);
    _tts.stop();
    super.onClose();
  }

  /// Puts a line in the baby's bubble, and takes it away again so the screen
  /// does not sit on a stale complaint.
  void showVoiceNotice(String message) {
    _voiceNoticeTimer?.cancel();
    voiceNotice.value = message;
    _voiceNoticeTimer = Timer(const Duration(seconds: 6), () {
      voiceNotice.value = '';
    });
  }

  void clearVoiceNotice() {
    _voiceNoticeTimer?.cancel();
    voiceNotice.value = '';
  }

  void _onSpeakingChanged() => isSpeaking.value = _tts.isSpeakingNotifier.value;
  void _onGeneratingChanged() =>
      isGenerating.value = _tts.isGeneratingNotifier.value;

  /// Reads the cached catalogue and transcript, then downloads a fresh
  /// catalogue if there is none.
  Future<void> _bootstrap() async {
    langCode.value = await AppLanguage.current();
    await _loadCached();
    if (!_cacheLoaded.isCompleted) _cacheLoaded.complete();
    await _restoreTranscript();

    if (!hasBundle) {
      await sync();
      return;
    }

    // There is a catalogue, so the conversation opens on it straight away —
    // that is the point of caching it. A refresh then runs behind the screen,
    // because otherwise a phone that synced once would answer from that
    // download for ever, and intents added since would never reach her.
    await _startInitialFlowOrGreet();
    unawaited(sync(quiet: true));
  }

  // ── Catalogue ────────────────────────────────────────────────────────────

  Future<void> _loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      _adopt(BotBundle.fromJson(Map<String, dynamic>.from(decoded)));
    } catch (_) {
      // A corrupt cache is not worth surfacing — the next sync replaces it.
    }
  }

  void _adopt(BotBundle next) {
    bundle = next;
    if ((next.langCode ?? '').isNotEmpty) langCode.value = next.langCode!;
    lastSynced.value = next.downloadedAt;
    _engine = OfflineChatbotEngine(
      bundle: next,
      langCode: next.langCode,
      aiResolver: _resolveAi,
    );
  }

  /// Downloads the bot definition and caches it. The one call that needs a
  /// network; everything after it is local.
  ///
  /// [quiet] is for the refresh that runs on launch: a failure there is not
  /// worth a banner, because the catalogue already on the phone still answers
  /// and she never asked for the download in the first place.
  Future<void> sync({String? language, bool quiet = false}) async {
    if (isSyncing.value) return;
    isSyncing.value = true;
    error.value = '';

    try {
      final response = await ChatbotApi.downloadBot(
        langCode: language ?? (langCode.value.isEmpty ? null : langCode.value),
      );

      if (!response.success || response.item is! Map) {
        if (!quiet) {
          error.value = response.networkError
              ? 'No connection — using what is already on this phone.'
              : (response.detail.isEmpty
                    ? 'Could not download AlloBot right now.'
                    : response.detail);
        }
        return;
      }

      final json = Map<String, dynamic>.from(response.item as Map);
      json['downloaded_at'] = DateTime.now().toIso8601String();

      final next = BotBundle.fromJson(json);
      if (next.isEmpty) {
        error.value = 'AlloBot has no intents configured yet.';
      }

      _adopt(next);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(next.toJson()));

      // A half-walked flow belongs to the catalogue that is being replaced, so
      // it is dropped. What was said is not: a sync is housekeeping, and it has
      // no business throwing away the conversation the mother is in.
      //
      // The opening flow is the exception. It runs off the cached catalogue
      // before the refresh has landed, and it is the app's own doing rather
      // than anything she asked for — so leaving it alone meant a flow edited
      // in the builder took two launches to show up: the first downloaded it,
      // the second ran it. It is restarted on the catalogue that just arrived.
      if (!quiet || !_session.isActive || _isInitialIntent(_session.intentKey)) {
        _delivery++;
        _pending.clear();
        _endTurn();
        _session.clear();
        activeOptions.clear();
        await _startInitialFlowOrGreet();
      }
    } catch (e) {
      if (!quiet) error.value = 'Could not download AlloBot: $e';
    } finally {
      isSyncing.value = false;
    }
  }

  /// Forgets the cached catalogue, so the next sync starts clean.
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    bundle = null;
    _engine = null;
    lastSynced.value = null;
    resetConversation(announce: false);
  }

  /// Answers an `ai` step by asking the server's model.
  ///
  /// The one call a conversation makes. Returning null on any failure lets the
  /// engine fall back to its own wording rather than surfacing an HTTP error
  /// mid-sentence, which is also what happens with no connectivity at all.
  Future<String?> _resolveAi(AiStepRequest request) async {
    try {
      final response = await ChatbotApi.runInference(
        prompt: request.prompt,
        system: request.system,
        model: request.model,
        // Sent every time, and used every time unless the step opted out: a
        // follow-up like "I ate it, what do I do?" is unanswerable without
        // the line before it.
        history: _transcript(),
        useEntireHistory: request.useEntireHistory,
        // The catalogue's language, so the answer is written in the one she
        // has been reading.
        langCode: request.langCode?.isNotEmpty == true
            ? request.langCode
            : (langCode.value.isEmpty
                  ? AppLanguage.cachedOrFallback
                  : langCode.value),
        // Who is asking, so a step can pose a plain question and still get an
        // answer that knows which week and whose vitals it is talking about.
        profile: _inferenceProfile(request.profile),
      );

      if (!response.success) return null;

      final item = response.item;
      if (item is Map && item['response'] is String) {
        return item['response'] as String;
      }
      return item is String ? item : null;
    } catch (_) {
      return null;
    }
  }

  /// What the model is told about the mother asking.
  ///
  /// The whole profile, unchanged. It is already the curated view — name, age,
  /// where the pregnancy stands, four vitals, today's date — and carries no
  /// contact details or ids, so there is nothing here to strip before it
  /// reaches a model. Kept as its own step so that stays a decision rather than
  /// an accident.
  Map<String, dynamic> _inferenceProfile(Map<String, dynamic> profile) =>
      profile.isEmpty ? const {} : profile;

  /// The conversation so far, as `{role, content}` entries.
  ///
  /// System notes are left out — they are the app talking about itself, not
  /// part of what was said — and the turn being answered is already the prompt,
  /// so it is not repeated here.
  List<Map<String, String>> _transcript({int limit = 40}) {
    final spoken = messages.where(
      (m) => !m.isSystem && m.text.trim().isNotEmpty,
    );
    final recent = spoken.length > limit
        ? spoken.skip(spoken.length - limit)
        : spoken;

    return recent
        .map(
          (m) => {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text},
        )
        .toList();
  }

  // ── Transcript persistence ───────────────────────────────────────────────

  /// Keeps the last conversation across app launches, so reopening Ask Allo
  /// does not wipe what was just said.
  ///
  /// Only the lines are kept, never the flow state: a half-walked graph cannot
  /// be rewound from a downloaded bundle, so a restored conversation reopens
  /// idle. Failures are swallowed — persistence is a record of the
  /// conversation, not part of answering it.
  Future<void> _persistTranscript() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent = messages.length > 60
          ? messages.sublist(messages.length - 60)
          : messages;
      await prefs.setString(
        _transcriptKey,
        jsonEncode(recent.map((m) => m.toJson()).toList()),
      );
    } catch (_) {
      // Left in memory; the next turn writes it again.
    }
  }

  Future<void> _restoreTranscript() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_transcriptKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      final restored = decoded
          .whereType<Map>()
          .map((e) => OfflineChatMessage.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (restored.isEmpty) return;

      messages.assignAll(restored);

      // The last reply's chips are still the live choice when the conversation
      // is reopened, so they come back with it.
      for (final line in restored.reversed) {
        if (line.fromUser || line.isSystem) continue;
        if (line.options.isNotEmpty) activeOptions.assignAll(line.options);
        break;
      }
    } catch (_) {
      // A transcript that will not load is not worth interrupting the chat for.
    }
  }

  // ── Conversation ─────────────────────────────────────────────────────────

  /// The line Ask Allo opens with: the home screen's greeting, in the bot's
  /// voice, so the page never opens blank.
  String greetingLine() {
    final main = MainController.instance;
    final name = main.userName.trim();
    final hour = DateTime.now().hour;
    final part = hour < 12
        ? 'Good Morning'
        : (hour < 17 ? 'Good Afternoon' : 'Good Evening');
    final salutation = name.isEmpty ? '$part, Amma ❤️' : '$part, $name ❤️';

    if (main.isPregnant) {
      final week = main.currentGestationalWeek;
      final weekLine = week > 0
          ? "You are in week $week. How can I support you and your baby today?"
          : 'How can I support you and your baby today?';
      return '$salutation\n$weekLine';
    }
    if (main.isNewMom) {
      return '$salutation\nHow are you and baby doing today?';
    }
    return '$salutation\nHow can I support you today?';
  }

  /// If [inital_intent_key] is present in the intents for the current language,
  /// starts that intent flow. Otherwise falls back to [_greet].
  Future<void> _startInitialFlowOrGreet() async {
    // Silent here. This runs while the app is starting up, which may be with
    // the mother still on the home screen — the week's message is spoken when
    // she opens Ask Allo and can see who is talking. See [openConversation].
    final started = await startInitialIntentFlow();
    if (!started) {
      _greet();
    }
  }

  /// Opens Ask Allo on the week's message, and lets the baby say it out loud.
  ///
  /// Called every time the page opens, not once per app run: the message is a
  /// greeting, and a greeting that only ever happened during a launch the
  /// mother never saw is one nobody was greeted by. When the bubble is already
  /// on screen from her last visit it is not printed twice — only spoken.
  ///
  /// Spoken out of the step's own recording alone. A clip someone recorded for
  /// week 1 is the baby talking; the phone's synthesised voice reading the
  /// screen aloud the moment a page opens is not, so a step with no clip
  /// simply opens quietly.
  Future<void> openConversation() async {
    await ready;

    // Mid-flow on something else — she asked a question last visit and the
    // flow is waiting on her answer. Restarting the week's message here would
    // throw that away, so the conversation is left exactly where she left it.
    if (_session.isActive && !_isInitialIntent(_session.intentKey)) return;

    await startInitialIntentFlow(speak: true, recordedOnly: true);
  }

  /// Whether [key] names the intent the page opens on, allowing for the
  /// `inital`/`initial` spelling [startIntentByKey] also tolerates.
  bool _isInitialIntent(String? key) {
    if (key == null) return false;
    final target = inital_intent_key.trim();
    return key == target || (target == 'inital' && key == 'initial');
  }

  /// Starts the intent flow for [inital_intent_key] if present for the current language.
  Future<bool> startInitialIntentFlow({
    bool speak = false,
    bool recordedOnly = false,
  }) => startIntentByKey(
    inital_intent_key,
    speak: speak,
    recordedOnly: recordedOnly,
  );

  /// Starts the intent flow with the given [key] if it exists in the catalogue
  /// for the current language.
  ///
  /// Returns true if the intent was found and started, false otherwise.
  /// [recordedOnly] limits [speak] to the clip a step names, leaving the reply
  /// silent when there is no recording rather than synthesising one.
  Future<bool> startIntentByKey(
    String key, {
    bool speak = false,
    bool recordedOnly = false,
  }) async {
    final engine = _engine;
    final trimmedKey = key.trim();
    if (engine == null || trimmedKey.isEmpty) return false;

    final lang = langCode.value.isEmpty ? null : langCode.value;
    final catalogue = bundle?.forLanguage(lang) ?? const <BotIntent>[];

    BotIntent? targetIntent;
    for (final intent in catalogue) {
      if (intent.key == trimmedKey) {
        targetIntent = intent;
        break;
      }
    }
    // Defensive fallback: if 'inital' was searched but authored as 'initial'
    if (targetIntent == null && trimmedKey == 'inital') {
      for (final intent in catalogue) {
        if (intent.key == 'initial') {
          targetIntent = intent;
          break;
        }
      }
    }

    if (targetIntent == null) return false;

    final delivery = ++_delivery;
    activeOptions.clear();
    isTyping.value = true;
    isBusy.value = true;

    try {
      final reply = await engine.runIntent(
        targetIntent,
        session: _session,
        profile: await offlineChatbotProfile(),
      );

      // Already on screen from her last visit: keep the session and its
      // options, but do not print the same lines a second time.
      if (_alreadyOnScreen(_replyLines(reply))) {
        activeOptions.assignAll(reply.options);
        if (_delivery == delivery) _endTurn();
        // The bubbles are already there from her last visit, but she has just
        // opened the page again — printing them twice would be noise, staying
        // silent would mean the baby never greets her a second time.
        if (speak) {
          await _narrate(reply, delivery, recordedOnly: recordedOnly);
        }
        update();
        return true;
      }

      await _deliverReply(
        reply,
        delivery,
        speak: speak,
        recordedOnly: recordedOnly,
      );
      return true;
    } catch (e) {
      if (_delivery == delivery) _endTurn();
      debugPrint('OfflineChatbotController: failed to run intent "$key": $e');
      return false;
    }
  }

  /// Prints a line of a reply and makes it the line the screen is on.
  void _show(OfflineChatMessage message) {
    messages.add(message);
    _speaking(message.text);
    isTyping.value = false;
  }

  /// Moves the screen onto [text], the line now being said.
  void _speaking(String? text) {
    final line = (text ?? '').trim();
    if (line.isNotEmpty) currentLine.value = text;
  }

  /// Drops both waiting indicators at the end of a turn.
  void _endTurn() {
    isTyping.value = false;
    isBusy.value = false;
  }

  /// The lines a turn prints, one per step, in order.
  List<String> _replyLines(BotReply reply) => [
    for (final segment in reply.segments)
      for (final utterance in segment.utterances)
        if (utterance.text.trim().isNotEmpty) utterance.text.trim(),
  ];

  /// Whether the transcript already ends with exactly [lines].
  ///
  /// A turn is printed one message per step, so recognising a turn that is
  /// already on screen means comparing its whole tail rather than only the last
  /// bubble — otherwise the greeting would be printed again every time Ask Allo
  /// is opened.
  bool _alreadyOnScreen(List<String> lines) {
    if (lines.isEmpty) return false;
    final printed = [
      for (final message in messages)
        if (!message.fromUser && !message.isSystem) message.text.trim(),
    ];
    if (printed.length < lines.length) return false;
    final tail = printed.sublist(printed.length - lines.length);
    for (var i = 0; i < lines.length; i++) {
      if (tail[i] != lines[i]) return false;
    }
    return true;
  }

  /// Reads [reply] out step by step without printing it — for the bubbles that
  /// are already on screen from her last visit.
  ///
  /// Each step is waited out before the next one starts, the same gate
  /// [_deliverReply] holds the printed turn behind.
  Future<void> _narrate(
    BotReply reply,
    int delivery, {
    bool recordedOnly = false,
  }) async {
    for (final segment in reply.segments) {
      if (segment.delay > 0) {
        await Future.delayed(
          Duration(milliseconds: (segment.delay * 1000).round()),
        );
        if (_delivery != delivery) return;
      }

      for (final utterance in segment.utterances) {
        if (utterance.isEmpty) continue;

        // The screen moves onto the line before it is read, exactly as
        // printing one does. Without this the bubbles would all be on screen
        // from her last visit while the baby worked through them from the
        // top, and Ask Allo — which shows one line — would sit on the last.
        _speaking(utterance.text);

        final saidAloud = await _speakReplyIfEnabled(
          utterance.text,
          audioUrl: utterance.audioUrl,
          recordedOnly: recordedOnly,
        );
        if (_delivery != delivery) return;

        if (!saidAloud && utterance.text.isNotEmpty) {
          await Future.delayed(_readingPause(utterance.text));
          if (_delivery != delivery) return;
        }
      }
    }
  }

  void _greet() {
    if (messages.isNotEmpty) return;
    _show(OfflineChatMessage(text: greetingLine()));
  }

  /// Clears the conversation: the transcript, the flow she was in, and
  /// whatever was still being said.
  ///
  /// [announce] leaves a note saying so. [restart] decides whether the opening
  /// flow is run into the empty transcript — which is right when the app is
  /// starting the conversation itself, and wrong when the mother asked for a
  /// blank page.
  void resetConversation({bool announce = true, bool restart = true}) {
    _delivery++;
    _tts.stop();
    _pending.clear();
    _endTurn();
    _session.clear();
    activeOptions.clear();
    currentLine.value = null;
    messages.clear();
    if (announce) {
      messages.add(
        OfflineChatMessage(text: 'Conversation reset.', isSystem: true),
      );
    }
    if (restart) {
      unawaited(_startInitialFlowOrGreet());
    }
    unawaited(_persistTranscript());
  }

  /// Starts a fresh transcript, and leaves it empty.
  ///
  /// New Chat is the mother asking for a blank page, so the opening flow is not
  /// replayed into it — she gets the empty state and says the first thing. Ask
  /// Allo still opens on the week's message when she goes there, because that
  /// is the page opening rather than a chat she has just cleared.
  Future<void> createNewChat() async {
    resetConversation(announce: false, restart: false);
  }

  /// Abandons the turn being answered: whatever segments are still queued
  /// behind a delay, and whatever is being spoken.
  ///
  /// The delivery bump is what discards the reply. A server request already in
  /// flight cannot be recalled, so its answer is dropped when it lands rather
  /// than printed into a conversation the mother has moved on from.
  Future<void> stopCurrentTurn() async {
    if (!isBusy.value) {
      // Nothing being generated — the stop is only about the voice.
      unawaited(_tts.stop());
      return;
    }

    _delivery++;
    _pending.clear();
    _endTurn();
    unawaited(_tts.stop());
    await _persistTranscript();
  }

  /// Silences the line being read without abandoning the turn.
  ///
  /// The counterpart to [stopCurrentTurn]: that one throws the whole reply
  /// away, this one only cuts the narration short. The delivery loop is gated
  /// on the voice stopping, however it stopped, so this moves the flow on to
  /// its next step rather than leaving it stuck behind a line she has heard
  /// enough of.
  Future<void> skipNarration() async {
    await _tts.stop();
  }

  /// Messages sent while the previous one was still being answered, oldest
  /// first. Each is answered in turn once the one in flight finishes.
  final List<({String text, bool speak})> _pending = [];

  /// What a turn says when it produced nothing at all — rather than leaving
  /// the mother looking at her own message with no reply under it.
  static const String _nothingToSayMessage =
      "I'm sorry, I didn't catch that. Could you say it another way?";

  /// Answers a message locally and delivers the reply's segments in order,
  /// honouring the pause each one carries so a delay step reads as a real gap
  /// between two bubbles.
  ///
  /// [speak] is the caller's call, not a setting: Ask Allo is a conversation
  /// held out loud and reads the answer back, Chat is a transcript being read,
  /// and a phone that starts talking while she is reading is an interruption.
  ///
  /// A message sent while the previous one is still being answered is queued,
  /// not dropped. It used to be dropped: the composer had already cleared the
  /// field by the time this refused it, so the message vanished with no reply
  /// and no trace — and an `ai` step can hold a turn open for a minute or more,
  /// which is a long window to lose everything typed into.
  Future<void> send(String text, {bool speak = true}) async {
    final message = text.trim();
    if (message.isEmpty) return;

    // Her own words supersede whatever the voice input was complaining about,
    // including when there is no catalogue yet and this turn ends in a note.
    clearVoiceNotice();

    // The message appears the moment she sends it, answered now or queued.
    messages.add(OfflineChatMessage(text: message, fromUser: true));

    if (isBusy.value) {
      _pending.add((text: message, speak: speak));
      return;
    }

    await _answer(message, speak: speak);
    await _drainPending();
  }

  /// Answers whatever was typed while a turn was in flight, in order.
  ///
  /// A loop rather than recursion through [send]: the user's message is
  /// already in the transcript, and a long queue should not nest.
  Future<void> _drainPending() async {
    while (_pending.isNotEmpty && !isBusy.value) {
      final next = _pending.removeAt(0);
      await _answer(next.text, speak: next.speak);
    }
  }

  /// Runs one turn. The user's message is already on screen by now.
  Future<void> _answer(String message, {bool speak = true}) async {
    // Whatever is being said belongs to the previous turn. Not awaited: the
    // stop is a platform round-trip, and the mother's own message should not
    // wait on it to appear.
    unawaited(_tts.stop());

    final engine = _engine;
    if (engine == null) {
      _pending.clear();
      _show(
        OfflineChatMessage(
          text: 'AlloBot is not downloaded yet. Tap sync to fetch it.',
          isSystem: true,
        ),
      );
      return;
    }

    final delivery = ++_delivery;
    activeOptions.clear();
    isTyping.value = true;
    isBusy.value = true;

    try {
      final reply = await engine.respond(
        message: message,
        session: _session,
        profile: await offlineChatbotProfile(),
      );
      await _deliverReply(reply, delivery, speak: speak);
    } catch (e) {
      _show(
        OfflineChatMessage(
          text: 'Something went wrong answering that: $e',
          isSystem: true,
        ),
      );
      if (_delivery == delivery) _endTurn();
      await _persistTranscript();
      update();
    }
  }

  /// Delivers a [BotReply]'s segments, pauses, and actions to the transcript.
  ///
  /// One step at a time, and the next one does not start until the current
  /// one has finished being read aloud. A flow that redirects or chains steps
  /// produces several segments in a single turn, and printing them all at once
  /// meant each new line cut the last one off mid-word — every [TtsService]
  /// utterance stops the one before it — so only the last bubble of a turn was
  /// ever heard. See [TtsService.speakAndWait]; a manual stop opens that gate
  /// as well, so nothing here waits on a voice the mother has silenced.
  Future<void> _deliverReply(
    BotReply reply,
    int delivery, {
    bool speak = false,
    bool recordedOnly = false,
  }) async {
    var answered = false;

    // Printing anything ends the wait. From here the turn arrives line by line
    // behind the voice, and the screen has to show those lines — Ask Allo
    // shows the latest one and nothing else, so leaving the waiting indicator
    // up would hide every line but the last.
    void show(OfflineChatMessage message) {
      _show(message);
      answered = true;
    }

    try {
      for (final segment in reply.segments) {
        if (segment.delay > 0) {
          await Future.delayed(
            Duration(milliseconds: (segment.delay * 1000).round()),
          );
        }
        if (_delivery != delivery) return;

        // One message per step, not one per bubble. Two steps that ran back to
        // back are two things the baby said, and running them together into a
        // paragraph loses where one ended and the next began — a greeting and
        // the flow it redirects into should read as two messages.
        //
        // Printed and then read out one at a time, so the words appear as they
        // are spoken rather than all at once ahead of the voice.
        final spoken = [
          for (final utterance in segment.utterances)
            if (!utterance.isEmpty) utterance,
        ];
        // The choices belong to the step the flow is waiting on, so they ride
        // on the last message this part of the turn actually prints — not on a
        // step that only carried a recording and no words.
        final lastPrinted = spoken.lastIndexWhere((u) => u.text.isNotEmpty);

        for (var i = 0; i < spoken.length; i++) {
          final utterance = spoken[i];

          if (utterance.text.isNotEmpty) {
            show(
              OfflineChatMessage(
                text: utterance.text,
                audioUrls: utterance.hasAudio ? [utterance.audioUrl!] : const [],
                options: i == lastPrinted ? segment.options : const [],
              ),
            );
          }

          if (speak) {
            final saidAloud = await _speakReplyIfEnabled(
              utterance.text,
              audioUrl: utterance.audioUrl,
              recordedOnly: recordedOnly,
            );
            // She may have sent something else, or reset, while it was being
            // read; the rest of this reply belongs to a turn she has left.
            if (_delivery != delivery) return;

            // Nothing was heard — the voice is off, or this step has no
            // recording to play. The step still gets its moment, so the turn
            // reads as a conversation rather than arriving all at once.
            if (!saidAloud && utterance.text.isNotEmpty) {
              await Future.delayed(_readingPause(utterance.text));
              if (_delivery != delivery) return;
            }
          }
        }
        for (final url in segment.imageUrls) {
          show(OfflineChatMessage(text: '', imageUrl: url));
        }

        // Effects run after the words about them, not before: a step that
        // says "Let me take you to the community" and then navigates used to
        // fire the navigation the instant it was scheduled — often before the
        // line had even finished appearing.
        //
        // [speak] already pays this cost in the loop above — each utterance is
        // awaited through its own playback or [_readingPause] — so the voice
        // has finished by the time we get here. Without a voice (Chat, where
        // every bubble types itself out — see [OfflineChatMessageBubble]'s
        // streaming text) nothing paced the wait, so it is measured the same
        // way the bubble times its own reveal, plus a beat so the move reads
        // as a response to what was just said rather than something that
        // happened to the message mid-word.
        if (segment.actions.isNotEmpty) {
          answered = true;
          final combinedText = spoken.map((u) => u.text).join(' ').trim();
          final pause = speak || combinedText.isEmpty
              ? const Duration(seconds: 1)
              : _textRevealPause(combinedText) + const Duration(seconds: 1);
          await Future.delayed(pause);
          if (_delivery != delivery) return;
          await _runActions(segment.actions);
          if (_delivery != delivery) return;
        }
      }

      if (_delivery != delivery) return;
      if (!answered) {
        show(OfflineChatMessage(text: _nothingToSayMessage));
        if (speak && !recordedOnly) {
          await _speakReplyIfEnabled(_nothingToSayMessage);
        }
      }
      activeOptions.assignAll(reply.options);
    } catch (e) {
      _show(
        OfflineChatMessage(
          text: 'Something went wrong answering that: $e',
          isSystem: true,
        ),
      );
    } finally {
      if (_delivery == delivery) _endTurn();
      await _persistTranscript();
      update();
    }
  }

  /// The last line handed to the voice, so a test can tell "not spoken" from
  /// "spoken into a test binding that has no speech plugin".
  @visibleForTesting
  String? lastSpokenText;

  /// Says a reply aloud, handing the voice the clip this answer carries, and
  /// reports whether it was read at all.
  ///
  /// [audioUrl] is the recording the intent was authored with; [TtsService]
  /// prefers it over anything synthesised and falls back on its own when the
  /// clip cannot be played.
  ///
  /// A caller pacing a turn by its voice needs the return value: a line nobody
  /// heard leaves nothing to wait for, and the step after it would otherwise
  /// arrive in the same frame.
  Future<bool> _speakReplyIfEnabled(
    String text, {
    String? audioUrl,
    bool recordedOnly = false,
  }) async {
    if (BackgroundAudioController.isReady &&
        !BackgroundAudioController.to.isVoiceEnabled.value) {
      debugPrint('Chatbot: Voice is disabled in BackgroundAudioController');
      return false;
    }
    if (_isSystemOrErrorText(text)) return false;
    final clip = _absoluteAudioUrl(audioUrl);
    if (recordedOnly && clip == null) return false;
    lastSpokenText = text;
    debugPrint(
      'Chatbot: Speaking reply: "$text"${clip == null ? '' : ' (clip $clip)'}',
    );
    // Returns when the line has actually been said, not when it started being
    // said, so the caller can hold the flow until then.
    await _tts.speakAndWait(text, audioUrl: clip, recordedOnly: recordedOnly);
    return true;
  }

  /// How long a step stays on its own when there is no voice to pace it.
  ///
  /// Ask Allo shows the latest line and nothing else, so a step that is not
  /// read out would otherwise be replaced by the next one in the same frame
  /// and the mother would only ever see the last of them. Roughly a reading
  /// pace, bounded so a long line does not stall the turn.
  static Duration _readingPause(String text) {
    final words = text.trim().split(RegExp(r'\s+')).length;
    return Duration(milliseconds: (words * 180).clamp(900, 4000));
  }

  /// How long the Chat bubble's typewriter reveal takes for [text].
  ///
  /// Mirrors [botTextRevealDuration] in offline_chat_widgets.dart character
  /// for character — kept as a separate constant rather than importing the
  /// widget, since this is the one number the controller needs from a file
  /// that otherwise belongs entirely to presentation. If that widget's pacing
  /// changes, this needs to change with it.
  static Duration _textRevealPause(String text) =>
      Duration(milliseconds: (text.length * 14).clamp(250, 2200));

  /// Runs the intent filed under [key] on its own — in a fresh session, with
  /// nothing added to the transcript and the conversation's own flow left
  /// where it was — and returns what it says, step by step, with each step's
  /// clip resolved the same way the chat resolves it.
  ///
  /// For screens outside AlloBot that speak an authored flow, like the week
  /// on Home. Looks in her language first, then English. Empty when the
  /// catalogue has no such intent.
  Future<List<({String text, String? audioUrl})>> runIntentDetached(
    String key,
  ) async {
    await _cacheLoaded.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
    final engine = _engine;
    final all = bundle?.intents ?? const <BotIntent>[];
    final trimmed = key.trim();
    if (engine == null || trimmed.isEmpty) return const [];

    final lang = langCode.value.trim().toLowerCase();
    BotIntent? intent;
    for (final candidate in {if (lang.isNotEmpty) lang, 'en', null}) {
      for (final entry in all) {
        if (entry.key != trimmed) continue;
        if (candidate == null || entry.langCode == candidate) {
          intent = entry;
          break;
        }
      }
      if (intent != null) break;
    }
    if (intent == null) return const [];

    try {
      final reply = await engine.runIntent(
        intent,
        session: BotSession(),
        profile: await offlineChatbotProfile(),
      );
      return [
        for (final segment in reply.segments)
          for (final utterance in segment.utterances)
            if (!utterance.isEmpty)
              (
                text: utterance.text.trim(),
                audioUrl: _absoluteAudioUrl(utterance.audioUrl),
              ),
      ];
    } catch (e) {
      debugPrint('Chatbot: could not run "$trimmed" on its own: $e');
      return const [];
    }
  }

  /// Runs one turn of a conversation held outside the chat — in [session],
  /// which the caller owns — and returns the whole reply: its steps, pauses,
  /// clips and the options it ends on. Nothing is added to the transcript and
  /// the chat's own flow is left where it was.
  ///
  /// With [intentKey] the intent filed under it starts (her language first,
  /// then English; `inital`/`initial` both find the page's opening intent).
  /// Otherwise [message] answers whatever [session] is waiting on. Null when
  /// there is no catalogue or no such intent.
  ///
  /// For the AlloBaby card on Home, which runs the same opening flow as Ask
  /// Allo and lets her answer it in place.
  Future<BotReply?> runDetachedTurn({
    required BotSession session,
    String? intentKey,
    String? message,
  }) async {
    await _cacheLoaded.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
    final engine = _engine;
    if (engine == null) return null;
    final profile = await offlineChatbotProfile();

    try {
      final key = intentKey?.trim() ?? '';
      if (key.isEmpty) {
        final text = message?.trim() ?? '';
        if (text.isEmpty) return null;
        return await engine.respond(
          message: text,
          session: session,
          profile: profile,
        );
      }

      final all = bundle?.intents ?? const <BotIntent>[];
      final keys = {key, if (key == 'inital') 'initial'};
      final lang = langCode.value.trim().toLowerCase();
      BotIntent? intent;
      for (final candidate in {if (lang.isNotEmpty) lang, 'en', null}) {
        for (final entry in all) {
          if (!keys.contains(entry.key)) continue;
          if (candidate == null || entry.langCode == candidate) {
            intent = entry;
            break;
          }
        }
        if (intent != null) break;
      }
      if (intent == null) return null;
      return await engine.runIntent(intent, session: session, profile: profile);
    } catch (e) {
      debugPrint('Chatbot: detached turn failed: $e');
      return null;
    }
  }

  /// A step's clip as something the player can open: a server-relative path
  /// gets the API host in front of it.
  static String? resolveAudioUrl(String? url) => _absoluteAudioUrl(url);

  /// The audio-library entry filed under [key] in [lang], or the English one
  /// when that language has none. Its transcription is the line's text and its
  /// URL the recording, so a key alone is enough to show and voice a line.
  ///
  /// Waits briefly for the cached catalogue on a cold start; null when the
  /// library has no such key.
  Future<BotAudio?> libraryAudio(String key, String lang) async {
    await _cacheLoaded.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
    return libraryAudioNow(key, lang);
  }

  /// [libraryAudio] without waiting: whatever the catalogue in memory holds.
  BotAudio? libraryAudioNow(String key, String lang) {
    final audios = bundle?.audios ?? const <BotAudio>[];
    final clean = lang.trim().toLowerCase();
    for (final candidate in {clean, 'en'}) {
      for (final audio in audios) {
        if (audio.key == key && audio.langCode.toLowerCase() == candidate) {
          return audio;
        }
      }
    }
    return null;
  }

  /// The playable URL of [key]'s library clip in [lang], when the catalogue
  /// has one.
  String? libraryAudioUrl(String key, String lang) =>
      _absoluteAudioUrl(libraryAudioNow(key, lang)?.url);

  /// Absolutises a clip path from the catalogue.
  ///
  /// The sync bundle stores whatever was uploaded: a full URL for a clip on
  /// Firebase, but a bare `/media/...` path for one served by the API — which
  /// no player can open on its own.
  static String? _absoluteAudioUrl(String? url) {
    final clean = url?.trim() ?? '';
    if (clean.isEmpty) return null;
    if (!clean.startsWith('/')) return clean;
    final base = ApiRoutes.instance.baseUrl;
    return base.endsWith('/')
        ? '${base.substring(0, base.length - 1)}$clean'
        : '$base$clean';
  }

  bool _isSystemOrErrorText(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return true;

    final lower = clean.toLowerCase();
    if (clean == aiUnavailableMessage ||
        lower.contains('i could not reach the assistant')) {
      return true;
    }
    return lower.startsWith('error:') ||
        lower.startsWith('error executing') ||
        lower.contains('ai step failed') ||
        lower.startsWith('something went wrong') ||
        lower.startsWith('this version cannot perform') ||
        lower.startsWith('allobot is not downloaded yet');
  }

  /// Performs a segment's side effects, surfacing only what went wrong.
  ///
  /// A flow says its own "done" message in a text step, so a successful action
  /// stays silent; a failure or an action this app version does not know about
  /// becomes a system line, because silently doing nothing would leave the
  /// flow's next message claiming something that never happened.
  Future<void> _runActions(List<Map<String, dynamic>> actions) async {
    for (final action in actions) {
      if (action['executed'] == true) {
        final dynamic res = action['result'];
        if (res is ActionResult && !res.handled) {
          messages.add(
            OfflineChatMessage(
              text: 'This version cannot perform "${action['name']}" yet.',
              isSystem: true,
            ),
          );
        } else if (res is ActionResult &&
            res.message != null &&
            res.message!.isNotEmpty) {
          messages.add(OfflineChatMessage(text: res.message!, isSystem: true));
        }
        continue;
      }

      final name = action['name']?.toString();
      final result = await OfflineChatbotActions.run(name, action['data']);

      if (!result.handled) {
        messages.add(
          OfflineChatMessage(
            text: 'This version cannot perform "$name" yet.',
            isSystem: true,
          ),
        );
        continue;
      }
      if (result.data.isNotEmpty) {
        _session.data.addAll(result.data);
      }
      if (result.message != null && result.message!.isNotEmpty) {
        messages.add(OfflineChatMessage(text: result.message!, isSystem: true));
      }
    }
  }

  /// Fetches the language list when there is no catalogue to read it from.
  Future<void> loadLanguages() async {
    if (availableLanguages.isNotEmpty) return;
    try {
      final response = await ChatbotApi.getLanguages();
      if (!response.success || response.items is! List) return;
      final fetched = (response.items as List)
          .whereType<Map>()
          .map((e) => BotLanguage.fromJson(Map<String, dynamic>.from(e)))
          .where((l) => l.code.isNotEmpty)
          .toList();
      if (fetched.isEmpty) return;
      // Kept on the bundle so the picker and the download agree on one list.
      bundle = BotBundle(
        version: bundle?.version ?? 1,
        langCode: bundle?.langCode,
        downloadedAt: bundle?.downloadedAt,
        languages: fetched,
        intents: bundle?.intents ?? const [],
        audios: bundle?.audios ?? const [],
      );
      update();
    } catch (_) {
      // Without a list the picker simply shows what the bundle already had.
    }
  }

  /// Switches the catalogue to another language and downloads it.
  ///
  /// The whole catalogue is per-language, so this is a re-download rather than
  /// a filter — and the conversation starts again, because the intents that
  /// answered the old one are gone.
  Future<void> setLanguage(String code) async {
    final next = code.trim();
    if (next.isEmpty || next == langCode.value) return;

    langCode.value = next;
    await AppLanguage.save(next);
    await sync(language: next);
  }

  /// Trigger phrases the downloaded catalogue answers to, for a quick hint.
  ///
  /// At most one phrase per intent, so the suggestions always stand for
  /// different capabilities rather than four wordings of the same one. Pass
  /// [randomize] to shuffle, which is what the landing view does so the chips
  /// are not the same six every time.
  List<String> sampleTriggers({int limit = 8, bool randomize = false}) {
    final catalogue = List<BotIntent>.from(
      bundle?.forLanguage(langCode.value.isEmpty ? null : langCode.value) ??
          const <BotIntent>[],
    );
    if (randomize) catalogue.shuffle();

    final phrases = <String>[];
    for (final intent in catalogue) {
      if (intent.isFallback) continue;
      final examples = List<String>.from(intent.examples);
      if (randomize) examples.shuffle();
      for (final example in examples) {
        final trimmed = example.trim();
        // A phrase with a {placeholder} is a template, not something to tap.
        if (trimmed.isEmpty ||
            trimmed.contains('{') ||
            phrases.contains(trimmed)) {
          continue;
        }
        phrases.add(trimmed);
        break; // One trigger per intent.
      }
      if (phrases.length >= limit) return phrases;
    }
    return phrases;
  }
}
