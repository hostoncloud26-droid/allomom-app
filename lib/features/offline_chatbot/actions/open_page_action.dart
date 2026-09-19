/// Actions that take the mother somewhere in the app.
///
/// AlloKonnect ships one file per navigation action because each one drives a
/// different tab controller. Every AlloMom destination is a plain page pushed
/// on the root navigator, so they are one parameterised class instead — the
/// registry names the destinations, and there is a single place where a push
/// can go wrong.
library;

import 'package:flutter/material.dart';

import 'package:allomom/features/offline_chatbot/actions/offline_chatbot_action.dart';
import 'package:allomom/main.dart' show rootNavigatorKey;

class OpenPageAction implements OfflineChatbotAction {
  const OpenPageAction({
    required this.name,
    required this.description,
    required this.builder,
    this.label,
    this.replaceStack = false,
  });

  @override
  final String name;

  @override
  final String description;

  /// The page to show. Built lazily, inside the post-frame callback, so a page
  /// that reads a controller in its constructor does so after the turn that
  /// asked for it has finished being delivered.
  final WidgetBuilder builder;

  /// What the destination is called, for the value a later step can read back.
  final String? label;

  /// Whether to pop back to the app shell first. True for destinations that
  /// belong at the root, so a long conversation does not leave a stack of
  /// pages behind the page that was asked for.
  final bool replaceStack;

  @override
  Future<ActionResult> run(Map<String, dynamic> data) async {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      return const ActionResult.failed(
        'I cannot open that right now — try again in a moment.',
      );
    }

    try {
      // After the frame, so the reply that announces the move is on screen
      // before the page slides over it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = rootNavigatorKey.currentState;
        if (target == null) return;
        if (replaceStack) target.popUntil((route) => route.isFirst);
        target.push(MaterialPageRoute(builder: builder));
      });
      return ActionResult.ok(data: {'opened': label ?? name});
    } catch (e) {
      return ActionResult.failed('Could not open ${label ?? name}: $e');
    }
  }
}

/// Returns to the app shell without opening anything on top of it.
class OpenHomeAction implements OfflineChatbotAction {
  const OpenHomeAction();

  @override
  String get name => 'open_home';

  @override
  String get description => 'Goes back to the AlloMom home screen.';

  @override
  Future<ActionResult> run(Map<String, dynamic> data) async {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) {
      return const ActionResult.failed(
        'I cannot open home right now — try again in a moment.',
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
    return const ActionResult.ok(data: {'opened': 'home'});
  }
}
