/// The bot definition, as it arrives from `/chatbot/sync` and is cached on device.
///
/// Rows are keyed by their natural keys and steps reference each other through
/// per-flow `ref` labels rather than ids, so a downloaded catalogue is self
/// contained — nothing here needs a second call to resolve.
library;

class BotBundle {
  final int version;
  final String? langCode;
  final DateTime? downloadedAt;
  final List<BotLanguage> languages;
  final List<BotIntent> intents;
  final List<BotAudio> audios;

  const BotBundle({
    this.version = 1,
    this.langCode,
    this.downloadedAt,
    this.languages = const [],
    this.intents = const [],
    this.audios = const [],
  });

  bool get isEmpty => intents.isEmpty;

  factory BotBundle.fromJson(Map<String, dynamic> json) {
    return BotBundle(
      version: json['version'] is int ? json['version'] as int : 1,
      langCode: json['lang_code'] as String?,
      downloadedAt: json['downloaded_at'] != null
          ? DateTime.tryParse(json['downloaded_at'].toString())
          : null,
      languages: ((json['languages'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => BotLanguage.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      intents: ((json['intents'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => BotIntent.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      audios: ((json['audios'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => BotAudio.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'lang_code': langCode,
        'downloaded_at': (downloadedAt ?? DateTime.now()).toIso8601String(),
        'languages': languages.map((e) => e.toJson()).toList(),
        'intents': intents.map((e) => e.toJson()).toList(),
        'audios': audios.map((e) => e.toJson()).toList(),
      };

  /// The intent that answers a message matching no trigger phrase.
  ///
  /// Language-strict, like the server: a fallback only answers users of its own
  /// language, since replying in a language the user does not read is worse
  /// than saying nothing sensible.
  BotIntent? fallbackFor(String? langCode) {
    for (final intent in intents) {
      if (!intent.isFallback) continue;
      if (langCode != null && intent.langCode != langCode) continue;
      return intent;
    }
    for (final intent in intents) {
      if (intent.key == 'fallback' &&
          (langCode == null || intent.langCode == langCode)) {
        return intent;
      }
    }
    return null;
  }

  List<BotIntent> forLanguage(String? langCode) {
    if (langCode == null || langCode.isEmpty || langCode == 'all') {
      return intents;
    }
    return intents.where((i) => i.langCode == langCode).toList();
  }

  /// The intent a redirect points at, by the id the Builder stored on the step.
  ///
  /// Exact where [intentByRef] guesses: a key is unique only within a language,
  /// so a catalogue holding the same flow in English and Tamil has two intents
  /// answering to `check_breakfast`, and only the id says which one the author
  /// drew the arrow to.
  BotIntent? intentById(String id) {
    if (id.isEmpty) return null;
    for (final intent in intents) {
      if (intent.id == id) return intent;
    }
    return null;
  }

  BotIntent? intentByRef(String key, String langCode) {
    for (final intent in intents) {
      if (intent.key == key && intent.langCode == langCode) return intent;
    }
    for (final intent in intents) {
      if (intent.key == key) return intent;
    }
    return null;
  }
}

class BotLanguage {
  final String code;
  final String name;

  const BotLanguage({required this.code, required this.name});

  factory BotLanguage.fromJson(Map<String, dynamic> json) => BotLanguage(
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'code': code, 'name': name};
}

class BotIntent {
  /// The id this intent has in the catalogue it was downloaded from.
  ///
  /// How an `intent` step's redirect finds its target: the Flow Builder stores
  /// the target by id, so the id is what resolves it exactly. Empty for a
  /// hand-built intent or a bundle downloaded before ids travelled, which is
  /// why [BotBundle.intentByRef] is still there to fall back on.
  final String id;
  final String key;
  final String name;
  final List<String> examples;

  /// "response" (one reply) or "flow" (a multi-step graph).
  final String type;
  final String langCode;
  final bool isFallback;
  final BotResponse? response;
  final BotFlow? flow;

  const BotIntent({
    this.id = '',
    required this.key,
    required this.name,
    this.examples = const [],
    this.type = 'response',
    this.langCode = 'en',
    this.isFallback = false,
    this.response,
    this.flow,
  });

  factory BotIntent.fromJson(Map<String, dynamic> json) => BotIntent(
        id: (json['id'] ?? '').toString(),
        key: (json['key'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        examples: ((json['examples'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        type: (json['type'] ?? 'response').toString(),
        langCode: (json['lang_code'] ?? 'en').toString(),
        isFallback: json['is_fallback'] == true,
        response: json['response'] is Map
            ? BotResponse.fromJson(Map<String, dynamic>.from(json['response']))
            : null,
        flow: json['flow'] is Map
            ? BotFlow.fromJson(Map<String, dynamic>.from(json['flow']))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'name': name,
        'examples': examples,
        'type': type,
        'lang_code': langCode,
        'is_fallback': isFallback,
        'response': response?.toJson(),
        'flow': flow?.toJson(),
      };
}

class BotResponse {
  final String message;
  final String? audioUrl;

  const BotResponse({required this.message, this.audioUrl});

  factory BotResponse.fromJson(Map<String, dynamic> json) => BotResponse(
        message: (json['message'] ?? '').toString(),
        audioUrl: json['audio_url'] as String?,
      );

  Map<String, dynamic> toJson() => {'message': message, 'audio_url': audioUrl};
}

class BotFlow {
  final String name;
  final String completionMessage;
  final String? action;
  final List<BotStep> steps;
  final List<BotConnector> connectors;

  const BotFlow({
    required this.name,
    this.completionMessage = '',
    this.action,
    this.steps = const [],
    this.connectors = const [],
  });

  factory BotFlow.fromJson(Map<String, dynamic> json) => BotFlow(
        name: (json['name'] ?? '').toString(),
        completionMessage: (json['completion_message'] ?? '').toString(),
        action: json['action'] as String?,
        steps: ((json['steps'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => BotStep.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        connectors: ((json['connectors'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => BotConnector.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'completion_message': completionMessage,
        'action': action,
        'steps': steps.map((e) => e.toJson()).toList(),
        'connectors': connectors.map((e) => e.toJson()).toList(),
      };

  BotStep? stepByRef(String? ref) {
    if (ref == null) return null;
    for (final step in steps) {
      if (step.ref == ref) return step;
    }
    return null;
  }

  /// Connectors leaving a step, in the order they were drawn.
  List<BotConnector> outgoing(String ref) =>
      connectors.where((c) => c.fromRef == ref).toList();

  /// Connectors drawn from the canvas START node — they name the entry step.
  List<BotConnector> get startConnectors =>
      connectors.where((c) => c.fromRef == null && c.toRef != null).toList();
}

class BotStep {
  final String ref;

  /// "text", "delay", "question", "http", "image", "ai", "action", "intent".
  final String type;
  final String question;
  final String? saveKey;
  final String? questionDataType;
  final String? audioUrl;

  /// The recording this step speaks, named rather than linked.
  ///
  /// A key is language-independent: the same `pregnant_week10` plays the Tamil
  /// clip in a Tamil conversation and the English one in English, because the
  /// library is filed by language. A step with an explicit [audioUrl] names
  /// one file and overrides this.
  final String? audioKey;
  final String? httpMethod;
  final String? httpUrl;
  final dynamic httpHeaders;
  final String? httpBody;
  final String? imageUrl;
  final String? aiPrompt;
  final String? aiSystem;
  final String? aiModel;
  final String? actionName;
  final dynamic actionData;
  final List<String> options;

  /// An "intent" step hands the conversation to another intent.
  ///
  /// [nextIntentId] is what the Flow Builder actually stored and is resolved
  /// first; the key and language are the fallback, for a bundle exported
  /// before ids travelled or imported into a different database, where the
  /// ids are someone else's.
  final String? nextIntentId;
  final String? nextIntentKey;
  final String? nextIntentLang;

  const BotStep({
    required this.ref,
    this.type = 'question',
    this.question = '',
    this.saveKey,
    this.questionDataType,
    this.audioUrl,
    this.audioKey,
    this.httpMethod,
    this.httpUrl,
    this.httpHeaders,
    this.httpBody,
    this.imageUrl,
    this.aiPrompt,
    this.aiSystem,
    this.aiModel,
    this.actionName,
    this.actionData,
    this.options = const [],
    this.nextIntentId,
    this.nextIntentKey,
    this.nextIntentLang,
  });

  factory BotStep.fromJson(Map<String, dynamic> json) {
    final nextIntent = json['next_intent_ref'];
    return BotStep(
      ref: (json['ref'] ?? '').toString(),
      type: (json['type'] ?? 'question').toString(),
      question: (json['question'] ?? '').toString(),
      saveKey: json['save_key'] as String?,
      questionDataType: json['question_data_type'] as String?,
      audioUrl: json['audio_url'] as String?,
      audioKey: json['audio_key'] as String?,
      httpMethod: json['http_method'] as String?,
      httpUrl: json['http_url'] as String?,
      httpHeaders: json['http_headers'],
      httpBody: json['http_body'] as String?,
      imageUrl: json['image_url'] as String?,
      aiPrompt: json['ai_prompt'] as String?,
      aiSystem: json['ai_system'] as String?,
      aiModel: json['ai_model'] as String?,
      actionName: json['action_name'] as String?,
      actionData: json['action_data'],
      options: ((json['options'] as List?) ?? const [])
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList(),
      nextIntentId: json['next_intent_id']?.toString(),
      nextIntentKey:
          nextIntent is Map ? nextIntent['key']?.toString() : null,
      nextIntentLang:
          nextIntent is Map ? (nextIntent['lang_code']?.toString() ?? 'en') : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'ref': ref,
        'type': type,
        'question': question,
        'save_key': saveKey,
        'question_data_type': questionDataType,
        'audio_url': audioUrl,
        'audio_key': audioKey,
        'http_method': httpMethod,
        'http_url': httpUrl,
        'http_headers': httpHeaders,
        'http_body': httpBody,
        'image_url': imageUrl,
        'ai_prompt': aiPrompt,
        'ai_system': aiSystem,
        'ai_model': aiModel,
        'action_name': actionName,
        'action_data': actionData,
        'options': options,
        'next_intent_id': nextIntentId,
        'next_intent_ref': nextIntentKey == null
            ? null
            : {'key': nextIntentKey, 'lang_code': nextIntentLang ?? 'en'},
      };

  /// The tag an ai step used to carry to opt *into* the transcript. Kept so an
  /// already-authored step still reads as it did — it now says what is already
  /// true. The [options] column is unused on an ai step — options are a
  /// question's quick-reply buttons — so these flags ride along there rather
  /// than costing a schema change.
  static const String historyOption = 'use_entire_history';

  /// The opt-*out*: an ai step carrying this answers the prompt alone.
  ///
  /// For the steps that summarise, classify or extract, where an earlier
  /// exchange is noise in the prompt rather than context.
  static const String noHistoryOption = 'no_history';

  /// Whether this ai step sees the conversation so far — which it does unless
  /// it was authored to not.
  ///
  /// The default used to be the other way round, and it made the bot forgetful
  /// in exactly the moment a mother expects it not to be: told that raw papaya
  /// is unsafe, she asks "I ate it, what do I do?", and a step without the
  /// transcript has no idea what "it" was.
  bool get usesEntireHistory {
    if (type != 'ai') return false;
    return !options.any((o) {
      final tag = o.trim().toLowerCase();
      return tag == noHistoryOption || tag == 'no_entire_history';
    });
  }

  /// Steps that run on their own and hand straight over to the next one.
  bool get isAutomatic => const [
        'text',
        'delay',
        'http',
        'image',
        'ai',
        'action',
        'intent',
      ].contains(type);
}

class BotConnector {
  final String ref;

  /// Null when the connector is drawn from the canvas START node.
  final String? fromRef;
  final String? toRef;
  final Map<String, dynamic> logic;

  const BotConnector({
    required this.ref,
    this.fromRef,
    this.toRef,
    this.logic = const {},
  });

  factory BotConnector.fromJson(Map<String, dynamic> json) => BotConnector(
        ref: (json['ref'] ?? '').toString(),
        fromRef: json['from_ref'] as String?,
        toRef: json['to_ref'] as String?,
        logic: json['logic'] is Map
            ? Map<String, dynamic>.from(json['logic'])
            : const {},
      );

  Map<String, dynamic> toJson() => {
        'ref': ref,
        'from_ref': fromRef,
        'to_ref': toRef,
        'logic': logic,
      };

  /// The clauses this connector is gated on, tolerating the pre-list format.
  /// An empty list means unconditional.
  List<Map<String, dynamic>> get conditions {
    final raw = logic['conditions'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((c) =>
              c['operator'] != null && c['operator'].toString() != 'always')
          .toList();
    }
    final op = logic['operator'];
    if (op == null || op.toString() == 'always') return const [];
    return [
      {
        'variable': logic['variable'],
        'operator': op,
        'value': logic['value'] ?? '',
      }
    ];
  }

  bool get matchAny => (logic['match']?.toString().toLowerCase() ?? 'all') == 'any';
}

class BotAudio {
  final String key;
  final String langCode;
  final String filename;
  final String url;
  final String? transcription;

  const BotAudio({
    required this.key,
    required this.langCode,
    required this.filename,
    required this.url,
    this.transcription,
  });

  factory BotAudio.fromJson(Map<String, dynamic> json) => BotAudio(
        key: (json['key'] ?? '').toString(),
        langCode: (json['lang_code'] ?? 'en').toString(),
        filename: (json['filename'] ?? '').toString(),
        url: (json['url'] ?? '').toString(),
        transcription: json['transcription'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'lang_code': langCode,
        'filename': filename,
        'url': url,
        'transcription': transcription,
      };
}
