import 'dart:typed_data';

import 'package:blurapp/features/editor/blur_engine_mvp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mask to brush strokes', () {
    test('converts mask pixels above threshold into strokes', () {
      const int w = 8;
      const int h = 8;
      final Uint8List mask = Uint8List(w * h);

      // set a few pixels above threshold
      mask[1 * w + 1] = 200;
      mask[2 * w + 2] = 180;
      mask[5 * w + 4] = 255;

      final strokes = BlurEngineMVP.maskToBrushStrokes(mask, w, h,
          stride: 1, threshold: 128, baseSize: 12.0);

      expect(strokes, isNotEmpty);
      // Expect at least 3 strokes for the 3 pixels we set
      expect(strokes.length, greaterThanOrEqualTo(3));

      // Check one stroke matches an opacity value from mask
      final opacities = strokes.map((s) => s.opacity).toList();
      expect(opacities, contains(200));
      expect(opacities, contains(180));
      expect(opacities, contains(255));
    });
  });
}
