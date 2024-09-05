import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ELOVANDO_App/main.dart';

void main() {
  testWidgets('App can be built and rendered', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app builds without throwing an error.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
