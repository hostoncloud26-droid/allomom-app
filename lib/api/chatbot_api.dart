import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// Routes for the graph chatbot that powers Ask Allo.
///
/// The app answers offline: it downloads the whole bot definition once and
/// then matches triggers and walks the flow graph on device, so a conversation
/// costs no network at all. Everything here is about *fetching the definition*,
/// never about running a turn — apart from [runInference], which is the one
/// thing a device cannot do alone.
class ChatbotApi {
  /// The whole catalogue — intents, their replies, flow graphs with steps and
  /// connectors, and the audio index. Pass [langCode] to download a single
  /// language, which is what the app does once the mother has picked one.
  static Future<APIResponse> downloadBot({String? langCode}) {
    return ApiBase.get('/chatbot/sync', query: _langQuery(langCode));
  }

  /// The languages a catalogue can be downloaded for.
  static Future<APIResponse> getLanguages() {
    return ApiBase.get('/chatbot/sync/languages');
  }

  /// Intents alone, without their flows — enough to list what can trigger.
  static Future<APIResponse> getIntents({String? langCode}) {
    return ApiBase.get('/chatbot/sync/intents', query: _langQuery(langCode));
  }

  /// One flow's steps and connectors, for refreshing a single graph.
  static Future<APIResponse> getFlow(String flowId) {
    return ApiBase.get('/chatbot/sync/flows/$flowId');
  }

  /// Runs one `ai` step's inference.
  ///
  /// The single call the offline bot makes mid-conversation — the model cannot
  /// live on device, so an `ai` node reaches out while trigger matching, the
  /// flow graph and everything else stays local. [prompt] and [system] arrive
  /// already rendered; the app resolved their {variables} itself.
  /// [history] is the conversation so far, as `{role, content}` entries. It is
  /// sent on every call, and [useEntireHistory] — which an `ai` step leaves
  /// true unless it was authored to opt out — is what decides whether the
  /// server folds it into the prompt.
  static Future<APIResponse> runInference({
    required String prompt,
    String? system,
    String? model,
    List<Map<String, String>> history = const [],
    bool useEntireHistory = true,
    String? langCode,
    Map<String, dynamic> profile = const {},
  }) {
    return ApiBase.post('/chatbot/ai/infer', {
      'prompt': prompt,
      'system_instruction': system,
      'model': model,
      'history': history,
      'use_entire_history': useEntireHistory,
      // The language the rest of the conversation is in. An authored prompt is
      // written once and shared by every language's catalogue, so without this
      // a Tamil conversation got an English answer at the first `ai` step.
      'lang_code': langCode,
      // What is known about the mother asking. Folded into the system
      // instruction server-side, so a step can ask a plain question and still
      // be answered personally.
      'profile': profile,
    }, timeout: inferenceTimeout);
  }

  /// How long a turn waits on the model before falling back to the flow's own
  /// wording.
  ///
  /// Longer than the app's usual twenty seconds: a model answering with a whole
  /// transcript in the prompt regularly takes more, and giving up at twenty
  /// threw away answers the server had already produced — the mother saw "I
  /// could not reach the assistant" for a reply that existed.
  static const Duration inferenceTimeout = Duration(seconds: 90);

  static Map<String, dynamic>? _langQuery(String? langCode) {
    if (langCode == null || langCode.isEmpty || langCode == 'all') return null;
    return {'lang_code': langCode};
  }
}
