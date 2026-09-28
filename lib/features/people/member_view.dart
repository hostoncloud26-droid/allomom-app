import 'package:flutter/material.dart';

import 'package:allomom/controllers/main_controller.dart';

/// Opens [builder]'s screen on a family member's health record — a father
/// opening My Health, the pregnancy journey or reports on his wife's.
///
/// The screens are the ones he uses for his own record: [MainController]
/// switches whose record they read for as long as the screen is open, and
/// switches back when it is closed.
Future<void> openMemberView(
  BuildContext context, {
  required String memberUserId,
  required String memberName,
  required WidgetBuilder builder,
}) async {
  final session = MainController.instance;
  final navigator = Navigator.of(context);

  // Straight onto her record: the copy on the device shows at once and the
  // latest is fetched behind it, the way AlloConnect opens a member.
  await session.viewMember(memberUserId, name: memberName);
  try {
    await navigator.push(MaterialPageRoute(builder: builder));
  } finally {
    await session.stopViewingMember();
  }
}
