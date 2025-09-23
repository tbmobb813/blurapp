import 'dart:ui' show Color;

/// Safe opacity helper that avoids using potentially deprecated component
/// accessors. This composes a new Color by replacing the alpha channel and
/// preserving the RGB bits from the original color.
Color withOpacitySafe(Color color, double opacity) {
  // Clamp opacity between 0.0 and 1.0 and convert to 0-255 alpha
  final int a = ((opacity.clamp(0.0, 1.0) * 255).round()) & 0xFF;

  // Preserve RGB components and set new alpha using toARGB32()
  final int argb = color.toARGB32();
  final int rgb = argb & 0x00FFFFFF;
  return Color((a << 24) | rgb);
}
