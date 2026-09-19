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

  OfflineChatMessage({
    required this.text,
    String? id,
    this.fromUser = false,
    DateTime? timestamp,
    this.imageUrl,
    List<String>? audioUrls,
    List<String>? options,
    this.isSystem = false,
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
  final RxBool isTyping = false.obs;
  final RxString error = ''.obs;
  final RxString langCode = ''.obs;
  final Rxn<DateTime> lastSynced = Rxn<DateTime>();

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

  @override
  void onInit() {
    super.onInit();
    _tts.init();
    _tts.isSpeakingNotifier.addListener(_onSpeakingChanged);
    _tts.isGeneratingNotifier.addListener(_onGeneratingChanged);
    unawaited(_bootstrap());
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
  void _onGeneratingChanged() => isGenerating.value = _tts.isGeneratingNotifier.value;

  /// Reads the cached catalogue and transcript, then downloads a fresh
  /// catalogue if there is none.
  Future<void> _bootstrap() async {
    langCode.value = await AppLanguage.current();
    await _loadCached();
    await _restoreTranscript();

    if (!hasBundle) {
      await sync();
      return;
    }

    // There is a catalogue, so the conversation opens on it straight away —
    // that is the point of caching it. A refresh then runs behind the screen,
    // because otherwise a phone that synced once would answer from that
    // download for ever, and intents added since would never reach her.
    _greet();
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
      actionRunner: OfflineChatbotActions.run,
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
      _delivery++;
      _pending.clear();
      isTyping.value = false;
      _session.clear();
      activeOptions.clear();
      _greet();
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
        .map((m) => {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text})
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

  void _greet() {
    if (messages.isNotEmpty) return;
    messages.add(OfflineChatMessage(text: greetingLine()));
  }

  void resetConversation({bool announce = true}) {
    _delivery++;
    _tts.stop();
    _pending.clear();
    isTyping.value = false;
    _session.clear();
    activeOptions.clear();
    messages.clear();
    if (announce) {
      messages.add(
        OfflineChatMessage(text: 'Conversation reset.', isSystem: true),
      );
    }
    _greet();
    unawaited(_persistTranscript());
  }

  /// Starts a fresh transcript.
  Future<void> createNewChat() async {
    resetConversation(announce: false);
  }

  /// Abandons the turn being answered: whatever segments are still queued
  /// behind a delay, and whatever is being spoken.
  ///
  /// The delivery bump is what discards the reply. A server request already in
  /// flight cannot be recalled, so its answer is dropped when it lands rather
  /// than printed into a conversation the mother has moved on from.
  Future<void> stopCurrentTurn() async {
    if (!isTyping.value) {
      // Nothing being generated — the stop is only about the voice.
      unawaited(_tts.stop());
      return;
    }

    _delivery++;
    _pending.clear();
    isTyping.value = false;
    unawaited(_tts.stop());
    await _persistTranscript();
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

    if (isTyping.value) {
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
    while (_pending.isNotEmpty && !isTyping.value) {
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
      messages.add(
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

    // Whether this turn put anything on screen or did anything at all. A flow
    // that runs out mid-graph can return a reply with no text in it, and the
    // turn would then end in silence.
    var answered = false;

    try {
      final reply = await engine.respond(
        message: message,
        session: _session,
        profile: offlineChatbotProfile(),
      );

      for (final segment in reply.segments) {
        if (segment.delay > 0) {
          await Future.delayed(
            Duration(milliseconds: (segment.delay * 1000).round()),
          );
        }
        if (_delivery != delivery) return;

        // Effects run before the words about them, which is the order the flow
        // put them in: the page has already opened by the time "Opening your
        // reports" appears.
        await _runActions(segment.actions);
        if (_delivery != delivery) return;
        if (segment.actions.isNotEmpty) answered = true;

        if (segment.text.isNotEmpty) {
          answered = true;
          messages.add(
            OfflineChatMessage(
              text: segment.text,
              audioUrls: segment.audioUrls,
              options: segment.options,
            ),
          );
          if (speak) {
            await _speakReplyIfEnabled(
              segment.text,
              audioUrl: segment.audioUrls.isEmpty
                  ? null
                  : segment.audioUrls.first,
            );
          }
        }
        for (final url in segment.imageUrls) {
          answered = true;
          messages.add(OfflineChatMessage(text: '', imageUrl: url));
        }
      }

      if (_delivery != delivery) return;
      if (!answered) {
        messages.add(OfflineChatMessage(text: _nothingToSayMessage));
        if (speak) await _speakReplyIfEnabled(_nothingToSayMessage);
      }
      activeOptions.assignAll(reply.options);
    } catch (e) {
      messages.add(
        OfflineChatMessage(
          text: 'Something went wrong answering that: $e',
          isSystem: true,
        ),
      );
    } finally {
      if (_delivery == delivery) isTyping.value = false;
      await _persistTranscript();
      update();
    }
  }

  /// The last line handed to the voice, so a test can tell "not spoken" from
  /// "spoken into a test binding that has no speech plugin".
  @visibleForTesting
  String? lastSpokenText;

  /// Says a reply aloud, handing the voice the clip this answer carries.
  ///
  /// [audioUrl] is the recording the intent was authored with; [TtsService]
  /// prefers it over anything synthesised and falls back on its own when the
  /// clip cannot be played.
  Future<void> _speakReplyIfEnabled(String text, {String? audioUrl}) async {
    if (BackgroundAudioController.isReady &&
        !BackgroundAudioController.to.isVoiceEnabled.value) {
      debugPrint('Chatbot: Voice is disabled in BackgroundAudioController');
      return;
    }
    if (_isSystemOrErrorText(text)) return;
    lastSpokenText = text;
    debugPrint('Chatbot: Speaking reply: "$text"');
    await _tts.speak(text, audioUrl: _absoluteAudioUrl(audioUrl));
  }

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
