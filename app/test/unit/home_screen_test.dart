import 'package:blurapp/features/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_framework.dart';

void main() {
  BlurAppTestFramework.testGroup('HomeScreen Core Tests', () {
    BlurAppTestFramework.widgetTest('home screen renders all essential UI elements', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Verify essential UI elements are present
      expect(find.text('BlurApp'), findsOneWidget);
      expect(find.text('Select a Photo to Blur'), findsOneWidget);
      expect(find.text('Choose from gallery or take a new photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    }, level: TestLevel.core);

    BlurAppTestFramework.widgetTest('picker buttons exist and are tappable', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for initial render
      await tester.pumpAndSettle();

      // Check that buttons exist (they might be hidden by loading, but should be in widget tree)
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);

      // Try to tap gallery button if it's not hidden by loading indicator
      if (tester.any(find.text('Choose from Gallery'))) {
        await tester.tap(find.text('Choose from Gallery'));
        await tester.pump();
      }

      // Verify app doesn't crash
      expect(tester.takeException(), isNull);
    }, level: TestLevel.core);

    BlurAppTestFramework.widgetTest('settings navigation works', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Wait for initial render
      await tester.pumpAndSettle();

      // Tap settings button
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);

      await tester.tap(settingsButton);
      await tester.pumpAndSettle(); // Wait for navigation animation

      // Verify we're on the settings screen
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Privacy First'), findsOneWidget);
    }, level: TestLevel.core);

    BlurAppTestFramework.widgetTest('privacy notice is displayed', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Verify privacy notice is visible
      expect(find.text('All editing happens offline on your device. No photos are uploaded.'), findsOneWidget);
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
    }, level: TestLevel.misc);
  });
}
