/// Opens the youngest baby's milestones tab on `BabyDetailPage` — "add a
/// milestone" and "see milestones" both land here, since the add-form lives
/// on that tab rather than as a screen of its own.
library;

import 'package:flutter/material.dart';

import 'package:allomom/controllers/baby_controller.dart';
import 'package:allomom/features/baby/baby_detail_page.dart';
import 'package:allomom/features/offline_chatbot/actions/offline_chatbot_action.dart';
import 'package:allomom/main.dart' show rootNavigatorKey;

class OpenBabyMilestonesAction implements OfflineChatbotAction {
  const OpenBabyMilestonesAction();

  @override
  String get name => 'open_milestones';

  @override
  String get description => "Opens the baby's milestones tab.";

  @override
  Future<ActionResult> run(Map<String, dynamic> data) async {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      return const ActionResult.failed(
        'I cannot open that right now — try again in a moment.',
      );
    }

    final babyId = BabyController.instance.youngest?.id;
    if (babyId == null) {
      return const ActionResult.failed(
        'Add a baby first, then milestones will show up here.',
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootNavigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => BabyDetailPage(babyId: babyId, initialTab: 1),
        ),
      );
    });
    return const ActionResult.ok(data: {'opened': 'Milestones'});
  }
}
