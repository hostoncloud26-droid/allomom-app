import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/auth/contact_number_page.dart';
import 'package:allomom/features/auth/language_selection_page.dart';
import 'package:allomom/features/auth/register_flow/register_cycle_prediction_page.dart';
import 'package:allomom/features/auth/register_flow/register_edd_due_date_page.dart';
import 'package:allomom/features/auth/register_flow/register_name_page.dart';
import 'package:allomom/features/auth/register_flow/register_status_page.dart';
import 'package:allomom/features/auth/role_selection_page.dart';

/// The onboarding screens fill the viewport: the baby card grows into whatever
/// the form card does not need, and the form card runs to the physical bottom
/// edge rather than stopping above the gesture bar.
///
/// They used to pair a fixed 270px baby card with a `Spacer`, which on a tall
/// phone left a band of background between the two — and the whole column sat
/// inside a `SafeArea`, so a strip of background also showed under the card.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// The white sheet at the bottom of every onboarding screen. Identified by
  /// its rounded top, which nothing else on these pages has.
  final bottomCard = find.byWidgetPredicate((w) {
    if (w is! Container) return false;
    final decoration = w.decoration;
    return decoration is BoxDecoration &&
        decoration.borderRadius ==
            const BorderRadius.vertical(top: Radius.circular(32));
  });

  /// Pumps [child] at [size] with [bottomInset] of system padding below it —
  /// a gesture bar, which is what used to leave a visible strip.
  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(400, 880),
    double bottomInset = 48,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: EdgeInsets.only(bottom: bottomInset),
          viewPadding: EdgeInsets.only(bottom: bottomInset),
        ),
        child: MaterialApp(home: child),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
  }

  final pages = <String, Widget Function()>{
    'LanguageSelectionPage': () => const LanguageSelectionPage(),
    'ContactNumberPage': () => const ContactNumberPage(),
    'RoleSelectionPage': () => const RoleSelectionPage(),
    'RegisterNamePage': () => const RegisterNamePage(),
    'RegisterStatusPage': () => const RegisterStatusPage(userName: 'Meera'),
    'RegisterEddDueDatePage': () => RegisterEddDueDatePage(
      userName: 'Meera',
      status: 'Pregnant',
      lmpDate: DateTime(2026, 3, 1),
      eddDate: DateTime(2026, 12, 6),
    ),
    'RegisterCyclePredictionPage': () => RegisterCyclePredictionPage(
      userName: 'Meera',
      status: 'Pre Pregnancy',
      lmpDate: DateTime(2026, 5, 1),
    ),
  };

  for (final entry in pages.entries) {
    group(entry.key, () {
      testWidgets('the card runs to the bottom edge of the screen', (
        tester,
      ) async {
        await pumpAt(tester, entry.value());

        expect(
          tester.getRect(bottomCard.last).bottom,
          moreOrLessEquals(880),
          reason: 'the sheet should paint under the gesture bar, not above it',
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('the baby card takes the space the sheet does not', (
        tester,
      ) async {
        await pumpAt(tester, entry.value());

        expect(
          tester.getRect(find.byType(BabyHeroBanner)).bottom,
          moreOrLessEquals(tester.getRect(bottomCard.last).top),
          reason: 'no background band between the baby and the sheet',
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('the baby card grows with the viewport', (tester) async {
        await pumpAt(tester, entry.value(), size: const Size(400, 700));
        final short = tester.getSize(find.byType(BabyHeroBanner)).height;

        await pumpAt(tester, entry.value(), size: const Size(400, 980));
        final tall = tester.getSize(find.byType(BabyHeroBanner)).height;

        expect(
          tall,
          greaterThan(short),
          reason: 'the extra 280px should go to the baby, not to dead space',
        );
      });
    });
  }
}
