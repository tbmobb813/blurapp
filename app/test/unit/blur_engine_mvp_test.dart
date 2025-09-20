import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:blurapp/features/editor/blur_engine_mvp.dart';

void main() {
  group('BlurEngineMVP Tests', () {
    test('createBrushMask should generate valid mask', () async {
      // Arrange
      const int width = 100;
      const int height = 100;
      final List<BrushStroke> strokes = [
        const BrushStroke(
          points: [Point(50, 50)],
          size: 20,
          opacity: 255,
        ),
      ];

      // Act
      final Uint8List mask = await BlurEngineMVP.createBrushMask(
        width: width,
        height: height,
        brushStrokes: strokes,
      );

      // Assert
      expect(mask.length, equals(width * height));
      expect(mask, isA<Uint8List>());
    });

    test('generateFaceMask should return placeholder mask', () async {
      // Arrange
      const int width = 100;
      const int height = 100;
      final Uint8List dummyImageBytes =
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG header

      // Act
      final Uint8List? mask = await BlurEngineMVP.generateFaceMask(
        imageBytes: dummyImageBytes,
        width: width,
        height: height,
      );

      // Assert
      expect(mask, isNotNull);
      expect(mask!.length, equals(width * height));
    });

    test('BlurType enum should have expected values', () {
      // Assert
      expect(BlurType.values.length, equals(3));
      expect(BlurType.values, contains(BlurType.gaussian));
      expect(BlurType.values, contains(BlurType.pixelate));
      expect(BlurType.values, contains(BlurType.mosaic));
    });

    test('BrushStroke should create valid instances', () {
      // Arrange & Act
      const stroke = BrushStroke(
        points: [Point(10, 20), Point(30, 40)],
        size: 15.5,
        opacity: 128,
      );

      // Assert
      expect(stroke.points.length, equals(2));
      expect(stroke.points[0].x, equals(10));
      expect(stroke.points[0].y, equals(20));
      expect(stroke.points[1].x, equals(30));
      expect(stroke.points[1].y, equals(40));
      expect(stroke.size, equals(15.5));
      expect(stroke.opacity, equals(128));
    });

    test('Point should create valid instances', () {
      // Arrange & Act
      const point = Point(123.45, 678.90);

      // Assert
      expect(point.x, equals(123.45));
      expect(point.y, equals(678.90));
    });
  });
}
