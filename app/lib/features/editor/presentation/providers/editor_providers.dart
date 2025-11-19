import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blurapp/shared/domain/entities/image_data.dart';
import 'package:blurapp/features/editor/domain/entities/editor_state.dart';
import 'package:blurapp/features/editor/domain/entities/brush_stroke.dart';
import 'package:blurapp/features/editor/domain/entities/blur_settings.dart';
import 'package:blurapp/features/editor/domain/commands/command.dart';
import 'package:blurapp/features/editor/domain/commands/command_history.dart';
import 'package:blurapp/features/editor/domain/commands/add_stroke_command.dart';
import 'package:blurapp/features/editor/domain/commands/change_blur_settings_command.dart';
import 'package:blurapp/features/editor/domain/repositories/image_repository.dart';
import 'package:blurapp/features/editor/domain/repositories/blur_repository.dart';
import 'package:blurapp/features/editor/domain/use_cases/load_image_use_case.dart';
import 'package:blurapp/features/editor/domain/use_cases/apply_blur_use_case.dart';
import 'package:blurapp/shared/errors/result.dart';

/// Editor state notifier with undo/redo support
class EditorNotifier extends StateNotifier<EditorState> {
  CommandHistory _history = const CommandHistory();

  EditorNotifier() : super(const EditorState());

  /// Get current command history
  CommandHistory get history => _history;

  /// Check if undo is available
  bool get canUndo => _history.canUndo;

  /// Check if redo is available
  bool get canRedo => _history.canRedo;

  /// Add a brush stroke
  void addStroke(BrushStroke stroke) {
    final command = AddStrokeCommand(stroke: stroke);
    _executeCommand(command);
  }

  /// Change blur settings
  void changeBlurSettings(BlurSettings newSettings) {
    final command = ChangeBlurSettingsCommand(
      newSettings: newSettings,
      previousSettings: state.blurSettings,
    );
    _executeCommand(command);
  }

  /// Clear all strokes
  void clearStrokes() {
    final command = ClearStrokesCommand(
      previousStrokes: state.strokes,
    );
    _executeCommand(command);
  }

  /// Undo last command
  void undo() {
    if (!canUndo) return;

    final command = _history.lastCommand;
    if (command == null) return;

    state = command.undo(state);
    _history = _history.moveToRedo();
  }

  /// Redo last undone command
  void redo() {
    if (!canRedo) return;

    final command = _history.nextCommand;
    if (command == null) return;

    state = command.execute(state);
    _history = _history.moveToUndo();
  }

  /// Execute a command and add to history
  void _executeCommand(Command command) {
    state = command.execute(state);
    _history = _history.addCommand(command);
  }

  /// Set processing state
  void setProcessing(bool isProcessing) {
    state = state.copyWith(isProcessing: isProcessing);
  }

  /// Set preview image
  void setPreviewImage(ImageData? image) {
    state = state.copyWith(previewImage: image);
  }

  /// Set original image
  void setOriginalImage(ImageData? image) {
    state = state.copyWith(
      originalImage: image,
      strokes: [], // Clear strokes when new image loaded
    );
    _history = const CommandHistory(); // Clear history
  }

  /// Set error message
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Editor state provider
final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>(
  (ref) => EditorNotifier(),
);

/// Undo availability provider
final canUndoProvider = Provider<bool>((ref) {
  final notifier = ref.watch(editorProvider.notifier);
  ref.watch(editorProvider); // Trigger rebuild on state change
  return notifier.canUndo;
});

/// Redo availability provider
final canRedoProvider = Provider<bool>((ref) {
  final notifier = ref.watch(editorProvider.notifier);
  ref.watch(editorProvider); // Trigger rebuild on state change
  return notifier.canRedo;
});

/// Current brush size provider
final brushSizeProvider = Provider<double>((ref) {
  return ref.watch(editorProvider.select((state) => state.brushSize));
});

/// Current blur settings provider
final blurSettingsProvider = Provider<BlurSettings>((ref) {
  return ref.watch(editorProvider.select((state) => state.blurSettings));
});

/// Has image loaded provider
final hasImageProvider = Provider<bool>((ref) {
  return ref.watch(editorProvider.select((state) => state.hasImage));
});

/// Can export provider
final canExportProvider = Provider<bool>((ref) {
  return ref.watch(editorProvider.select((state) => state.canExport));
});

// =============================================================================
// Repository Providers
// =============================================================================
// Note: These are placeholder providers. In Phase 2, we'll implement the data
// layer and replace these with actual repository implementations.

/// Image repository provider
/// TODO: Replace with actual implementation in data layer
final imageRepositoryProvider = Provider<ImageRepository>((ref) {
  throw UnimplementedError(
    'ImageRepository not yet implemented. '
    'This will be added in Phase 2 (Data Layer)',
  );
});

/// Blur repository provider
/// TODO: Replace with actual implementation in data layer
final blurRepositoryProvider = Provider<BlurRepository>((ref) {
  throw UnimplementedError(
    'BlurRepository not yet implemented. '
    'This will be added in Phase 2 (Data Layer)',
  );
});

// =============================================================================
// Use Case Providers
// =============================================================================

/// Load image use case provider
final loadImageUseCaseProvider = Provider<LoadImageUseCase>((ref) {
  final repository = ref.watch(imageRepositoryProvider);
  return LoadImageUseCase(repository);
});

/// Apply blur use case provider
final applyBlurUseCaseProvider = Provider<ApplyBlurUseCase>((ref) {
  final repository = ref.watch(blurRepositoryProvider);
  return ApplyBlurUseCase(repository);
});
