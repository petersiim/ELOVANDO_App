import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ELOVANDO_App/main.dart';

void main() {
  testWidgets('App can be built and rendered', (WidgetTester tester) async {
    try {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Allow for any initial async operations to complete
      await tester.pump(const Duration(seconds: 2));

      // Pump until all animations and microtasks are complete
      await tester.pumpAndSettle();

      // Verify that the app builds without throwing an error.
      expect(find.byType(MaterialApp), findsOneWidget);
    } catch (e) {
      fail('Test failed with error: $e');
    }
  }, timeout: const Timeout(Duration(seconds: 60))); // Set a 60-second timeout for the entire test
}
