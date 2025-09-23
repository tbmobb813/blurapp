import 'package:flutter_test/flutter_test.dart';

import 'test_setup.dart';
import 'unit/auto_detect_service_test.dart' as auto_detect_tests;
import 'unit/blur_pipeline_test.dart' as blur_pipeline_tests;
import 'widget_test.dart' as widget_tests;

/// Test runner for BlurApp with categorized execution
///
/// This allows running tests by priority level:
/// - Core tests: Essential functionality that must never fail
/// - Critical tests: User-facing features and workflows
/// - Misc tests: Edge cases, performance, and optional features
void main() {
  // Initialize global test bootstrap (inject test providers, etc.)
  initTestBootstrap();
  group('BlurApp Test Suite', () {
    group('🔴 CORE Tests - Essential Business Logic', () {
      auto_detect_tests.main();
      blur_pipeline_tests.main();
    });

    group('🟡 CRITICAL Tests - User Workflows', () {
      widget_tests.main();
    });

    group('🟢 MISC Tests - Edge Cases & Performance', () {
      // Additional miscellaneous tests can be added here
    });
  });
}

/// Helper to run only core tests for quick validation
void runCoreTests() {
  group('Core Tests Only', () {
    auto_detect_tests.main();
    blur_pipeline_tests.main();
  });
}

/// Helper to run only critical tests for UI validation
void runCriticalTests() {
  group('Critical Tests Only', () {
    widget_tests.main();
  });
}
