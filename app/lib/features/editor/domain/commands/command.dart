import 'package:blurapp/features/editor/domain/entities/editor_state.dart';

/// Base interface for all commands
/// Commands encapsulate state changes and support undo/redo
abstract class Command {
  /// Unique identifier for this command
  String get id;

  /// Execute the command and return new state
  EditorState execute(EditorState currentState);

  /// Undo the command and return previous state
  EditorState undo(EditorState currentState);

  /// Get a description of what this command does
  String get description;

  /// Check if this command can be merged with another
  /// Used to combine multiple small edits into one undo step
  bool canMergeWith(Command other) => false;

  /// Merge this command with another
  Command? mergeWith(Command other) => null;
}

/// Command that can be undone
abstract class UndoableCommand extends Command {
  @override
  final String id;
  @override
  final String description;

  UndoableCommand({
    required this.id,
    required this.description,
  });
}
