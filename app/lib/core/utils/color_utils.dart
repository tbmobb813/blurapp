import 'dart:ui' show Color;

/// Safe opacity helper that avoids using potentially deprecated component
/// accessors. This composes a new Color by replacing the alpha channel and
/// preserving the RGB bits from the original color.
Color withOpacitySafe(Color color, double opacity) {
  // Clamp opacity between 0.0 and 1.0 and convert to 0-255 alpha
  final int a = ((opacity.clamp(0.0, 1.0) * 255).round()) & 0xFF;
  // Use the built-in withAlpha which preserves RGB channels and updates
  // the alpha channel. This avoids accessing the (deprecated) `.value`
  // field or relying on component accessors that may vary across SDKs.
  return color.withAlpha(a);
}
