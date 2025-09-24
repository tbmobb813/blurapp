import 'package:blurapp/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_framework.dart';

void main() {
  BlurAppTestFramework.testGroup('BlurApp Widget Tests', () {
    BlurAppTestFramework.widgetTest('app renders without crashing', (tester) async {
      await tester.pumpWidget(const BlurApp());

      // Verify app loads successfully
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, level: TestLevel.critical);

    BlurAppTestFramework.widgetTest('home screen is displayed as initial screen', (tester) async {
      await tester.pumpWidget(const BlurApp());

      // Verify home screen elements are present
      expect(find.text('BlurApp'), findsOneWidget);
      expect(find.text('Select a Photo to Blur'), findsOneWidget);
    }, level: TestLevel.critical);

    BlurAppTestFramework.widgetTest('gallery and camera buttons are present', (tester) async {
      await tester.pumpWidget(const BlurApp());

      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
    }, level: TestLevel.critical);
  });
}
