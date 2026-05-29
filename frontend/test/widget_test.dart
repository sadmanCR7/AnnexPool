import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Ensure this import points to your main.dart file correctly
import 'package:frontend/main.dart'; 

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: AnnexPoolApp()));
    await tester.pumpAndSettle(); // Wait for routing animations to finish

    // Verify that our initial text from the GoRouter is displayed.
    expect(find.text('AnnexPool: Initialization Successful'), findsOneWidget);
  });
}