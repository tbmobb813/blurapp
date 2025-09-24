import 'dart:typed_data';

/// Nearest-neighbor downscale for a grayscale mask (one byte per pixel)
Uint8List scaleMaskNearestNeighbor(
    Uint8List src, int srcW, int srcH, int dstW, int dstH) {
  if (src.length < srcW * srcH) return Uint8List(dstW * dstH);
  final Uint8List out = Uint8List(dstW * dstH);
  for (int y = 0; y < dstH; y++) {
    final double srcY = (y + 0.5) * srcH / dstH - 0.5;
    final int sy = srcY.clamp(0, srcH - 1).round();
    for (int x = 0; x < dstW; x++) {
      final double srcX = (x + 0.5) * srcW / dstW - 0.5;
      final int sx = srcX.clamp(0, srcW - 1).round();
      out[y * dstW + x] = src[sy * srcW + sx];
    }
  }
  return out;
}
