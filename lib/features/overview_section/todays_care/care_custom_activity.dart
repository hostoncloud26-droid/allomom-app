import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/overview_section/todays_care/care_catalogue.dart';

/// The kinds of thing she can add to her own day, each with the look its card
/// wears on the timeline.
enum CareActivityType {
  meal('Meal', Icons.restaurant_rounded, Color(0xffFF9800)),
  water('Water', Icons.water_drop_rounded, Color(0xff26C6DA)),
  medicine('Medicine', Icons.medication_rounded, Color(0xffFF626F)),
  exercise('Exercise', Icons.self_improvement_rounded, Color(0xff4CAF50)),
  rest('Rest / Sleep', Icons.bedtime_rounded, Color(0xff5C7CFA)),
  other('Other', Icons.chat_bubble_outline_rounded, Color(0xff8E95A5));

  const CareActivityType(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static CareActivityType fromName(String? name) => CareActivityType.values
      .firstWhere((t) => t.name == name, orElse: () => CareActivityType.other);
}

/// An activity she put on the timeline herself.
///
/// It is part of her routine, not of one day: it comes back at the same hour
/// every day, and ticking it off is per day, through the same `todocare`
/// tick-off the built-in items use.
class CareCustomActivity {
  const CareCustomActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.hour,
    this.note = '',
  });

  final String id;
  final CareActivityType type;
  final String title;
  final String note;

  /// 0–23.
  final int hour;

  /// The tick-off key. Stable, so a day's tick survives a rename.
  String get actionValue => 'custom_$id';

  CareItem toCareItem() => CareItem(
    id: 'custom_$id',
    title: title,
    subtitle: note.isNotEmpty ? note : type.label,
    icon: type.icon,
    color: type.color,
    kind: CareActionKind.checkoff,
    actionValue: actionValue,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'note': note,
    'hour': hour,
  };

  static CareCustomActivity? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id']?.toString();
    final title = json['title']?.toString();
    final hour = json['hour'];
    if (id == null || title == null || hour is! int) return null;
    return CareCustomActivity(
      id: id,
      type: CareActivityType.fromName(json['type']?.toString()),
      title: title,
      note: json['note']?.toString() ?? '',
      hour: hour.clamp(0, 23),
    );
  }
}

/// Saves her own activities on the phone, per account.
class CareCustomActivityStore {
  CareCustomActivityStore._();

  static const _uuid = Uuid();

  static String get _key =>
      'todocare_custom_activities_${MainController.instance.userId}';

  static Future<List<CareCustomActivity>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(CareCustomActivity.fromJson)
          .whereType<CareCustomActivity>()
          .toList();
    } catch (e) {
      debugPrint('⚠️ [CareCustomActivityStore] Could not read activities: $e');
      return const [];
    }
  }

  static Future<void> _save(List<CareCustomActivity> activities) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final a in activities) a.toJson()]),
    );
  }

  static Future<void> add({
    required CareActivityType type,
    required String title,
    required int hour,
    String note = '',
  }) async {
    final current = await load();
    await _save([
      ...current,
      CareCustomActivity(
        id: _uuid.v4(),
        type: type,
        title: title,
        hour: hour,
        note: note,
      ),
    ]);
  }

  static Future<void> remove(String id) async {
    final current = await load();
    await _save(current.where((a) => a.id != id).toList());
  }
}
