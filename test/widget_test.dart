import 'package:flutter_test/flutter_test.dart';
import 'package:allomom/main.dart';

void main() {
  testWidgets('App renders', (WidgetTester tester) async {
    await tester.pumpWidget(const AllomomApp());
    expect(find.text('Please Select Your Language'), findsOneWidget);
    expect(find.text('Proceed'), findsOneWidget);
  });
}
