import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/auth/contact_number_page.dart';
import 'package:allomom/features/auth/register_flow/register_name_page.dart';
import 'package:allomom/features/auth/verify_otp_page.dart';

/// How the onboarding forms present the baby prompt with the keyboard up.
///
/// Two things went wrong here: the banner was squeezed to 150px, which left an
/// empty pink block with a bubble floating in it, and the bottom sheet stopped
/// being pinned to the bottom, which opened a dead gap above the keyboard.
/// Both are asserted against the real geometry.
///
/// Broad overflow coverage for these screens lives in
/// `auth_keyboard_layout_test.dart`; this file is specifically about the
/// banner/prompt swap.
void main() {
  const screen = Size(1080, 2340);
  const dpr = 3.0;
  const logicalHeight = 2340 / dpr; // 780
  const keyboardLogical = 300.0;

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Asserts nothing overflowed *vertically* — the class of bug this file
  /// guards, and the one the screenshots showed.
  ///
  /// Horizontal overflow is not asserted because flutter_test substitutes a
  /// font whose every glyph is a full em square: "Didn't receive the code?"
  /// measures 306px here against ~150px in real Poppins, so text rows that fit
  /// perfectly on a device report a spurious overflow. Heights are unaffected,
  /// so vertical assertions stay trustworthy.
  void expectNoVerticalOverflow(WidgetTester tester) {
    final error = tester.takeException();
    if (error == null) return;
    expect(
      error.toString(),
      isNot(contains('on the bottom')),
      reason: 'something overflowed vertically: $error',
    );
  }

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    required bool keyboard,
  }) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = dpr;
    if (keyboard) {
      tester.view.viewInsets = const FakeViewPadding(
        bottom: keyboardLogical * dpr,
      );
    }
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();
  }

  /// Bottom edge of the area the keyboard leaves visible.
  const visibleBottom = logicalHeight - keyboardLogical;

  final pages = <String, Widget>{
    'contact number': const ContactNumberPage(),
    'verify OTP': const VerifyOtpPage(phoneNumber: '+91 9876500011'),
    'register name': const RegisterNamePage(),
  };

  pages.forEach((name, page) {
    group(name, () {
      testWidgets('shows the full banner when the keyboard is down',
          (tester) async {
        await pump(tester, page, keyboard: false);

        expect(find.byType(BabyHeroBanner), findsOneWidget);
        expect(find.byKey(BabyPromptBar.barKey), findsNothing);
        expectNoVerticalOverflow(tester);
      });

      testWidgets('swaps to the slim prompt when the keyboard is up',
          (tester) async {
        await pump(tester, page, keyboard: true);

        expect(
          find.byKey(BabyPromptBar.barKey),
          findsOneWidget,
          reason: 'a 150px banner is an empty pink block, not a baby',
        );
        expect(find.byType(BabyHeroBanner), findsNothing);
        expectNoVerticalOverflow(tester);
      });

      testWidgets('the slim prompt fits above the keyboard', (tester) async {
        await pump(tester, page, keyboard: true);

        final bar = tester.getRect(find.byKey(BabyPromptBar.barKey));
        expect(bar.bottom, lessThan(visibleBottom));
        // Slim really is slim — the whole point of the swap.
        expect(bar.height, lessThan(90));
        expectNoVerticalOverflow(tester);
      });
    });
  });

  testWidgets('the contact sheet stays pinned to the bottom with a keyboard',
      (tester) async {
    await pump(tester, const ContactNumberPage(), keyboard: true);

    // The last control in the sheet should sit near the bottom of the space
    // the keyboard leaves — not float with a dead gap under it.
    final google = tester.getRect(find.text('Continue with Google'));
    expect(
      google.bottom,
      greaterThan(visibleBottom - 90),
      reason: 'the bottom sheet is not pinned to the bottom any more',
    );
    expect(google.bottom, lessThanOrEqualTo(visibleBottom + 0.5));
    expectNoVerticalOverflow(tester);
  });

  testWidgets('the contact sheet is still at the bottom without a keyboard',
      (tester) async {
    await pump(tester, const ContactNumberPage(), keyboard: false);

    final google = tester.getRect(find.text('Continue with Google'));
    expect(google.bottom, greaterThan(logicalHeight - 90));
    expectNoVerticalOverflow(tester);
  });
}
