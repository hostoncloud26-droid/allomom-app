/// The flow engine, running on device.
///
/// A port of the server's runtime: it renders {variable} templates, evaluates
/// connector conditions, walks the graph and produces a turn as ordered
/// segments, each carrying the pause that precedes it. Nothing here touches the
/// network — the bot definition was downloaded once, and every turn after that
/// is local.
library;

import 'dart:convert';

import 'package:allomom/features/offline_chatbot/engine/offline_matching.dart';
import 'package:allomom/features/offline_chatbot/model/offline_chatbot_models.dart';

/// Templates read the caller-supplied user facts under this reserved key, e.g.
/// {profile.due_date}.
const String profileKey = 'profile';

/// What the user actually typed. `message` is the current turn's text and
/// changes every turn; `trigger_message` is the text that opened the active
/// flow and stays fixed for its duration.
const String messageKey = 'message';
const String triggerMessageKey = 'trigger_message';

/// Shown when the active step offers options but the user said something that
/// matches none of them (and is not an intent trigger either).
const String optionMismatchMessage =
    'Sorry, I could not understand that. Can you repeat?';

/// Seeded placeholders — scaffolding, not something to show a user. A flow
/// still carrying one of these ends silently instead.
const Set<String> placeholderCompletionMessages = {
  'flow completed successfully.',
  'flow completed successfully',
  'flow completed.',
  'flow completed',
  'completed.',
  'completed',
  'done.',
  'done',
};

/// Saved for an `ai` step whose inference could not be reached, so a template
/// reading its save key says something honest instead of leaving the
/// placeholder on screen.
const String aiUnavailableMessage =
    'I could not reach the assistant just now — please try again in a moment.';

/// A delay holds a reply back, so a mistyped step must not be able to stall the
/// conversation indefinitely.
const double maxDelaySeconds = 30.0;

final RegExp _singleBraceVar =
    RegExp(r'\{\s*([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)\s*\}');
final RegExp _doubleBraceVar = RegExp(r'\{\{\s*([^}]+?)\s*\}\}');

/// Replaces {{variable}} placeholders with values from session data.
///
/// Supports `{{name}}`, dotted paths (`{{my_http.status_code}}`), and the
/// single-brace form so variables captured from a trigger phrase like
/// "can i eat {food}" can be reused verbatim in step text. Only keys that
/// actually exist are substituted, so JSON bodies and other literal braces are
/// left untouched, and unknown keys stay as they are.
String renderTemplate(String? text, Map<String, dynamic>? data) {
  if (text == null || text.isEmpty || data == null || data.isEmpty) {
    return text ?? '';
  }

  dynamic resolve(String path) {
    dynamic current = data;
    for (final part in path.split('.')) {
      if (current is Map && current.containsKey(part)) {
        current = current[part];
      } else {
        return null;
      }
    }
    return current;
  }

  String replace(Match match) {
    final value = resolve(match.group(1)!.trim());
    if (value == null) return match.group(0)!;
    return value.toString();
  }

  return text.replaceAllMapped(_doubleBraceVar, replace).replaceAllMapped(
        _singleBraceVar,
        replace,
      );
}

/// Reads a dotted variable path out of session data, e.g. `profile.due_date`.
dynamic resolveConditionPath(String? path, Map<String, dynamic>? sessionData) {
  if (path == null || path.trim().isEmpty || sessionData == null) return null;
  dynamic current = sessionData;
  for (final part in path.trim().split('.')) {
    if (current is Map && current.containsKey(part)) {
      current = current[part];
    } else {
      return null;
    }
  }
  return current;
}

bool _isTruthy(dynamic val) {
  if (val == null) return false;
  if (val is bool) return val;
  if (val is num) return val != 0;
  final s = val.toString().trim().toLowerCase();
  return s == 'true' || s == '1' || s == 'yes' || s == 'y' || s == 't';
}

bool _evaluateClause(
  Map<String, dynamic> clause,
  BotStep? currentStep,
  String? userMessage,
  Map<String, dynamic>? sessionData,
) {
  final op = (clause['operator'] ?? 'equals').toString();

  // An explicit `variable` on the connector wins, which is what lets a start
  // connector (no current step) branch on a trigger-captured value; otherwise
  // fall back to the current step's answer, then the message.
  dynamic valToTest;
  final variable = (clause['variable'] ?? '').toString().trim();
  final saveKey = currentStep?.saveKey;

  if (variable.isNotEmpty) {
    valToTest = resolveConditionPath(variable, sessionData);
  } else if (saveKey != null &&
      saveKey.isNotEmpty &&
      sessionData != null &&
      sessionData.containsKey(saveKey)) {
    valToTest = sessionData[saveKey];
  } else if (userMessage != null) {
    valToTest = userMessage;
  } else if (sessionData != null) {
    valToTest = sessionData[messageKey];
  }

  // "Did we capture anything?" has to be answerable before the null guard,
  // since a missing variable is exactly what these two operators test for.
  final hasValue = valToTest != null && valToTest.toString().trim().isNotEmpty;
  if (op == 'is_set') return hasValue;
  if (op == 'is_empty') return !hasValue;
  if (op == 'is_true') return _isTruthy(valToTest);
  if (op == 'is_false') return !_isTruthy(valToTest);
  if (valToTest == null) return false;

  final target = clause['value'] ?? '';

  // Compare as numbers whenever both sides parse as such — a start connector
  // has no step to declare `question_data_type: number`, so relying on that
  // alone would make `>=` fall through to a string compare.
  final numTest = double.tryParse(valToTest.toString().trim());
  final numTarget = double.tryParse(target.toString().trim());
  if (numTest != null && numTarget != null) {
    switch (op) {
      case 'equals':
        return numTest == numTarget;
      case 'not_equals':
        return numTest != numTarget;
      case 'greater_than':
        return numTest > numTarget;
      case 'less_than':
        return numTest < numTarget;
      case 'greater_than_or_equal':
        return numTest >= numTarget;
      case 'less_than_or_equal':
        return numTest <= numTarget;
    }
  }

  final strTest = valToTest.toString().trim().toLowerCase();
  final strTarget = target.toString().trim().toLowerCase();

  // Compare as booleans whenever target or test value represents a boolean
  if (valToTest is bool || strTarget == 'true' || strTarget == 'false') {
    final boolTest = _isTruthy(valToTest);
    final boolTarget = strTarget == 'true'
        ? true
        : (strTarget == 'false' ? false : _isTruthy(target));
    if (op == 'equals') return boolTest == boolTarget;
    if (op == 'not_equals') return boolTest != boolTarget;
  }

  switch (op) {
    case 'equals':
      return strTest == strTarget;
    case 'not_equals':
      return strTest != strTarget;
    case 'contains':
      return strTest.contains(strTarget);
    case 'not_contains':
      return !strTest.contains(strTarget);
    case 'greater_than':
      return strTest.compareTo(strTarget) > 0;
    case 'less_than':
      return strTest.compareTo(strTarget) < 0;
    case 'greater_than_or_equal':
      return strTest.compareTo(strTarget) >= 0;
    case 'less_than_or_equal':
      return strTest.compareTo(strTarget) <= 0;
  }
  return false;
}

/// True when every clause (`match: all`) or any clause (`match: any`) holds.
bool evaluateConnector(
  BotConnector connector,
  BotStep? currentStep,
  String? userMessage,
  Map<String, dynamic>? sessionData,
) {
  final clauses = connector.conditions;
  if (clauses.isEmpty) return true; // unconditional connector

  final results = clauses
      .map((c) => _evaluateClause(c, currentStep, userMessage, sessionData));
  return connector.matchAny ? results.any((r) => r) : results.every((r) => r);
}

/// How long a delay step waits. Its duration lives in `question` and may be a
/// template, so a flow can pause for a value it collected earlier.
double delaySeconds(BotStep step, Map<String, dynamic>? sessionData) {
  final raw = renderTemplate(step.question, sessionData).trim();
  final seconds = double.tryParse(raw);
  if (seconds == null) return 0.0;
  return seconds.clamp(0.0, maxDelaySeconds).toDouble();
}

List<String> stepOptions(BotStep? step, Map<String, dynamic>? sessionData) {
  if (step == null || step.options.isEmpty) return const [];
  return step.options.map((o) => renderTemplate(o, sessionData)).toList();
}

/// Validates an answer against the step's declared data type.
({bool valid, String? error}) validateInput(String value, String? dataType) {
  if (dataType == null || dataType.isEmpty || dataType == 'text') {
    return (valid: true, error: null);
  }

  final clean = value.trim();
  if (clean.isEmpty) return (valid: false, error: 'Input cannot be empty.');

  switch (dataType) {
    case 'number':
      return double.tryParse(clean) != null
          ? (valid: true, error: null)
          : (valid: false, error: 'Please enter a valid number.');
    case 'email':
      return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(clean)
          ? (valid: true, error: null)
          : (
              valid: false,
              error: 'Please enter a valid email address (e.g. name@domain.com).'
            );
    case 'date':
      return clean.length >= 2
          ? (valid: true, error: null)
          : (
              valid: false,
              error: "Please enter a valid date (e.g. 2026-06-25 or 'tomorrow')."
            );
  }
  return (valid: true, error: null);
}

/// What an `ai` step needs answered.
///
/// The prompt and system instruction arrive already rendered — the engine
/// resolved their {variables} against the session, which is the part that does
/// not need a server.
class AiStepRequest {
  final String prompt;
  final String? system;
  final String? model;

  /// Whether this step sees the conversation so far, which an `ai` step does
  /// unless it was authored to opt out. The transcript is sent either way —
  /// the resolver cannot know which steps want it — and this is what decides
  /// whether it is actually used.
  final bool useEntireHistory;

  /// The language the catalogue is in, so the model answers in the language
  /// the rest of the conversation is written in.
  ///
  /// An authored prompt is written once, usually in English, and every
  /// language's catalogue reuses it — so without this a Tamil conversation got
  /// an English answer the moment it reached an `ai` step.
  final String? langCode;

  /// What is known about the person asking — the same facts every `{profile.*}`
  /// placeholder resolves against.
  ///
  /// Travels with every request so an authored prompt does not have to name
  /// each fact it wants: a step can just ask a question and still get an answer
  /// that knows whose vitals and whose week it is talking about.
  final Map<String, dynamic> profile;

  const AiStepRequest({
    required this.prompt,
    this.system,
    this.model,
    this.useEntireHistory = true,
    this.langCode,
    this.profile = const {},
  });
}

/// Answers an `ai` step. Returns null when the model could not be reached, so
/// the flow can say so rather than printing a broken placeholder.
///
/// Keeping this a callback is what stops the engine from owning an HTTP client:
/// it stays pure and testable, and the app decides where inference comes from.
typedef AiResolver = Future<String?> Function(AiStepRequest request);

/// One thing said, by the one step that said it: its words and the recording
/// that step named.
///
/// A segment is a bubble; its utterances are the steps that filled it. They
/// stay separate because a bubble is read out one step at a time, each waited
/// on before the next begins — and because a step's clip belongs to that
/// step's words, not to whatever else ended up in the same bubble.
class BotUtterance {
  BotUtterance({this.text = '', this.audioUrl});

  String text;
  String? audioUrl;

  bool get hasAudio => (audioUrl ?? '').isNotEmpty;
  bool get isEmpty => text.isEmpty && !hasAudio;
}

/// One message of a turn, and the pause that precedes it.
class BotSegment {
  double delay;

  /// What this bubble says, step by step, in the order the flow said it.
  final List<BotUtterance> utterances;

  final List<String> imageUrls;

  /// Side effects this part of the turn asks the app to perform, in the order
  /// the flow ran them — so a `toggle_theme` before a text step takes effect
  /// before the message announcing it appears.
  final List<Map<String, dynamic>> actions;
  List<String> options;

  BotSegment({
    this.delay = 0,
    List<BotUtterance>? utterances,
    List<String>? imageUrls,
    List<Map<String, dynamic>>? actions,
    List<String>? options,
  })  : utterances = utterances ?? [],
        imageUrls = imageUrls ?? [],
        actions = actions ?? [],
        options = options ?? [];

  /// The bubble's words — every step that spoke into it, run together.
  String get text => utterances
      .where((u) => u.text.isNotEmpty)
      .map((u) => u.text)
      .join('\n\n');

  /// Every clip this bubble carries, in order.
  List<String> get audioUrls =>
      [for (final u in utterances) if (u.hasAudio) u.audioUrl!];
}

/// A turn's answer, as the ordered parts the UI should deliver.
///
/// Text steps and the question a flow lands on become segments. A delay step
/// says nothing — it sets the pause the *next* segment carries, which is what
/// turns "message, wait, message" into distinct bubbles rather than one blob
/// with a stall in front of it. Consecutive messages with no delay between
/// them merge, so a flow without delays reads as a single reply.
class BotReply {
  final List<BotSegment> segments = [];
  final List<Map<String, dynamic>> actions = [];
  double _pendingDelay = 0;

  void wait(double seconds) => _pendingDelay += seconds;

  /// The utterance the step currently running is filling. [endStep] closes it,
  /// so the next step's words and clip cannot land on the step before it.
  BotUtterance? _open;

  BotSegment _current() {
    if (segments.isEmpty || _pendingDelay > 0) {
      segments.add(BotSegment(delay: _pendingDelay));
      _pendingDelay = 0;
      _open = null;
    }
    return segments.last;
  }

  BotUtterance _openUtterance() {
    final part = _open;
    if (part != null) return part;
    final fresh = BotUtterance();
    _current().utterances.add(fresh);
    _open = fresh;
    return fresh;
  }

  /// Adds what the running step says. Its own utterance, so it is read out on
  /// its own even when it shares a bubble with the step before it.
  void say(String? text) {
    if (text == null || text.isEmpty) return;
    final part = _openUtterance();
    part.text = part.text.isEmpty ? text : '${part.text}\n\n$text';
  }

  /// Attaches the running step's clip to what it said. A step naming a second
  /// clip gets a second utterance rather than losing one.
  void addAudio(String? url) {
    if (url == null || url.isEmpty) return;
    final part = _openUtterance();
    if (!part.hasAudio) {
      part.audioUrl = url;
      return;
    }
    _open = null;
    _openUtterance().audioUrl = url;
  }

  /// Marks the end of one step's contribution.
  ///
  /// Without it, a step that says nothing but names a clip would hang that
  /// clip on the previous step's words — and the clip wins over the text, so
  /// that step's line would go unread.
  void endStep() => _open = null;

  void addImage(String? url) {
    if (url != null && url.isNotEmpty) _current().imageUrls.add(url);
  }

  void setOptions(List<String> options) => _current().options = options;

  void addAction(Map<String, dynamic> action) {
    _current().actions.add(action);
    actions.add(action);
  }

  String get text =>
      segments.where((s) => s.text.isNotEmpty).map((s) => s.text).join('\n\n');

  List<String> get options => segments.isEmpty ? const [] : segments.last.options;
}

/// Where a conversation currently stands. Purely in memory — a fresh app run
/// starts a fresh conversation, exactly as the server's session manager does.
class BotSession {
  String? intentKey;

  /// The language of the intent this flow came from. A catalogue downloaded
  /// for one language makes this the same everywhere, but a bundle holding
  /// several is what decides which recording an `audio_key` resolves to.
  String? intentLang;
  String? flowName;
  String? currentStepRef;
  BotFlow? flow;
  Map<String, dynamic> data = {};

  bool get isActive => flow != null && currentStepRef != null;

  void clear() {
    intentKey = null;
    intentLang = null;
    flowName = null;
    currentStepRef = null;
    flow = null;
    data = {};
  }
}

/// Runs a flow graph and matches triggers, entirely on device.
class OfflineChatbotEngine {
  OfflineChatbotEngine({
    required this.bundle,
    this.langCode,
    this.aiResolver,
  });

  final BotBundle bundle;
  final String? langCode;

  /// Where `ai` steps get their answers. Null leaves them unanswered, which is
  /// what a build with no inference available should do.
  final AiResolver? aiResolver;

  /// Where the audio library is served from. A clip filed under a key lives at
  /// `<base>/<lang_code>/<key>.mp3` — so
  /// `https://audio.savemom.app/allomom/en/pregnant_week10_english.mp3`.
  static const String audioLibraryBase = 'https://audio.savemom.app/allomom';

  /// The language every key is expected to have a recording in, and what a
  /// conversation in some other language falls back to. The same fallback the
  /// server applies, so both sides pick the same clip.
  static const String fallbackAudioLang = 'en';

  /// Clips the downloaded catalogue carries, keyed `<key>|<lang>`. Built once,
  /// on the first step that names a key — most conversations never need it.
  Map<String, String>? _audioIndex;

  /// The clip a step should play, in the language the conversation is in.
  ///
  /// An explicit `audio_url` wins outright: it names one file, chosen against
  /// this one step. Failing that an `audio_key` is looked up in the catalogue's
  /// audio library, and finally resolved by convention — a key is filed under
  /// its language, so the URL can be built without the library having been
  /// synced. A clip missing in the conversation's language falls back to the
  /// English one rather than going silent, and a URL that turns out not to
  /// play is not fatal either: [TtsService] falls back to speaking the text.
  /// [langCode] overrides the catalogue's own language, which is what a bundle
  /// holding several needs; left out, the engine's language is used.
  String? stepAudio(BotStep step, {String? langCode}) {
    final url = step.audioUrl?.trim() ?? '';
    if (url.isNotEmpty) return url;

    final key = step.audioKey?.trim() ?? '';
    if (key.isEmpty) return null;

    final lang = _audioLang(langCode ?? this.langCode);
    final index = _audioIndex ??= {
      for (final audio in bundle.audios)
        if (audio.key.isNotEmpty && audio.url.isNotEmpty)
          '${audio.key}|${audio.langCode}': audio.url,
    };

    for (final candidate in {lang, fallbackAudioLang}) {
      final known = index['$key|$candidate'];
      if (known != null) return known;
    }
    return audioUrlForKey(key, lang);
  }

  /// The library URL a key resolves to in [langCode].
  static String audioUrlForKey(String key, String? langCode) =>
      '$audioLibraryBase/${_audioLang(langCode)}/$key.mp3';

  /// The language a clip is looked up in. "all" is the catalogue's wildcard,
  /// not a language anything is recorded in.
  static String _audioLang(String? code) {
    final clean = (code ?? '').trim().toLowerCase();
    if (clean.isEmpty || clean == 'all') return fallbackAudioLang;
    return clean;
  }

  /// The clip for a step reached inside [session], in that flow's language.
  String? _sessionAudio(BotStep step, BotSession session) =>
      stepAudio(step, langCode: session.intentLang ?? langCode);

  /// Steps that need the network are skipped offline; their save key gets this
  /// marker so a template referencing it renders something honest rather than
  /// leaving `{api_res}` on screen.
  static const Map<String, dynamic> _offlineSkipped = {
    'offline': true,
    'status_code': 0,
    'data': null,
  };

  BotStep? _startStep(
    BotFlow flow,
    String? userMessage,
    Map<String, dynamic>? sessionData,
  ) {
    if (flow.steps.isEmpty) return null;

    // Start connectors name the entry step outright. Conditional ones are tried
    // in the order they were drawn against the trigger message and captured
    // variables; an unconditional one is the else branch.
    final starts = flow.startConnectors
        .where((c) => flow.stepByRef(c.toRef) != null)
        .toList();
    final conditional = starts.where((c) => c.conditions.isNotEmpty).toList();
    final defaults = starts.where((c) => c.conditions.isEmpty).toList();

    for (final conn in conditional) {
      if (evaluateConnector(conn, null, userMessage, sessionData)) {
        return flow.stepByRef(conn.toRef);
      }
    }
    if (defaults.isNotEmpty) return flow.stepByRef(defaults.first.toRef);
    // Every start connector was conditional and none matched: the first is a
    // better guess than inferring, since the author did point at an entry.
    if (conditional.isNotEmpty) return flow.stepByRef(conditional.first.toRef);

    // Otherwise infer it: the step nothing points at.
    final incoming = flow.connectors
        .where((c) => c.toRef != null)
        .map((c) => c.toRef)
        .toSet();
    final candidates =
        flow.steps.where((s) => !incoming.contains(s.ref)).toList();
    if (candidates.isNotEmpty) return candidates.first;

    // Circular flow fallback.
    return flow.steps.first;
  }

  BotStep? _nextStep(
    BotFlow flow,
    BotStep current,
    String? userMessage,
    Map<String, dynamic>? sessionData,
  ) {
    final outgoing =
        flow.outgoing(current.ref).where((c) => c.toRef != null).toList();
    final conditional = outgoing.where((c) => c.conditions.isNotEmpty).toList();
    final defaults = outgoing.where((c) => c.conditions.isEmpty).toList();

    for (final conn in conditional) {
      if (evaluateConnector(conn, current, userMessage, sessionData)) {
        return flow.stepByRef(conn.toRef);
      }
    }
    if (defaults.isNotEmpty) return flow.stepByRef(defaults.first.toRef);
    return null;
  }

  Map<String, dynamic> _actionPayload(
      BotStep step, Map<String, dynamic>? sessionData) {
    final name = renderTemplate(step.actionName ?? '', sessionData);
    dynamic data = <String, dynamic>{};
    final raw = step.actionData;

    if (raw is String && raw.trim().isNotEmpty) {
      final interpolated = renderTemplate(raw, sessionData);
      try {
        data = jsonDecode(interpolated);
      } catch (_) {
        final match = RegExp(r'''["']?mode["']?\s*:\s*["']?(\w+)["']?''',
                caseSensitive: false)
            .firstMatch(interpolated);
        data = match != null
            ? {'mode': match.group(1)!.toLowerCase()}
            : interpolated;
      }
    } else if (raw is Map) {
      final out = <String, dynamic>{};
      raw.forEach((key, value) {
        if (value is String) {
          final interpolated = renderTemplate(value, sessionData);
          try {
            out[key.toString()] = jsonDecode(interpolated);
          } catch (_) {
            out[key.toString()] = interpolated;
          }
        } else {
          out[key.toString()] = value;
        }
      });
      data = out;
    } else if (raw != null) {
      data = raw;
    }

    return {'name': name, 'data': data};
  }

  /// Runs an `ai` step's inference, or reports that it could not.
  Future<String> _runAi(BotStep step, BotSession session) async {
    final prompt = renderTemplate(step.aiPrompt ?? '', session.data).trim();
    if (prompt.isEmpty) return '';

    final resolver = aiResolver;
    if (resolver == null) return aiUnavailableMessage;

    final system = renderTemplate(step.aiSystem ?? '', session.data).trim();

    try {
      final raw = session.data[profileKey];

      final answer = await resolver(AiStepRequest(
        prompt: prompt,
        system: system.isEmpty ? null : system,
        model: step.aiModel,
        useEntireHistory: step.usesEntireHistory,
        langCode: langCode,
        profile: raw is Map
            ? Map<String, dynamic>.from(raw)
            : const <String, dynamic>{},
      ));
      final text = answer?.trim() ?? '';
      return text.isEmpty ? aiUnavailableMessage : text;
    } catch (_) {
      return aiUnavailableMessage;
    }
  }

  void _save(BotSession session, String? key, dynamic value) {
    if (key != null && key.isNotEmpty) session.data[key] = value;
  }

  /// Runs every self-driving step, filling [reply], until one needs the user.
  /// Returns the step the flow is now waiting on, or null when it ran to the end.
  Future<BotStep?> _traverse(
    BotSession session,
    BotStep? start,
    BotReply reply,
  ) async {
    // Keyed by flow *and* ref, not ref alone. A step's ref is only unique
    // inside its own flow — every flow numbers its steps s1, s2, s3 — so an
    // `intent` step handing over to another flow used to land on that flow's
    // s1, find "s1" already visited from the flow it just left, and stop dead:
    // the redirect appeared to do nothing at all. Scoping the key to the flow
    // keeps the loop guard (a flow that redirects back into itself still stops
    // at the step it has already run) without one flow shadowing another.
    final visited = <String>{};
    var curr = start;

    while (curr != null && curr.isAutomatic) {
      final mark = '${identityHashCode(session.flow)}#${curr.ref}';
      // Already walked this turn: the graph loops. The flow ends here rather
      // than landing on the step, which would print it a second time and then
      // leave the session waiting on a step that takes no answer.
      if (visited.contains(mark)) return null;
      visited.add(mark);

      // A step offering options waits for a selection instead of running on.
      // An ai step is exempt: its options carry the history flag, not choices.
      if (curr.options.isNotEmpty &&
          curr.type != 'intent' &&
          curr.type != 'ai') {
        break;
      }

      switch (curr.type) {
        case 'text':
          reply.say(renderTemplate(curr.question, session.data));
          break;
        case 'delay':
          // A delay is a pause, not a message: it holds back whatever the flow
          // says next and contributes nothing of its own.
          reply.wait(delaySeconds(curr, session.data));
          break;
        case 'image':
          reply.addImage(renderTemplate(curr.imageUrl ?? '', session.data));
          break;
        case 'action':
        case 'custom_action':
          // Queued for the controller to run once this turn's reply has
          // actually been shown, not run here: this step is reached while
          // walking the graph to work out what the turn *says*, well before
          // anything is on screen. Running a navigation action's side effect
          // this early is what used to send the mother to another page the
          // instant the flow was matched — before she had even seen the line
          // introducing it.
          final payload = _actionPayload(curr, session.data);
          _save(session, curr.saveKey, payload);
          reply.addAction(payload);
          break;
        case 'ai':
          _save(session, curr.saveKey, await _runAi(curr, session));
          break;
        case 'http':
          // The one step this engine cannot do: it has no HTTP client, by
          // design. The flow carries on rather than stalling, and the save key
          // gets a response-shaped marker so `{api_res.status_code}` still
          // resolves to something a condition can read.
          _save(session, curr.saveKey, _offlineSkipped);
          break;
        case 'intent':
          final target = _redirectTarget(curr);
          if (target != null) {
            if (target.type == 'response') {
              reply.say(renderTemplate(target.response?.message, session.data));
              reply.addAudio(target.response?.audioUrl);
              session.clear();
              return null;
            }
            if (target.type == 'flow' && target.flow != null) {
              final first = _startStep(
                  target.flow!, session.data[messageKey]?.toString(), session.data);
              if (first != null) {
                session.intentKey = target.key;
                session.intentLang = target.langCode;
                session.flow = target.flow;
                session.flowName = target.flow!.name;
                session.currentStepRef = first.ref;
                curr = first;
                continue;
              }
              session.clear();
              return null;
            }
          }
          break;
      }

      if (curr.type != 'delay') reply.addAudio(_sessionAudio(curr, session));
      // This step has had its say. Whatever the next one contributes is read
      // out as its own line, after this one has finished being read.
      reply.endStep();

      final flow = session.flow;
      if (flow == null) return null;
      curr = _nextStep(flow, curr, null, session.data);
    }

    return curr;
  }

  /// The intent an `intent` step hands over to.
  ///
  /// By id first — that is what the Flow Builder stored, and a key is unique
  /// only within one language, so on a catalogue holding several languages the
  /// key alone can land on the wrong copy of a flow. The key is the fallback,
  /// for a bundle downloaded before ids travelled and for one imported into a
  /// different database, where the ids belong to someone else's rows.
  BotIntent? _redirectTarget(BotStep step) {
    final id = step.nextIntentId;
    if (id != null && id.isNotEmpty) {
      final byId = bundle.intentById(id);
      if (byId != null) return byId;
    }
    final key = step.nextIntentKey;
    if (key == null || key.isEmpty) return null;
    return bundle.intentByRef(key, step.nextIntentLang ?? 'en');
  }

  void _appendCompletion(BotReply reply, BotFlow? flow, BotSession session) {
    if (flow == null) return;
    final completion = renderTemplate(flow.completionMessage, session.data);
    if (completion.isNotEmpty &&
        !placeholderCompletionMessages.contains(completion.trim().toLowerCase())) {
      reply.say(completion);
    }
    if (flow.action != null && flow.action!.isNotEmpty) {
      reply.say('⚙️ *Backend Action Executed:* `${flow.action}`');
    }
  }

  /// Starts or executes an intent directly (bypassing trigger phrase matching).
  Future<BotReply> runIntent(
    BotIntent intent, {
    required BotSession session,
    Map<String, dynamic> profile = const {},
    Map<String, String> triggerVars = const {},
    String? triggerMessage,
  }) async {
    final turnContext = <String, dynamic>{
      ...profile,
      profileKey: profile,
      if (triggerMessage != null) ...{
        messageKey: triggerMessage,
        triggerMessageKey: triggerMessage,
      },
    };
    return _runIntent(intent, triggerVars, turnContext, session);
  }

  Future<BotReply> _runIntent(
    BotIntent intent,
    Map<String, String> triggerVars,
    Map<String, dynamic> turnContext,
    BotSession session,
  ) async {
    final reply = BotReply();

    if (intent.type == 'response') {
      session.clear();
      final context = {...triggerVars, ...turnContext};
      if (intent.response != null) {
        reply.say(renderTemplate(intent.response!.message, context));
        reply.addAudio(intent.response!.audioUrl);
      } else {
        reply.say(
            "Matched intent '${intent.name}', but no reply is configured yet.");
      }
      return reply;
    }

    final flow = intent.flow;
    if (flow == null || flow.steps.isEmpty) {
      session.clear();
      reply.say(
          "Matched '${intent.name}', but its flow has no steps configured yet.");
      return reply;
    }

    // Conditional start connectors read the trigger's captured variables, so
    // seed the session before choosing an entry step.
    session.clear();
    session.intentKey = intent.key;
    session.intentLang = intent.langCode;
    session.flow = flow;
    session.flowName = flow.name;
    session.data = {...triggerVars, ...turnContext};

    final first = _startStep(
        flow, turnContext[messageKey]?.toString(), session.data);
    session.currentStepRef = first?.ref;

    final landed = await _traverse(session, first, reply);

    if (landed == null) {
      // The flow finished on the turn it started (only self-driving steps).
      // `session.flow` rather than `flow`: an `intent` step may have handed
      // over on the way, and it is the flow that actually ran out that gets to
      // say its closing line — or none at all, when the handover cleared the
      // session because the target was a plain response.
      _appendCompletion(reply, session.flow, session);
      session.clear();
      return reply;
    }

    session.currentStepRef = landed.ref;
    reply.say(renderTemplate(landed.question, session.data));
    reply.addAudio(_sessionAudio(landed, session));
    reply.setOptions(stepOptions(landed, session.data));
    return reply;
  }

  /// Answers one message. Mutates [session] to reflect where the flow now is.
  Future<BotReply> respond({
    required String message,
    required BotSession session,
    Map<String, dynamic> profile = const {},
  }) async {
    final trimmed = message.trim();
    final turnContext = <String, dynamic>{
      ...profile,
      profileKey: profile,
      messageKey: trimmed,
      triggerMessageKey: trimmed,
    };

    final catalogue = bundle.forLanguage(langCode);

    if (trimmed.isEmpty) {
      return BotReply()..say('Please say something to begin!');
    }

    // An active flow: the message is first read as an answer to the step the
    // flow is waiting on.
    if (session.isActive) {
      final flow = session.flow!;
      final current = flow.stepByRef(session.currentStepRef);
      if (current == null) {
        session.clear();
      } else {
        final opts = stepOptions(current, session.data);
        final selected = opts.isEmpty ? null : matchOption(opts, trimmed);

        if (selected == null) {
          // While a step waits on one of its options, only a confident intent
          // match may interrupt it — a loose substring hit would let "hi" fire
          // on the word "thing".
          //
          // A step waiting on free text is capped too, just less tightly: a
          // fragment match would have every short answer — "good", "fine",
          // "ok" — read as a question about whichever trigger phrase happens
          // to contain that word, and the flow she was actually in would never
          // reach its next step.
          final maxTier = opts.isEmpty ? tierTemplateLoose : tierTemplateFull;
          final match = findBestIntent(catalogue, trimmed, maxTier: maxTier) ??
              findBestIntent(bundle.intents, trimmed, maxTier: maxTier);

          if (match != null) {
            return await _runIntent(
                match.intent, match.variables, turnContext, session);
          }

          // Neither an option nor an intent — the step is waiting on a choice,
          // so ask again instead of storing the stray utterance.
          if (opts.isNotEmpty) {
            final reply = BotReply()
              ..say(optionMismatchMessage)
              ..say(renderTemplate(current.question, session.data))
              ..addAudio(_sessionAudio(current, session))
              ..setOptions(opts);
            return reply;
          }
        }

        // From here the answer is the canonical option text when one was
        // selected, so saved values and conditions see "Not Good" rather than
        // "i am not good".
        final answer = selected ?? trimmed;

        session.data[profileKey] = profile;
        for (final entry in profile.entries) {
          session.data[entry.key] = entry.value;
        }
        session.data[messageKey] = answer;
        session.data.putIfAbsent(triggerMessageKey, () => answer);

        final validation = validateInput(answer, current.questionDataType);
        if (!validation.valid) {
          final reply = BotReply()
            ..say('⚠️ ${validation.error}')
            ..say(renderTemplate(current.question, session.data))
            ..setOptions(stepOptions(current, session.data));
          return reply;
        }

        _save(session, current.saveKey, answer);

        final reply = BotReply();
        final next = _nextStep(flow, current, answer, session.data);
        final landed = await _traverse(session, next, reply);

        if (landed != null) {
          session.currentStepRef = landed.ref;
          reply.say(renderTemplate(landed.question, session.data));
          reply.addAudio(_sessionAudio(landed, session));
          reply.setOptions(stepOptions(landed, session.data));
          return reply;
        }

        // The flow that ran out, which is not `flow` when an `intent` step
        // handed the conversation over mid-traversal.
        _appendCompletion(reply, session.flow, session);
        session.clear();

        if (reply.text.isEmpty) {
          // The flow ran out with nothing to say, and it was the user's own
          // words that ended it — give them a second life as a trigger rather
          // than replying with a dead end. No fallback here: the message was
          // already understood as an answer, so "I didn't catch that" would be
          // a lie.
          final match = findBestIntent(catalogue, trimmed) ??
              findBestIntent(bundle.intents, trimmed);
          if (match != null) {
            final followup = await _runIntent(
                match.intent, match.variables, turnContext, session);
            reply.segments.addAll(followup.segments);
            reply.actions.addAll(followup.actions);
          }
        }

        return reply;
      }
    }

    // No active flow — intent detection.
    final match = findBestIntent(catalogue, trimmed) ??
        findBestIntent(bundle.intents, trimmed);
    if (match != null) {
      return await _runIntent(match.intent, match.variables, turnContext, session);
    }

    final fallback = bundle.fallbackFor(langCode);
    if (fallback != null) {
      return await _runIntent(fallback, const {}, turnContext, session);
    }

    return BotReply()
      ..say(
          "I'm sorry, I didn't catch that. Could you please rephrase, or try saying 'hi'?");
  }
}
