/// Actions that open a modal bottom sheet over whatever page is on screen,
/// rather than pushing a new one — Add Family Member and anything else that
/// belongs as a sheet rather than its own route.
library;

import 'package:flutter/material.dart';

import 'package:allomom/features/offline_chatbot/actions/offline_chatbot_action.dart';
import 'package:allomom/main.dart' show rootNavigatorKey;

class OpenSheetAction implements OfflineChatbotAction {
  const OpenSheetAction({
    required this.name,
    required this.description,
    required this.builder,
    this.label,
  });

  @override
  final String name;

  @override
  final String description;

  /// The sheet's body. Built lazily, the same as [OpenPageAction]'s builder.
  final WidgetBuilder builder;

  /// What the sheet is called, for the value a later step can read back.
  final String? label;

  @override
  Future<ActionResult> run(Map<String, dynamic> data) async {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return const ActionResult.failed(
        'I cannot open that right now — try again in a moment.',
      );
    }

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: builder,
      );
      return ActionResult.ok(data: {'opened': label ?? name});
    } catch (e) {
      return ActionResult.failed('Could not open ${label ?? name}: $e');
    }
  }
}
