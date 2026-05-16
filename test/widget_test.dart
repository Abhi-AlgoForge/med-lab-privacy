// This is a basic Flutter widget test for MedLab app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:med_lab/main.dart';

void main() {
  testWidgets('App initializes smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MedLabApp());

    // Verify that the app initializes without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
