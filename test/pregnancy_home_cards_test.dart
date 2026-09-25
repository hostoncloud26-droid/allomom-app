import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/home/widgets/pregnancy_home_cards.dart';
import 'package:allomom/features/pregnancy/data/weekly_baby_talk.dart';

Widget _host(Widget child, {bool dark = false}) => MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  home: Scaffold(
    body: Center(child: SizedBox(height: 345, child: child)),
  ),
);

void _smallPhone(WidgetTester t) {
  t.view.physicalSize = const Size(360, 800);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the seed has Amma\'s message for every pregnancy week', () {
    final weeks =
        jsonDecode(File(WeeklyBabyTalk.asset).readAsStringSync())
            as Map<String, dynamic>;
    for (var w = 1; w <= 40; w++) {
      final mom = (weeks['$w'] as Map)['mom'] as Map;
      for (final lang in WeeklyBabyTalk.languages) {
        expect(mom[lang], isA<String>(), reason: 'week $w $lang');
      }
    }
  });

  test('completed weeks map onto the sheet', () {
    expect(WeeklyBabyTalk.pregnancyWeek(0), 1);
    expect(WeeklyBabyTalk.pregnancyWeek(6), 6);
    // 41 in the sheet is the birth, not an overdue week.
    expect(WeeklyBabyTalk.pregnancyWeek(42), 40);
  });

  testWidgets('the week card shows the sheet message and fits', (t) async {
    _smallPhone(t);
    await t.runAsync(() async {
      await t.pumpWidget(
        _host(
          const PregnancyWeekCard(
            week: 6,
            trimester: 'First Trimester',
            daysLeft: 234,
          ),
        ),
      );
      // The asset load and language read resolve outside the fake clock.
      for (
        var i = 0;
        i < 20 && find.textContaining('flickering').evaluate().isEmpty;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await t.pump();
      }
    });
    expect(find.text('Week 6'), findsOneWidget);
    expect(find.textContaining('flickering'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('right now follows the clock through the day', (t) async {
    _smallPhone(t);
    for (final dark in [false, true]) {
      for (final hour in [6, 9, 11, 14, 17, 20, 23, 2]) {
        await t.pumpWidget(
          _host(
            RightNowCareCard(clock: () => DateTime(2026, 9, 25, hour, 10)),
            dark: dark,
          ),
        );
        await t.pump();
        expect(t.takeException(), isNull, reason: '$hour:10');
        expect(find.textContaining('RIGHT NOW'), findsOneWidget);
      }
    }
    await t.pumpWidget(
      _host(RightNowCareCard(clock: () => DateTime(2026, 9, 25, 8, 10))),
    );
    expect(find.text('Breakfast time'), findsOneWidget);
    expect(find.text('NOW'), findsOneWidget);
  });
}
