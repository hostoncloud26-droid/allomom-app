import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:allomom/features/auth/contact_number_page.dart';
import 'package:allomom/features/auth/language_selection_page.dart';
import 'package:allomom/features/auth/register_flow/register_name_page.dart';
import 'package:allomom/features/auth/role_selection_page.dart';

/// Pins the onboarding order: language → mobile verification → (existing user
/// signs in | new user picks a role) → registration.
///
/// The two steps covered here are plain navigation, so they can be driven
/// end to end. The OTP hop between them needs the backend and is asserted
/// structurally instead.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();
  }

  testWidgets('language proceeds to the mobile number, not the role',
      (tester) async {
    await pump(tester, const LanguageSelectionPage());

    expect(find.text('Please Select Your Language'), findsOneWidget);

    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    expect(find.byType(ContactNumberPage), findsOneWidget);
    expect(find.byType(RoleSelectionPage), findsNothing);
  });

  testWidgets('the mobile step no longer greets by an unknown role',
      (tester) async {
    await pump(tester, const ContactNumberPage());

    // Role is only asked after verification, so it cannot be used here.
    expect(find.textContaining('Mommy'), findsNothing);
    expect(find.textContaining('Daddy'), findsNothing);
    expect(find.textContaining("What's your mobile number"), findsOneWidget);
  });

  testWidgets('role selection carries the verified phone into registration',
      (tester) async {
    await pump(
      tester,
      const RoleSelectionPage(
        selectedLanguage: 'en',
        phone: '9876500011',
        countryCode: '+91',
      ),
    );

    expect(find.text('Select Your Role'), findsOneWidget);

    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    final registerPage = tester.widget<RegisterNamePage>(
      find.byType(RegisterNamePage),
    );
    // The number verified two steps ago is reused rather than re-asked.
    expect(registerPage.phone, '9876500011');
    expect(registerPage.countryCode, '+91');
    expect(registerPage.selectedRole, 'Mom');
    expect(registerPage.selectedLanguage, 'en');
  });

  testWidgets('picking Dad carries that role through', (tester) async {
    await pump(
      tester,
      const RoleSelectionPage(phone: '9876500011'),
    );

    await tester.tap(find.text('Dad'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Proceed'));
    await tester.pumpAndSettle();

    final registerPage = tester.widget<RegisterNamePage>(
      find.byType(RegisterNamePage),
    );
    expect(registerPage.selectedRole, 'Dad');
  });
}
