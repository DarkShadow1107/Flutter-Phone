import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_phone/main.dart';

void main() {
  testWidgets('Phone app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PhoneApp());

    // Verify that the keypad screen is shown by checking for a digit.
    expect(find.text('Keypad'), findsWidgets);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
