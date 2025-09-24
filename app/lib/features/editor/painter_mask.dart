import 'dart:typed_data';

import 'package:flutter/material.dart';

class PainterMask extends ChangeNotifier {
  List<MaskStroke> strokes = [];
  MaskStroke? _currentStroke;

  void startStroke(Offset point, double size, bool erase) {
    _currentStroke = MaskStroke(points: [point], size: size, erase: erase, type: MaskType.brush);
    notifyListeners();
  }

  void addPoint(Offset point) {
    if (_currentStroke != null) {
      _currentStroke!.points.add(point);
      notifyListeners();
    }
  }

  void endStroke() {
    if (_currentStroke != null) {
      strokes.add(_currentStroke!);
      _currentStroke = null;
      notifyListeners();
    }
  }

  void addShape(Rect rect, double feather, MaskType type, bool erase) {
    strokes.add(
      MaskStroke(points: [rect.topLeft, rect.bottomRight], size: feather, erase: erase, type: type, rect: rect),
    );
    notifyListeners();
  }

  void undo() {
    if (strokes.isNotEmpty) {
      strokes.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    strokes.clear();
    notifyListeners();
  }

  /// Apply segmentation mask from ML model
  void applySegmentationMask(Uint8List maskBytes) {
    // This is a simplified implementation
    // In a real app, you'd decode the mask image and convert to strokes
    // For now, we'll just add a placeholder stroke
    strokes.add(
      MaskStroke(
        points: [const Offset(0, 0), const Offset(100, 100)],
        size: 1.0,
        erase: false,
        type: MaskType.segmentation,
      ),
    );
    notifyListeners();
  }
}

enum MaskType { brush, rectangle, ellipse, segmentation }

class MaskStroke {
  List<Offset> points;
  double size;
  bool erase;
  MaskType type;
  Rect? rect;

  MaskStroke({required this.points, required this.size, required this.erase, required this.type, this.rect});
}
