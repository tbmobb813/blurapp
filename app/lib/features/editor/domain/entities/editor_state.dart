import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:blurapp/shared/domain/entities/image_data.dart';
import 'blur_settings.dart';
import 'brush_stroke.dart';

part 'editor_state.freezed.dart';

/// Complete state of the image editor
@freezed
class EditorState with _$EditorState {
  const factory EditorState({
    ImageData? originalImage,
    ImageData? previewImage,
    ImageData? processedImage,
    @Default([]) List<BrushStroke> strokes,
    @Default(BlurSettings()) BlurSettings blurSettings,
    @Default(50.0) double brushSize,
    @Default(EditorMode.brush) EditorMode mode,
    @Default(false) bool isProcessing,
    String? error,
  }) = _EditorState;

  const EditorState._();

  /// Check if editor has an image loaded
  bool get hasImage => originalImage != null;

  /// Check if editor has any strokes
  bool get hasStrokes => strokes.isNotEmpty;

  /// Check if there's anything to undo
  bool get canUndo => strokes.isNotEmpty;

  /// Check if preview is different from original
  bool get hasPreview => previewImage != null;

  /// Check if editor is ready to export
  bool get canExport => hasImage && hasStrokes && !isProcessing;

  /// Get total number of brush points
  int get totalBrushPoints {
    return strokes.fold(0, (sum, stroke) => sum + stroke.points.length);
  }

  /// Check if memory usage is acceptable
  bool get isMemoryHealthy {
    final originalSize = originalImage?.sizeInMB ?? 0;
    final previewSize = previewImage?.sizeInMB ?? 0;
    final processedSize = processedImage?.sizeInMB ?? 0;
    final totalMB = originalSize + previewSize + processedSize;
    return totalMB < 150; // 150MB threshold
  }
}

/// Editor mode (for future expansion)
enum EditorMode {
  brush,
  eraser,
  select; // Future: magic wand, lasso, etc.

  String get displayName => switch (this) {
        EditorMode.brush => 'Brush',
        EditorMode.eraser => 'Eraser',
        EditorMode.select => 'Select',
      };
}
