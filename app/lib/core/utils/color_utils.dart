import 'package:flutter/painting.dart';

/// Safe opacity helper that avoids using the deprecated `withOpacity` API.
///
/// This uses the color's components and returns a new Color with the
/// requested opacity value. It intentionally avoids calling
/// `Color.withOpacity` to keep analyzer quiet on older/newer SDKs.
Color withOpacitySafe(Color color, double opacity) {
  // Clamp opacity between 0.0 and 1.0 and convert to 0-255 alpha
  final a = (opacity.clamp(0.0, 1.0) * 255).round();
  return Color.fromARGB(a, color.red, color.green, color.blue);
}
