import 'package:blurapp/features/editor/domain/entities/brush_stroke.dart';
import 'package:blurapp/features/editor/domain/entities/editor_state.dart';
import 'command.dart';

/// Command to add a brush stroke
class AddStrokeCommand extends UndoableCommand {
  final BrushStroke stroke;

  AddStrokeCommand({
    required this.stroke,
    String? id,
  }) : super(
          id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          description: 'Add brush stroke',
        );

  @override
  EditorState execute(EditorState currentState) {
    return currentState.copyWith(
      strokes: [...currentState.strokes, stroke],
    );
  }

  @override
  EditorState undo(EditorState currentState) {
    // Remove the last stroke (which should be this one)
    final newStrokes = List<BrushStroke>.from(currentState.strokes);
    if (newStrokes.isNotEmpty) {
      newStrokes.removeLast();
    }
    return currentState.copyWith(strokes: newStrokes);
  }

  @override
  bool canMergeWith(Command other) {
    // Can merge consecutive strokes if they're close in time
    if (other is! AddStrokeCommand) return false;

    final thisTime = stroke.createdAt ?? DateTime.now();
    final otherTime = other.stroke.createdAt ?? DateTime.now();
    final timeDiff = thisTime.difference(otherTime).abs();

    return timeDiff.inMilliseconds < 100; // Merge if within 100ms
  }

  @override
  Command? mergeWith(Command other) {
    if (!canMergeWith(other)) return null;

    // For now, just return the newer command
    // In future, could combine strokes intelligently
    return other;
  }
}
