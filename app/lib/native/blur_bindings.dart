import 'dart:typed_data';

// Stub implementation for native blur bindings
// TODO: Implement proper FFI bindings when native blur is ready
class FfiBlur {
  FfiBlur();

  /// Apply blur effect to image pixels
  /// Returns 0 on success, non-zero on error
  int apply(Uint8List pixels, int width, int height, List<int> rects, int mode,
      int strength) {
    // Stub implementation - just return success
    // In a real implementation, this would call native blur functions
    return 0;
  }
}
