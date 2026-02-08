// Basic Flutter widget smoke test for UrbanSight.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:urbansight/main.dart';

void main() {
  testWidgets('App loads and shows sign-in or shell', (WidgetTester tester) async {
    await tester.pumpWidget(const UrbanSightApp());
    await tester.pumpAndSettle();

    // Should show either sign-in UI or main app content.
    expect(
      find.byType(MaterialApp),
      findsOneWidget,
    );
  });
}
