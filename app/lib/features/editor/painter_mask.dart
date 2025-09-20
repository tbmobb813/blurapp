import 'dart:ui';
import 'package:flutter/material.dart';

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
    strokes.add(MaskStroke(
      points: [rect.topLeft, rect.bottomRight],
      size: feather,
      erase: erase,
      type: type,
      rect: rect,
    ));
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
}

enum MaskType { brush, rectangle, ellipse }

class MaskStroke {
  List<Offset> points;
  double size;
  bool erase;
  MaskType type;
  Rect? rect;
  MaskStroke({
    required this.points,
    required this.size,
    required this.erase,
    required this.type,
    this.rect,
  });
}

class MaskStroke {
  List<Offset> points;
  double size;
  bool erase;
  MaskStroke({required this.points, required this.size, required this.erase});
}
