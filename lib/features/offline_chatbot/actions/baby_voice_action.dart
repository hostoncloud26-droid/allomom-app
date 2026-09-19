/// Turns the baby's voice on and off from inside a conversation.
///
/// The same switch the Settings screen shows: off means the baby stops reading
/// screens out, and her lines keep appearing as text.
library;

import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/offline_chatbot/actions/offline_chatbot_action.dart';

class SetBabyVoiceAction implements OfflineChatbotAction {
  const SetBabyVoiceAction({required this.enable});

  /// Fixed for the two registered actions; a flow that wants the other one
  /// names it rather than passing an argument.
  final bool enable;

  @override
  String get name => enable ? 'enable_speech' : 'disable_speech';

  @override
  String get description => enable
      ? "Turns the baby's voice on."
      : "Turns the baby's voice off.";

  @override
  Future<ActionResult> run(Map<String, dynamic> data) async {
    if (!BackgroundAudioController.isReady) {
      return const ActionResult.failed(
        'The voice setting is not available right now.',
      );
    }

    final controller = BackgroundAudioController.to;
    final was = controller.isVoiceEnabled.value;
    if (was == enable) {
      // Already there. Still a success: the flow's own "done" message stays
      // true either way.
      return ActionResult.ok(data: {'speech': enable, 'changed': false});
    }

    await controller.setVoiceEnabled(enable);
    return ActionResult.ok(data: {'speech': enable, 'changed': true});
  }
}
