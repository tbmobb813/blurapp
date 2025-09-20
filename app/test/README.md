# BlurApp Testing Framework

This directory contains a standardized testing framework for the BlurApp project, providing consistent testing patterns across different levels of functionality.

## Testing Levels

### 🔴 CORE Tests - Essential Business Logic

**Priority:** CRITICAL - Must always pass  
**Run Time:** < 100ms per test  
**Coverage:** Essential algorithms, data validation, core calculations

Core tests verify the fundamental business logic that the app depends on:

- Image processing algorithms (blur, pixelate, mosaic)
- Data validation and error handling
- Essential service operations
- Core state management

**Example:**

```dart
BlurAppTestFramework.testCase(
  'blur algorithm produces valid output for all supported strengths',
  () {
    // Test core business logic
  },
  level: TestLevel.core,
);
```

### 🟡 CRITICAL Tests - User-Facing Features  

**Priority:** HIGH - Should always pass  
**Run Time:** < 500ms per test  
**Coverage:** Primary user interactions, UI workflows, error handling

Critical tests verify user-facing features that impact the core workflow:

- Complete user flows (image → edit → export)
- UI state transitions
- Error handling and recovery
- Performance under normal usage

**Example:**

```dart
BlurAppTestFramework.widgetTest(
  'user can complete full blur workflow',
  (tester) async {
    // Test complete user scenario
  },
  level: TestLevel.critical,
);
```

### 🟢 MISC Tests - Supporting Features

**Priority:** MEDIUM - Nice to have  
**Run Time:** Variable  
**Coverage:** Edge cases, performance, accessibility, optional features

Miscellaneous tests cover supporting features and edge cases:

- Boundary conditions and edge cases
- Performance benchmarks
- Accessibility compliance
- Internationalization
- Graceful degradation

**Example:**

```dart
BlurAppTestFramework.performanceTest(
  'image resizing completes within threshold',
  () async {
    // Test performance constraints
  },
  maxDuration: Duration(milliseconds: 50),
);
```

## Framework Components

### BlurAppTestFramework

Main testing utility providing standardized test methods:

- `testGroup()` - Grouped tests with setup
- `testCase()` - Standard unit tests
- `widgetTest()` - Widget testing with app wrapper
- `asyncTest()` - Async operations with timeout
- `performanceTest()` - Performance benchmarking
- `integrationTest()` - End-to-end scenarios

### TestHelpers

Common utilities for test setup and assertions:

- `createTestImageBytes()` - Generate test data
- `waitForAsync()` - Wait for async operations
- `pumpAndSettle()` - Widget tree updates
- `tapAndSettle()` - UI interactions
- `findTextWidget()` - Enhanced widget finding

### BlurAppAssertions

Domain-specific assertions for BlurApp:

- `assertValidImageResult()` - Image processing validation
- `assertValidBlurParams()` - Parameter validation
- `assertUIStateTransition()` - UI state verification
- `assertServiceInitialized()` - Service validation
- `assertFileExists()` - File operation validation

## Running Tests

### Run All Tests

```bash
flutter test
```

### Run by Category

```bash
# Core tests only (fastest)
flutter test test/unit/

# Widget tests only
flutter test test/widget_test.dart

# Specific test file
flutter test test/unit/blur_pipeline_test.dart
```

### Test Runner

Use the test runner for organized execution:

```bash
flutter test test/test_runner.dart
```

## Test Templates

The `templates/` directory contains example test patterns:

- `core_test_template.dart` - Core business logic patterns
- `critical_test_template.dart` - User workflow patterns  
- `misc_test_template.dart` - Edge case and performance patterns

## Best Practices

### Core Tests

- ✅ Test pure functions and algorithms
- ✅ Cover all critical code paths
- ✅ Use deterministic test data
- ✅ Keep tests fast (< 100ms)
- ❌ No external dependencies
- ❌ No UI testing
- ❌ No network calls

### Critical Tests  

- ✅ Test complete user scenarios
- ✅ Verify UI state changes
- ✅ Include error handling
- ✅ Use realistic test data
- ❌ Don't test implementation details
- ❌ Don't mock core business logic

### Misc Tests

- ✅ Test edge cases and boundaries
- ✅ Include performance benchmarks
- ✅ Test accessibility features
- ✅ Verify graceful degradation
- ⚠️ Can be skipped in CI if needed
- ⚠️ Allowed to have longer timeouts

## File Structure

```
test/
├── test_framework.dart          # Core testing framework
├── test_runner.dart            # Categorized test execution
├── templates/                  # Example test patterns
│   ├── core_test_template.dart
│   ├── critical_test_template.dart
│   └── misc_test_template.dart
├── unit/                       # Core business logic tests
│   ├── auto_detect_service_test.dart
│   └── blur_pipeline_test.dart
├── widget_test.dart           # Critical UI workflow tests
└── integration/               # End-to-end scenarios (future)
```

## CI/CD Integration

Recommended test execution for different environments:

**Pre-commit Hook:**

```bash
flutter test test/unit/  # Core tests only
```

**Pull Request:**

```bash
flutter test test/unit/ test/widget_test.dart  # Core + Critical
```

**Release Pipeline:**

```bash
flutter test  # All tests
```

## Adding New Tests

1. **Identify Test Level:**
   - Core: Pure business logic
   - Critical: User-facing workflows
   - Misc: Edge cases and performance

2. **Use Framework:**

   ```dart
   BlurAppTestFramework.testCase(
     'descriptive test name',
     () {
       // Test implementation
     },
     level: TestLevel.core, // or critical, misc
   );
   ```

3. **Follow Patterns:**
   - Check templates for examples
   - Use helper methods for setup
   - Use assertions for validation
   - Include appropriate timeout/skip options

4. **Update Test Runner:**
   - Add new test files to test_runner.dart
   - Categorize appropriately

## Troubleshooting

### Common Issues

**Binding not initialized:**

```dart
// Add this to test setup
BlurAppTestFramework.setupTest();
```

**Widget not found:**

```dart
// Use helper for better error messages
TestHelpers.findTextWidget('Button Text');
```

**Async operation timeout:**

```dart
// Increase timeout for slow operations
BlurAppTestFramework.asyncTest(
  'slow operation',
  () async { /* ... */ },
  timeout: Timeout(Duration(seconds: 60)),
);
```

**Performance test failure:**

```dart
// Adjust performance expectations
BlurAppTestFramework.performanceTest(
  'operation performance',
  () async { /* ... */ },
  maxDuration: Duration(milliseconds: 200), // Adjust as needed
);
```
