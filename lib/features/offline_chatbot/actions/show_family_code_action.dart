/// Shows the family's invite code and QR from a chatbot flow.
library;

import 'package:allomom/features/offline_chatbot/actions/offline_chatbot_action.dart';
import 'package:allomom/features/people/widgets/family_invite_code_sheet.dart';
import 'package:allomom/main.dart' show rootNavigatorKey;

class ShowFamilyCodeAction implements OfflineChatbotAction {
  const ShowFamilyCodeAction();

  @override
  String get name => 'show_family_code';

  @override
  String get description => "Shows the family's invite code and QR.";

  @override
  Future<ActionResult> run(Map<String, dynamic> data) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return const ActionResult.failed(
        'I cannot show that right now — try again in a moment.',
      );
    }

    try {
      await showFamilyInviteCodeSheet(context);
      return const ActionResult.ok(data: {'opened': 'family_code'});
    } catch (e) {
      return ActionResult.failed('Could not show the family code: $e');
    }
  }
}
