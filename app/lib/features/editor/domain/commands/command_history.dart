import 'package:freezed_annotation/freezed_annotation.dart';
import 'command.dart';

part 'command_history.freezed.dart';

/// Manages command history for undo/redo functionality
@freezed
class CommandHistory with _$CommandHistory {
  const factory CommandHistory({
    @Default([]) List<Command> undoStack,
    @Default([]) List<Command> redoStack,
    @Default(100) int maxHistorySize,
  }) = _CommandHistory;

  const CommandHistory._();

  /// Check if undo is available
  bool get canUndo => undoStack.isNotEmpty;

  /// Check if redo is available
  bool get canRedo => redoStack.isNotEmpty;

  /// Get number of undo steps available
  int get undoCount => undoStack.length;

  /// Get number of redo steps available
  int get redoCount => redoStack.length;

  /// Add a command to history
  CommandHistory addCommand(Command command) {
    var newUndoStack = List<Command>.from(undoStack);

    // Try to merge with last command if possible
    if (newUndoStack.isNotEmpty) {
      final lastCommand = newUndoStack.last;
      if (lastCommand.canMergeWith(command)) {
        final merged = lastCommand.mergeWith(command);
        if (merged != null) {
          newUndoStack[newUndoStack.length - 1] = merged;
          return copyWith(
            undoStack: newUndoStack,
            redoStack: [], // Clear redo stack on new command
          );
        }
      }
    }

    // Add new command
    newUndoStack.add(command);

    // Trim history if needed
    if (newUndoStack.length > maxHistorySize) {
      newUndoStack = newUndoStack.sublist(
        newUndoStack.length - maxHistorySize,
      );
    }

    return copyWith(
      undoStack: newUndoStack,
      redoStack: [], // Clear redo stack on new command
    );
  }

  /// Move last command from undo to redo stack
  CommandHistory moveToRedo() {
    if (!canUndo) return this;

    final newUndoStack = List<Command>.from(undoStack);
    final command = newUndoStack.removeLast();

    return copyWith(
      undoStack: newUndoStack,
      redoStack: [...redoStack, command],
    );
  }

  /// Move last command from redo to undo stack
  CommandHistory moveToUndo() {
    if (!canRedo) return this;

    final newRedoStack = List<Command>.from(redoStack);
    final command = newRedoStack.removeLast();

    return copyWith(
      undoStack: [...undoStack, command],
      redoStack: newRedoStack,
    );
  }

  /// Get the last command that can be undone
  Command? get lastCommand => canUndo ? undoStack.last : null;

  /// Get the last command that can be redone
  Command? get nextCommand => canRedo ? redoStack.last : null;

  /// Clear all history
  CommandHistory clear() {
    return const CommandHistory();
  }

  /// Get memory estimate (rough approximation)
  int get estimatedMemoryBytes {
    // Very rough estimate: 1KB per command
    return (undoStack.length + redoStack.length) * 1024;
  }
}
