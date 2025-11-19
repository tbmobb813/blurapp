/// Example demonstrating the Clean Architecture implementation
///
/// This file shows how to use:
/// - Domain entities (EditorState, BrushStroke, BlurSettings)
/// - Commands (AddStrokeCommand, ChangeBlurSettingsCommand)
/// - Use cases (LoadImageUseCase, ApplyBlurUseCase)
/// - Riverpod providers (editorProvider, use case providers)
/// - Result<T> error handling
///
/// This is a reference implementation showing best practices.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:blurapp/features/editor/domain/entities/brush_stroke.dart';
import 'package:blurapp/features/editor/domain/entities/blur_settings.dart';
import 'package:blurapp/features/editor/domain/use_cases/load_image_use_case.dart';
import 'package:blurapp/features/editor/domain/use_cases/apply_blur_use_case.dart';
import 'package:blurapp/features/editor/presentation/providers/editor_providers.dart';

// =============================================================================
// Example 1: Basic Editor Widget with Undo/Redo
// =============================================================================

/// Example widget showing how to use the editor state and commands
class EditorExample extends ConsumerWidget {
  const EditorExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch editor state - widget rebuilds when state changes
    final editorState = ref.watch(editorProvider);

    // Get notifier for calling actions
    final editorNotifier = ref.read(editorProvider.notifier);

    // Watch computed providers
    final canUndo = ref.watch(canUndoProvider);
    final canRedo = ref.watch(canRedoProvider);
    final hasImage = ref.watch(hasImageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clean Architecture Example'),
        actions: [
          // Undo button - disabled when canUndo is false
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: canUndo ? () => editorNotifier.undo() : null,
            tooltip: 'Undo',
          ),
          // Redo button - disabled when canRedo is false
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: canRedo ? () => editorNotifier.redo() : null,
            tooltip: 'Redo',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status display
          _StatusDisplay(
            hasImage: hasImage,
            strokeCount: editorState.strokes.length,
            canUndo: canUndo,
            canRedo: canRedo,
          ),

          // Error display
          if (editorState.error != null)
            _ErrorBanner(
              error: editorState.error!,
              onDismiss: () => editorNotifier.clearError(),
            ),

          // Image display area
          Expanded(
            child: hasImage
                ? _ImageCanvas(
                    image: editorState.originalImage!,
                    strokes: editorState.strokes,
                    onStrokeAdded: (stroke) => editorNotifier.addStroke(stroke),
                  )
                : const Center(child: Text('No image loaded')),
          ),

          // Blur settings panel
          _BlurSettingsPanel(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLoadImageExample(context, ref),
        child: const Icon(Icons.add_photo_alternate),
        tooltip: 'Load Image (Example)',
      ),
    );
  }

  /// Example of loading an image using the use case
  void _showLoadImageExample(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Load Image Example'),
        content: const Text(
          'This demonstrates how to use LoadImageUseCase.\n\n'
          'In a real app, you would:\n'
          '1. Pick an image from gallery/camera\n'
          '2. Call the use case with the image path\n'
          '3. Handle the Result<ImageData> response\n'
          '4. Update the editor state',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Example 2: Using Use Cases with Error Handling
// =============================================================================

/// Example showing how to call use cases and handle Results
class UseLoadImageExample {
  final LoadImageUseCase _loadImageUseCase;
  final EditorNotifier _editorNotifier;

  UseLoadImageExample(this._loadImageUseCase, this._editorNotifier);

  /// Load an image with proper error handling
  Future<void> loadImage(String imagePath) async {
    // Set processing state
    _editorNotifier.setProcessing(true);
    _editorNotifier.clearError();

    // Call the use case
    final result = await _loadImageUseCase(
      LoadImageParams(
        path: imagePath,
        maxWidth: 2048,
        maxHeight: 2048,
      ),
    );

    // Handle the result using pattern matching
    result.when(
      success: (imageData) {
        // Success - update state with loaded image
        _editorNotifier.setOriginalImage(imageData);
        _editorNotifier.setProcessing(false);
      },
      failure: (failure) {
        // Failure - show error to user
        failure.when(
          imageLoad: (message, error) {
            _editorNotifier.setError('Failed to load image: $message');
          },
          outOfMemory: (message, requiredBytes, availableBytes) {
            _editorNotifier.setError(
              'Image too large: $message\n'
              'Required: ${_formatBytes(requiredBytes)}, '
              'Available: ${_formatBytes(availableBytes)}',
            );
          },
          permission: (message, permissionType) {
            _editorNotifier.setError(
              'Permission denied: $message\n'
              'Please grant $permissionType permission',
            );
          },
          // Handle other failure types...
          imageProcess: (message, error) {
            _editorNotifier.setError('Processing error: $message');
          },
          imageSave: (message, error) {
            _editorNotifier.setError('Save error: $message');
          },
          modelLoad: (message, modelPath) {
            _editorNotifier.setError('Model load error: $message');
          },
          unknown: (message, error, stackTrace) {
            _editorNotifier.setError('Unknown error: $message');
          },
        );
        _editorNotifier.setProcessing(false);
      },
    );
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return 'Unknown';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Example showing how to apply blur with use case
class UseApplyBlurExample {
  final ApplyBlurUseCase _applyBlurUseCase;
  final EditorNotifier _editorNotifier;

  UseApplyBlurExample(this._applyBlurUseCase, this._editorNotifier);

  /// Apply blur with error handling
  Future<void> applyBlur() async {
    final state = _editorNotifier.state;

    if (state.originalImage == null) {
      _editorNotifier.setError('No image loaded');
      return;
    }

    _editorNotifier.setProcessing(true);

    final result = await _applyBlurUseCase(
      ApplyBlurParams(
        image: state.originalImage!,
        strokes: state.strokes,
        settings: state.blurSettings,
      ),
    );

    result.when(
      success: (blurredImage) {
        _editorNotifier.setPreviewImage(blurredImage);
        _editorNotifier.setProcessing(false);
      },
      failure: (failure) {
        _editorNotifier.setError('Blur failed: ${failure.toString()}');
        _editorNotifier.setProcessing(false);
      },
    );
  }
}

// =============================================================================
// Example 3: Using Commands for Undo/Redo
// =============================================================================

/// Example showing how commands enable undo/redo
class CommandExample extends ConsumerWidget {
  const CommandExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorNotifier = ref.read(editorProvider.notifier);

    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // When you call addStroke, it:
            // 1. Creates an AddStrokeCommand
            // 2. Executes it (adds stroke to state)
            // 3. Adds command to history for undo/redo
            final stroke = BrushStroke(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              points: [
                BrushPoint(x: 100, y: 100, pressure: 1.0),
                BrushPoint(x: 200, y: 200, pressure: 1.0),
              ],
              size: 50,
            );
            editorNotifier.addStroke(stroke);
          },
          child: const Text('Add Stroke (Undoable)'),
        ),
        ElevatedButton(
          onPressed: () {
            // Changing blur settings also creates a command
            // Previous settings are stored for undo
            final newSettings = const BlurSettings(
              type: BlurType.mosaic,
              strength: 0.8,
            );
            editorNotifier.changeBlurSettings(newSettings);
          },
          child: const Text('Change Blur Settings (Undoable)'),
        ),
        ElevatedButton(
          onPressed: () {
            // Undo reverts the last command
            // Command history moves command to redo stack
            editorNotifier.undo();
          },
          child: const Text('Undo'),
        ),
        ElevatedButton(
          onPressed: () {
            // Redo re-executes last undone command
            // Command history moves command back to undo stack
            editorNotifier.redo();
          },
          child: const Text('Redo'),
        ),
      ],
    );
  }
}

// =============================================================================
// Example 4: Dependency Injection with Riverpod
// =============================================================================

/// Example showing how to inject use cases in widgets
class DependencyInjectionExample extends ConsumerWidget {
  const DependencyInjectionExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        // Get use cases from providers - they're automatically created
        // with their repository dependencies injected
        final loadImageUseCase = ref.read(loadImageUseCaseProvider);
        final applyBlurUseCase = ref.read(applyBlurUseCaseProvider);
        final editorNotifier = ref.read(editorProvider.notifier);

        // Use the helper classes
        final loadHelper = UseLoadImageExample(loadImageUseCase, editorNotifier);
        final blurHelper = UseApplyBlurExample(applyBlurUseCase, editorNotifier);

        // Call them
        await loadHelper.loadImage('/path/to/image.jpg');
        await blurHelper.applyBlur();
      },
      child: const Text('Load and Blur Image'),
    );
  }
}

// =============================================================================
// Supporting Widgets (Simplified for Example)
// =============================================================================

class _StatusDisplay extends StatelessWidget {
  final bool hasImage;
  final int strokeCount;
  final bool canUndo;
  final bool canRedo;

  const _StatusDisplay({
    required this.hasImage,
    required this.strokeCount,
    required this.canUndo,
    required this.canRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('Image: ${hasImage ? "Loaded" : "None"}'),
          Text('Strokes: $strokeCount'),
          Text('Can Undo: $canUndo'),
          Text('Can Redo: $canRedo'),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;

  const _ErrorBanner({
    required this.error,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red[100],
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(error)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _ImageCanvas extends StatelessWidget {
  final dynamic image;
  final List<BrushStroke> strokes;
  final ValueChanged<BrushStroke> onStrokeAdded;

  const _ImageCanvas({
    required this.image,
    required this.strokes,
    required this.onStrokeAdded,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('[Image Canvas Placeholder]'));
  }
}

class _BlurSettingsPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(blurSettingsProvider);
    final editorNotifier = ref.read(editorProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Blur Type: ${settings.type.name}'),
          Slider(
            value: settings.strength,
            onChanged: (value) {
              editorNotifier.changeBlurSettings(
                settings.copyWith(strength: value),
              );
            },
            label: 'Strength: ${(settings.strength * 100).round()}%',
          ),
        ],
      ),
    );
  }
}
