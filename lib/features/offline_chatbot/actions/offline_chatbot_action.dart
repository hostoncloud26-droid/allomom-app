/// The contract an offline bot action implements.
///
/// An `action` step in a flow names an action and hands it a JSON payload. The
/// engine only *resolves* that payload — rendering its {variables} — because it
/// stays pure and synchronous; running the side effect is the app's job, and
/// happens here as the reply is delivered.
library;

/// What an action reports back after running.
class ActionResult {
  /// False when no action is registered under that name, so the caller can say
  /// so rather than silently doing nothing.
  final bool handled;

  /// True when the side effect actually took place. A registered action that
  /// was asked for something impossible ("switch to purple mode") is handled
  /// but not applied.
  final bool applied;

  /// A line worth showing the user — an error, usually. Flows normally say
  /// their own "done" message in a text step, so a successful action is
  /// expected to stay quiet.
  final String? message;

  /// Anything the action wants to report, for logging or a future step.
  final Map<String, dynamic> data;

  const ActionResult({
    this.handled = true,
    this.applied = false,
    this.message,
    this.data = const {},
  });

  const ActionResult.unhandled(String name)
      : handled = false,
        applied = false,
        message = null,
        data = const {};

  const ActionResult.ok({this.data = const {}})
      : handled = true,
        applied = true,
        message = null;

  const ActionResult.failed(String reason)
      : handled = true,
        applied = false,
        message = reason,
        data = const {};
}

abstract class OfflineChatbotAction {
  /// The name a flow's action step must carry to reach this, e.g.
  /// `toggle_theme`. Matched case-insensitively after trimming.
  String get name;

  /// One line describing what it does, for the builder and for debugging.
  String get description;

  /// Runs the side effect. [data] is the step's `action_data` after its
  /// {variables} were rendered, normalised to a map.
  Future<ActionResult> run(Map<String, dynamic> data);
}
