# Tests — helper reference

This short guide explains test bootstrap and helpers used by unit/widget tests in this app.

Key helpers

- `initTestBootstrap()` (in `app/test/test_setup.dart`)
  - Call this at the top of tests to initialize the test shim. It sets `ImageSaverService.provider` to `TestGalleryProvider` and provides a minimal `PathProviderBridge` shim so tests don't depend on platform plugins.

- `TestGalleryProvider` (in `app/test/unit/test_gallery_provider.dart`)
  - Implements `GalleryProvider` for tests and maps document/temporary directories to `Directory.systemTemp`. Simulates successful gallery operations.

- `TestTempUtils` (in `app/test/unit/test_temp_utils.dart`)
  - Small helper to create and safely delete files under `Directory.systemTemp`.
  - Functions: `createTempFile(name, bytes)` and `safeDelete(File)`.

Conventions

- Tests should avoid depending on platform plugins. Use `initTestBootstrap()` to inject `TestGalleryProvider`.
- Write temporary files into `Directory.systemTemp` (via `TestTempUtils`) and always clean them up with `safeDelete`.
- Keep tests deterministic and small — prefer creating minimal valid image bytes (e.g. a 1×1 PNG via the `image` package) for image-processing paths.

Why this exists

- Centralizing temp-file creation and cleanup reduces duplication and flakiness across tests, and makes future improvements (age-based cache policy tests, cleanup boundaries) easier.
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

# Test helpers & conventions

This document is a short reference for the test helpers used by unit and
widget tests in this app. It focuses on the small helpers added in this PR.

Key helpers

- `initTestBootstrap()` — call this in test setup (see `app/test/test_setup.dart`).
  It injects a `TestGalleryProvider` into `ImageSaverService` and provides a
  minimal path-provider shim so tests don't depend on platform plugins.

- `TestGalleryProvider` — located at `app/test/unit/test_gallery_provider.dart`.
  Maps document/temporary directories to `Directory.systemTemp` and simulates
  successful gallery interactions for tests.

- `TestTempUtils` — located at `app/test/unit/test_temp_utils.dart`.
  Small helper to create and safely delete files under `Directory.systemTemp`.
  Functions: `createTempFile(name, bytes)` and `safeDelete(File)`.

Conventions

- Use `initTestBootstrap()` at the top of tests to avoid platform plugin
  dependencies.
- Use `TestTempUtils.createTempFile(...)` and `safeDelete(...)` for temp files
  to keep tests deterministic and to centralize cleanup logic.
- For image-processing paths prefer minimal valid image bytes (for example a
  1x1 PNG generated with the `image` package) to avoid decode/encode flakiness.

Running tests

Run unit tests:

```bash
flutter test test/unit/
```

Run a single test file:

```bash
flutter test test/unit/image_saver_cache_test.dart
```

Purpose

Centralizing temp-file logic reduces duplication and makes it easier to add
additional cache-policy tests in the future (for example age-based cleanup
or limits).
