import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_framework.dart';

/// Template for CRITICAL level tests
///
/// Critical tests verify user-facing features that impact core workflow.
/// These include:
/// - Primary user interactions
/// - Core UI functionality
/// - Essential user flows
/// - Critical error handling
///
/// Critical tests should:
/// - Test complete user scenarios
/// - Verify UI state changes
/// - Include error handling paths
/// - Cover primary use cases

void main() {
  BlurAppTestFramework.testGroup('Critical User Flow Tests', () {
    // Example: Critical user flow test
    BlurAppTestFramework.widgetTest('user can complete full blur workflow from image selection to export', (
      tester,
    ) async {
      // Build the main app
      await tester.pumpWidget(BlurAppTestFramework.createTestApp(const _MockEditorScreen()));

      // Step 1: User selects image
      await TestHelpers.tapAndSettle(tester, find.byKey(const Key('gallery_button')));

      BlurAppAssertions.assertUIStateTransition(tester, 'Select Image', 'Image Loaded');

      // Step 2: User applies blur
      await TestHelpers.tapAndSettle(tester, find.byKey(const Key('blur_button')));

      BlurAppAssertions.assertUIStateTransition(tester, 'Original', 'Blurred');

      // Step 3: User exports image
      await TestHelpers.tapAndSettle(tester, find.byKey(const Key('export_button')));

      // Verify export completed
      expect(find.text('Export Complete'), findsOneWidget);
    }, level: TestLevel.critical);

    // Example: Critical error handling test
    BlurAppTestFramework.widgetTest('app gracefully handles image processing errors', (tester) async {
      await tester.pumpWidget(BlurAppTestFramework.createTestApp(const _MockEditorScreen()));

      // Simulate error condition
      await tester.tap(find.byKey(const Key('error_trigger_button')));
      await TestHelpers.pumpAndSettle(tester);

      // Verify error is displayed to user
      expect(find.text('Processing Error'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      // Verify app remains functional
      expect(find.byKey(const Key('gallery_button')), findsOneWidget);
    }, level: TestLevel.critical);

    // Example: Critical UI responsiveness test
    BlurAppTestFramework.widgetTest('UI remains responsive during image processing', (tester) async {
      await tester.pumpWidget(BlurAppTestFramework.createTestApp(const _MockEditorScreen()));

      // Start processing
      await tester.tap(find.byKey(const Key('process_button')));
      await tester.pump(); // Don't settle, test immediate response

      // Verify loading indicator appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Verify UI is still interactive
      expect(find.byKey(const Key('cancel_button')), findsOneWidget);

      // Complete processing
      await TestHelpers.pumpAndSettle(tester);

      // Verify completion
      expect(find.byType(CircularProgressIndicator), findsNothing);
    }, level: TestLevel.critical);

    // Example: Critical data persistence test
    BlurAppTestFramework.asyncTest('user changes are preserved across app lifecycle', () async {
      final mockService = _MockDataService();

      // Make changes
      await mockService.saveUserSettings({'blurStrength': 25});

      // Simulate app restart
      mockService.simulateRestart();

      // Verify data persisted
      final settings = await mockService.loadUserSettings();
      expect(settings['blurStrength'], equals(25));
    }, level: TestLevel.critical);

    // Example: Critical integration test
    BlurAppTestFramework.integrationTest('complete app flow works end-to-end', (tester) async {
      await tester.pumpWidget(BlurAppTestFramework.createTestApp(const _MockBlurApp()));

      // Navigate to editor
      await TestHelpers.tapAndSettle(tester, find.text('Start Editing'));

      // Select image
      await TestHelpers.tapAndSettle(tester, find.text('Gallery'));

      // Apply blur
      await TestHelpers.tapAndSettle(tester, find.text('Blur'));

      // Export
      await TestHelpers.tapAndSettle(tester, find.text('Export'));

      // Verify final state
      expect(find.text('Export Successful'), findsOneWidget);
    });
  });
}

// Mock widgets for testing
class _MockEditorScreen extends StatelessWidget {
  const _MockEditorScreen();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Select Image'),
        ElevatedButton(key: const Key('gallery_button'), onPressed: () {}, child: const Text('Gallery')),
        ElevatedButton(key: const Key('blur_button'), onPressed: () {}, child: const Text('Blur')),
        ElevatedButton(key: const Key('export_button'), onPressed: () {}, child: const Text('Export')),
        ElevatedButton(key: const Key('error_trigger_button'), onPressed: () {}, child: const Text('Trigger Error')),
        ElevatedButton(key: const Key('process_button'), onPressed: () {}, child: const Text('Process')),
        ElevatedButton(key: const Key('cancel_button'), onPressed: () {}, child: const Text('Cancel')),
      ],
    );
  }
}

class _MockBlurApp extends StatelessWidget {
  const _MockBlurApp();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [ElevatedButton(onPressed: () {}, child: const Text('Start Editing'))],
    );
  }
}

// Mock service for testing
class _MockDataService {
  final Map<String, dynamic> _storage = {};

  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    _storage.addAll(settings);
  }

  Future<Map<String, dynamic>> loadUserSettings() async {
    return Map.from(_storage);
  }

  void simulateRestart() {
    // In real implementation, this would test actual persistence
  }
}
