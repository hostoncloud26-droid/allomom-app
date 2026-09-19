/// Remembers when AlloBot last raised each subject on the Home screen.
///
/// The flow's own "already asked" set lives and dies with the screen, which is
/// the wrong lifetime for a question like water: she opens the app six times a
/// day, and each time a fresh flow would ask "shall I add another glass?" as
/// if the last five had not happened. Written to SharedPreferences rather than
/// the vitals stream because a question that was *asked* is not a reading —
/// nothing else in the app has any business reading it.
///
/// Keyed per user and pruned to today: a gap measured in hours has nothing to
/// say about yesterday, and logout clears SharedPreferences outright.
library;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/allobot/home_voice_flow.dart';

class HomePromptHistory {
  HomePromptHistory._();

  static String _key() =>
      'allobot_home_prompts_${MainController.instance.userId}';

  /// When each subject was last put to her today.
  static Future<Map<HomePromptKind, DateTime>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _decode(prefs.getStringList(_key()) ?? const <String>[]);
    } catch (e) {
      debugPrint('HomePromptHistory: could not read the ask log: $e');
      return const {};
    }
  }

  /// Notes that [kind] was asked at [at], dropping anything from another day.
  static Future<void> record(HomePromptKind kind, DateTime at) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _key();
      final history = _decode(prefs.getStringList(key) ?? const <String>[])
        ..removeWhere((_, when) => !_isSameDay(when, at))
        ..[kind] = at;
      await prefs.setStringList(key, _encode(history));
    } catch (e) {
      debugPrint('HomePromptHistory: could not note the ask: $e');
    }
  }

  /// Rows are `kind|iso8601`. Unknown names — a prompt kind renamed in a later
  /// build — are skipped rather than throwing the whole log away.
  static Map<HomePromptKind, DateTime> _decode(List<String> rows) {
    final now = DateTime.now();
    final history = <HomePromptKind, DateTime>{};

    for (final row in rows) {
      final parts = row.split('|');
      if (parts.length != 2) continue;

      final kind = HomePromptKind.values
          .where((value) => value.name == parts.first)
          .firstOrNull;
      final at = DateTime.tryParse(parts.last);
      if (kind == null || at == null) continue;
      if (!_isSameDay(at, now)) continue;

      history[kind] = at;
    }

    return history;
  }

  static List<String> _encode(Map<HomePromptKind, DateTime> history) =>
      history.entries
          .map((entry) => '${entry.key.name}|${entry.value.toIso8601String()}')
          .toList();

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
