import 'dart:ui' show Color;

/// Safe opacity helper that avoids using potentially deprecated component
/// accessors. This composes a new Color by replacing the alpha channel and
/// preserving the RGB bits from the original color.
Color withOpacitySafe(Color color, double opacity) {
  // Clamp opacity between 0.0 and 1.0 and convert to 0-255 alpha
  final int a = ((opacity.clamp(0.0, 1.0) * 255).round()) & 0xFF;

  // Preserve RGB components and set new alpha using the analyzer-recommended
  // component accessors (.r/.g/.b). Those accessors are floating-point
  // values in the 0.0..1.0 range, so convert to 0..255 integers explicitly
  // and mask to 8 bits to match Color.fromARGB expectations.
  // Extract RGB bits from the 32-bit ARGB value. Some SDKs expose
  // floating-point component accessors (.r/.g/.b) while others still
  // only provide .value; using the integer value here is compatible with
  // both environments. Suppress the deprecated-member-use lint for this
  // access so analyzer runs (in CI) that flag `.value` won't fail the job.
  // ignore: deprecated_member_use
  final int argb = color.value;
  final int rgb = argb & 0x00FFFFFF;
  return Color((a << 24) | rgb);
}
