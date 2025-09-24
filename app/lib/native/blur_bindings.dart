import 'dart:typed_data';

// Stub implementation for native blur bindings
// NOTE: This file provides a lightweight, safe stub to be used until
// a proper native/FFI implementation is available.
//
// When the native blur implementation is ready, replace this class with
// real FFI bindings (using `dart:ffi` and a shared library). Keep the
// same public API so the rest of the app can switch to native code with
// minimal changes.

class FfiBlur {
  FfiBlur();

  /// Apply blur effect to image pixels.
  ///
  /// Parameters:
  /// - [pixels]: raw RGBA bytes (length should be width * height * 4)
  /// - [width],[height]: image dimensions
  /// - [rects]: list of 4-int rectangles (l,t,r,b) flattened or empty to apply to whole image
  /// - [mode]: blur mode id (0 = gaussian, 1 = pixelate, etc.)
  /// - [strength]: blur strength (0-100)
  ///
  /// Returns 0 on success, non-zero on error. Currently this is a no-op
  /// stub that returns success so higher-level code can be exercised in tests.
  int apply(Uint8List pixels, int width, int height, List<int> rects, int mode,
      int strength) {
  // For now, do a basic validation to help catch incorrect usage in tests.
    if (pixels.length < width * height * 4) return 1;
    // No-op success
    return 0;
  }
}
