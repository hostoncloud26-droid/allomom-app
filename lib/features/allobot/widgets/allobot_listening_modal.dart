import 'package:flutter/material.dart';
import 'package:allomom/features/allobot/widgets/allobot_voice_assistant_modal.dart';

export 'package:allomom/features/allobot/widgets/allobot_voice_assistant_modal.dart';

class AlloBotListeningModal extends StatelessWidget {
  final VoidCallback onOpenChat;
  final Function(String response)? onSpeechProcessed;

  const AlloBotListeningModal({
    super.key,
    required this.onOpenChat,
    this.onSpeechProcessed,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onOpenChat,
    Function(String response)? onSpeechProcessed,
  }) {
    return AlloBotVoiceAssistantModal.show(
      context,
      onOpenChat: onOpenChat,
      onSpeechProcessed: onSpeechProcessed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlloBotVoiceAssistantModal(
      onOpenChat: onOpenChat,
      onSpeechProcessed: onSpeechProcessed,
    );
  }
}
