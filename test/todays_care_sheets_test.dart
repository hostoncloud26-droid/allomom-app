import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_count_sheet.dart';
import 'package:allomom/features/overview_section/todays_care/widgets/care_meal_sheet.dart';

/// The count sheet returns an increment and the meal sheet returns calories;
/// both feed straight into a vital write, so their return values are pinned.
void main() {
  /// Pumps [open] behind a button and taps it to show the sheet.
  Future<void> pumpSheet(
    WidgetTester tester,
    Future<void> Function(BuildContext context) open,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => open(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('CareCountSheet', () {
    testWidgets('returns the first preset when logged straight away', (
      tester,
    ) async {
      int? result;
      await pumpSheet(tester, (context) async {
        result = await CareCountSheet.show(
          context,
          title: 'Drink water',
          unitLabel: 'glasses',
          unitLabelSingular: 'glass',
          icon: Icons.water_drop_rounded,
          color: Colors.cyan,
          target: 10,
          presets: const [1, 2, 3],
        );
      });

      expect(find.text('Drink water'), findsOneWidget);
      await tester.tap(find.text('Log 1 glass'));
      await tester.pumpAndSettle();

      expect(result, 1);
    });

    testWidgets('stepper and presets change the amount logged', (tester) async {
      int? result;
      await pumpSheet(tester, (context) async {
        result = await CareCountSheet.show(
          context,
          title: 'Drink water',
          unitLabel: 'glasses',
          unitLabelSingular: 'glass',
          icon: Icons.water_drop_rounded,
          color: Colors.cyan,
          presets: const [1, 2, 3],
        );
      });

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Log 3 glasses'), findsOneWidget);

      await tester.tap(find.text('2 glasses'));
      await tester.pumpAndSettle();
      expect(find.text('Log 2 glasses'), findsOneWidget);

      await tester.tap(find.text('Log 2 glasses'));
      await tester.pumpAndSettle();
      expect(result, 2);
    });

    testWidgets('never logs less than one or more than maxPerLog', (
      tester,
    ) async {
      await pumpSheet(tester, (context) async {
        await CareCountSheet.show(
          context,
          title: 'Coffee or tea',
          unitLabel: 'cups',
          unitLabelSingular: 'cup',
          icon: Icons.coffee_rounded,
          color: Colors.brown,
          presets: const [1, 2],
          maxPerLog: 2,
        );
      });

      // Already at the floor of 1.
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Log 1 cup'), findsOneWidget);

      // Two taps up, but the ceiling is 2.
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Log 2 cups'), findsOneWidget);
    });

    testWidgets('counts what is already logged toward the goal', (
      tester,
    ) async {
      await pumpSheet(tester, (context) async {
        await CareCountSheet.show(
          context,
          title: 'Drink water',
          unitLabel: 'glasses',
          unitLabelSingular: 'glass',
          icon: Icons.water_drop_rounded,
          color: Colors.cyan,
          loggedToday: 4,
          target: 10,
          presets: const [1, 2, 3],
        );
      });

      expect(
        find.text('Today: 4 logged · 5 of 10 glasses after this'),
        findsOneWidget,
      );

      // Reaching the goal is called out instead of the running tally.
      await tester.tap(find.text('3 glasses'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();
      expect(find.textContaining("hits today's goal"), findsOneWidget);
    });

    testWidgets('returns null when dismissed', (tester) async {
      int? result;
      var completed = false;
      await pumpSheet(tester, (context) async {
        result = await CareCountSheet.show(
          context,
          title: 'Snack',
          unitLabel: 'portions',
          unitLabelSingular: 'portion',
          icon: Icons.cookie_rounded,
          color: Colors.amber,
          presets: const [1, 2],
        );
        completed = true;
      });

      await tester.tapAt(const Offset(20, 20)); // barrier
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(result, isNull);
    });
  });

  group('CareMealSheet', () {
    testWidgets('defaults to the balanced portion and its calories', (
      tester,
    ) async {
      CareMealLog? result;
      await pumpSheet(tester, (context) async {
        result = await CareMealSheet.show(
          context,
          meal: CareMeal.breakfast,
          color: Colors.orange,
          icon: Icons.free_breakfast_rounded,
        );
      });

      expect(find.text('Log Breakfast'), findsOneWidget);
      await tester.tap(find.text('Save Breakfast'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.calories, CareMeal.breakfast.typicalCalories.toDouble());
      expect(result!.details, 'Balanced breakfast');
    });

    testWidgets('a lighter portion logs fewer calories', (tester) async {
      CareMealLog? result;
      await pumpSheet(tester, (context) async {
        result = await CareMealSheet.show(
          context,
          meal: CareMeal.lunch,
          color: Colors.orange,
          icon: Icons.lunch_dining_rounded,
        );
      });

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Lunch'));
      await tester.pumpAndSettle();

      expect(result!.calories, lessThan(CareMeal.lunch.typicalCalories));
      expect(result!.details, 'Light lunch');
    });

    testWidgets('typed description and exact calories win', (tester) async {
      CareMealLog? result;
      await pumpSheet(tester, (context) async {
        result = await CareMealSheet.show(
          context,
          meal: CareMeal.dinner,
          color: Colors.deepOrange,
          icon: Icons.dinner_dining_rounded,
        );
      });

      await tester.enterText(find.byType(TextField).first, 'Khichdi and curd');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enter exact calories'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '420');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Dinner'));
      await tester.pumpAndSettle();

      expect(result!.calories, 420);
      expect(result!.details, 'Khichdi and curd');
    });

    testWidgets('a blank calorie field falls back to the portion estimate', (
      tester,
    ) async {
      CareMealLog? result;
      await pumpSheet(tester, (context) async {
        result = await CareMealSheet.show(
          context,
          meal: CareMeal.dinner,
          color: Colors.deepOrange,
          icon: Icons.dinner_dining_rounded,
        );
      });

      await tester.tap(find.text('Enter exact calories'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Dinner'));
      await tester.pumpAndSettle();

      expect(result!.calories, CareMeal.dinner.typicalCalories.toDouble());
    });

    testWidgets('shows the trimester suggestion it was given', (tester) async {
      await pumpSheet(tester, (context) async {
        await CareMealSheet.show(
          context,
          meal: CareMeal.breakfast,
          color: Colors.orange,
          icon: Icons.free_breakfast_rounded,
          suggestion: 'Something bland and dry helps with morning nausea',
        );
      });

      expect(
        find.text('Something bland and dry helps with morning nausea'),
        findsOneWidget,
      );
    });
  });
}
