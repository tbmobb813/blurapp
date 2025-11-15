import 'package:freezed_annotation/freezed_annotation.dart';

part 'brush_stroke.freezed.dart';

/// Represents a brush stroke on the canvas
@freezed
class BrushStroke with _$BrushStroke {
  const factory BrushStroke({
    required String id,
    required List<BrushPoint> points,
    required double size,
    @Default(255) int opacity,
    DateTime? createdAt,
  }) = _BrushStroke;

  const BrushStroke._();

  /// Check if stroke is empty
  bool get isEmpty => points.isEmpty;

  /// Check if stroke has multiple points
  bool get isMultiPoint => points.length > 1;

  /// Get bounding box of the stroke
  BrushStrokeBounds get bounds {
    if (points.isEmpty) {
      return const BrushStrokeBounds(
        minX: 0,
        minY: 0,
        maxX: 0,
        maxY: 0,
      );
    }

    double minX = points.first.x;
    double minY = points.first.y;
    double maxX = points.first.x;
    double maxY = points.first.y;

    for (final point in points) {
      if (point.x < minX) minX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.x > maxX) maxX = point.x;
      if (point.y > maxY) maxY = point.y;
    }

    return BrushStrokeBounds(
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
    );
  }

  /// Add a point to the stroke (creates new instance)
  BrushStroke addPoint(BrushPoint point) {
    return copyWith(points: [...points, point]);
  }
}

/// A single point in a brush stroke
@freezed
class BrushPoint with _$BrushPoint {
  const factory BrushPoint({
    required double x,
    required double y,
    DateTime? timestamp,
  }) = _BrushPoint;

  const BrushPoint._();

  /// Calculate distance to another point
  double distanceTo(BrushPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return (dx * dx + dy * dy); // Squared distance (faster, avoid sqrt)
  }
}

/// Bounding box for a brush stroke
@freezed
class BrushStrokeBounds with _$BrushStrokeBounds {
  const factory BrushStrokeBounds({
    required double minX,
    required double minY,
    required double maxX,
    required double maxY,
  }) = _BrushStrokeBounds;

  const BrushStrokeBounds._();

  double get width => maxX - minX;
  double get height => maxY - minY;
  double get centerX => (minX + maxX) / 2;
  double get centerY => (minY + maxY) / 2;
}
