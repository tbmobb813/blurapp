import 'package:blurapp/features/editor/domain/entities/blur_settings.dart';
import 'package:blurapp/features/editor/domain/entities/editor_state.dart';
import 'command.dart';

/// Command to change blur settings
class ChangeBlurSettingsCommand extends UndoableCommand {
  final BlurSettings newSettings;
  final BlurSettings previousSettings;

  ChangeBlurSettingsCommand({
    required this.newSettings,
    required this.previousSettings,
    String? id,
  }) : super(
          id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          description: 'Change blur settings',
        );

  @override
  EditorState execute(EditorState currentState) {
    return currentState.copyWith(blurSettings: newSettings);
  }

  @override
  EditorState undo(EditorState currentState) {
    return currentState.copyWith(blurSettings: previousSettings);
  }
}

/// Command to clear all strokes
class ClearStrokesCommand extends UndoableCommand {
  final List<BrushStroke> previousStrokes;

  ClearStrokesCommand({
    required this.previousStrokes,
    String? id,
  }) : super(
          id: id ?? DateTime.now().millisecondsSinceEpoch.toString(),
          description: 'Clear all strokes',
        );

  @override
  EditorState execute(EditorState currentState) {
    return currentState.copyWith(strokes: []);
  }

  @override
  EditorState undo(EditorState currentState) {
    return currentState.copyWith(strokes: previousStrokes);
  }
}
