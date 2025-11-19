import 'package:freezed_annotation/freezed_annotation.dart';

part 'blur_settings.freezed.dart';

/// Blur configuration settings
@freezed
class BlurSettings with _$BlurSettings {
  const factory BlurSettings({
    @Default(BlurType.gaussian) BlurType type,
    @Default(0.5) double strength, // 0.0 to 1.0
    @Default(512) int previewWidth,
    @Default(512) int previewHeight,
  }) = _BlurSettings;

  const BlurSettings._();

  /// Get blur strength as integer (0-100)
  int get strengthAsInt => (strength * 100).round();

  /// Get blur strength for processing (type-specific)
  int get processingStrength {
    return switch (type) {
      BlurType.gaussian => (strength * 32).clamp(1, 32).toInt(),
      BlurType.pixelate => (strength * 32).clamp(1, 32).toInt(),
      BlurType.mosaic => (strength * 32).clamp(1, 32).toInt(),
    };
  }

  /// Check if settings are valid
  bool get isValid {
    return strength >= 0.0 &&
        strength <= 1.0 &&
        previewWidth > 0 &&
        previewHeight > 0;
  }

  /// Create settings with validated strength
  BlurSettings withValidatedStrength(double newStrength) {
    return copyWith(strength: newStrength.clamp(0.0, 1.0));
  }
}

/// Types of blur effects
enum BlurType {
  gaussian,
  pixelate,
  mosaic;

  String get displayName => switch (this) {
        BlurType.gaussian => 'Gaussian Blur',
        BlurType.pixelate => 'Pixelate',
        BlurType.mosaic => 'Mosaic',
      };

  String get description => switch (this) {
        BlurType.gaussian => 'Smooth, natural blur',
        BlurType.pixelate => 'Block-based pixelation',
        BlurType.mosaic => 'Color-averaged mosaic effect',
      };
}
