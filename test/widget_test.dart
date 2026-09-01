import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sih_smart_water/main.dart';

void main() {
  testWidgets('SmartWaterApp smoke test - renders main navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SmartWaterApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify main navigation bar items rendered
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Devices'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
