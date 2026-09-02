import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sih_smart_water/main.dart';

void main() {
  testWidgets('SmartWaterApp smoke test - opens SignUpScreen for unauthenticated users via AuthGate', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SmartWaterApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AuthGate renders SignUpScreen on initial launch for new/unauthenticated users
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Join Smart Water System'), findsOneWidget);
    expect(find.text('Sign Up'), findsWidgets);
  });
}
