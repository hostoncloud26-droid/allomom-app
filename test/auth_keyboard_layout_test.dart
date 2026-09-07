import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/features/auth/contact_number_page.dart';
import 'package:allomom/features/auth/language_selection_page.dart';
import 'package:allomom/features/auth/register_flow/register_name_page.dart';
import 'package:allomom/features/auth/register_flow/register_cycle_prediction_page.dart';
import 'package:allomom/features/auth/register_flow/register_edd_due_date_page.dart';
import 'package:allomom/features/auth/register_flow/register_partner_details_page.dart';
import 'package:allomom/features/auth/register_flow/register_status_page.dart';
import 'package:allomom/features/auth/role_selection_page.dart';

/// These onboarding screens pin a form card to the bottom of the viewport with
/// a Spacer. Before the fix they used `IntrinsicHeight` (which does not support
/// flex children) or no scroll view at all, so an open keyboard either
/// stretched the card or overflowed the column outright.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Pumps [child] at [size], with [keyboardHeight] of bottom view insets.
  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    required Size size,
    double keyboardHeight = 0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: size,
          viewInsets: EdgeInsets.only(bottom: keyboardHeight),
        ),
        child: MaterialApp(home: child),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));
  }

  /// Every onboarding screen, and whether it has a text field. Screens with
  /// no input never see a keyboard, so pushing one at them is not a state the
  /// app can reach — they are still checked on a small screen.
  final pages = <String, ({Widget Function() build, bool hasInput})>{
    'ContactNumberPage': (
      build: () => const ContactNumberPage(),
      hasInput: true,
    ),
    'RegisterNamePage': (build: () => const RegisterNamePage(), hasInput: true),
    'RegisterPartnerDetailsPage': (
      build: () => RegisterPartnerDetailsPage(
        userName: 'Meera',
        status: 'Pregnant',
        eddDate: DateTime(2026, 12, 1),
      ),
      hasInput: true,
    ),
    'LanguageSelectionPage': (
      build: () => const LanguageSelectionPage(),
      hasInput: false,
    ),
    'RoleSelectionPage': (
      build: () => const RoleSelectionPage(),
      hasInput: false,
    ),
    'RegisterStatusPage': (
      build: () => const RegisterStatusPage(userName: 'Meera'),
      hasInput: false,
    ),
    'RegisterEddDueDatePage': (
      build: () => RegisterEddDueDatePage(
        userName: 'Meera',
        status: 'Pregnant',
        lmpDate: DateTime(2026, 3, 1),
        eddDate: DateTime(2026, 12, 6),
      ),
      hasInput: false,
    ),
    'RegisterCyclePredictionPage': (
      build: () => RegisterCyclePredictionPage(
        userName: 'Meera',
        status: 'Pre Pregnancy',
        lmpDate: DateTime(2026, 5, 1),
      ),
      hasInput: false,
    ),
  };

  for (final entry in pages.entries) {
    final name = entry.key;
    final page = entry.value;

    group(name, () {
      testWidgets('lays out on a normal screen', (tester) async {
        await pumpAt(tester, page.build(), size: const Size(400, 800));
        expect(tester.takeException(), isNull);
      });

      testWidgets('lays out on a small screen', (tester) async {
        // A 320-wide phone, or a split-screen window.
        await pumpAt(tester, page.build(), size: const Size(320, 560));
        expect(tester.takeException(), isNull);
      });

      testWidgets('scrolls rather than clipping', (tester) async {
        await pumpAt(tester, page.build(), size: const Size(320, 560));
        // Either strategy is fine — a viewport-filling sliver, or a card that
        // scrolls its own content. What matters is that something can scroll.
        expect(find.byType(Scrollable), findsWidgets);
        expect(tester.takeException(), isNull);
      });

      if (page.hasInput) {
        testWidgets('lays out with the keyboard open', (tester) async {
          await pumpAt(
            tester,
            page.build(),
            size: const Size(400, 800),
            keyboardHeight: 340,
          );
          expect(tester.takeException(), isNull);
        });

        testWidgets('lays out on a small screen with the keyboard open', (
          tester,
        ) async {
          // Worst case: the form card alone is taller than what is left.
          await pumpAt(
            tester,
            page.build(),
            size: const Size(320, 560),
            keyboardHeight: 300,
          );
          expect(tester.takeException(), isNull);
        });
      }
    });
  }
}
