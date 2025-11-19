# BlurApp Architecture Guide

## Overview

BlurApp follows **Clean Architecture** principles with **Domain-Driven Design** to create a maintainable, testable, and scalable codebase. This architecture separates concerns into distinct layers, making the codebase easier to understand, test, and modify.

## Table of Contents

1. [Architecture Principles](#architecture-principles)
2. [Layer Structure](#layer-structure)
3. [Key Patterns](#key-patterns)
4. [Data Flow](#data-flow)
5. [Error Handling](#error-handling)
6. [State Management](#state-management)
7. [Adding New Features](#adding-new-features)
8. [Migration Guide](#migration-guide)
9. [Testing Strategy](#testing-strategy)
10. [Best Practices](#best-practices)

---

## Architecture Principles

### Clean Architecture Core Concepts

1. **Dependency Rule**: Dependencies point inward. Outer layers can depend on inner layers, but inner layers know nothing about outer layers.
2. **Framework Independence**: Business logic doesn't depend on Flutter or any framework.
3. **Testability**: Business logic can be tested without UI, database, or external services.
4. **UI Independence**: UI can change without affecting business logic.

### Layer Dependency Flow

```
┌──────────────────────────────────────┐
│      Presentation Layer              │  ← User Interface (Widgets, Providers)
│  (Flutter, Riverpod, UI State)       │
└──────────────┬───────────────────────┘
               │ depends on
               ↓
┌──────────────────────────────────────┐
│         Data Layer                   │  ← Implementation Details
│  (Repositories, Data Sources, APIs)  │
└──────────────┬───────────────────────┘
               │ implements
               ↓
┌──────────────────────────────────────┐
│        Domain Layer                  │  ← Business Logic (Pure Dart)
│  (Entities, Repositories, Use Cases) │
└──────────────────────────────────────┘
```

---

## Layer Structure

### Domain Layer (`lib/features/*/domain/`)

**Purpose**: Contains business logic and entities. No dependencies on Flutter or external libraries.

**Components**:

#### 1. Entities
Business objects with identity and behavior.

```dart
// lib/features/editor/domain/entities/brush_stroke.dart
@freezed
class BrushStroke with _$BrushStroke {
  const factory BrushStroke({
    required String id,
    required List<BrushPoint> points,
    required double size,
  }) = _BrushStroke;

  // Business logic methods
  bool get isEmpty => points.isEmpty;
  BrushStrokeBounds get bounds => /* calculate */;
}
```

**Key Entities**:
- `ImageData` - Core image representation
- `BrushStroke` - User brush strokes
- `BlurSettings` - Blur configuration
- `EditorState` - Complete editor state

#### 2. Repository Interfaces
Contracts for data access. Implemented by data layer.

```dart
// lib/features/editor/domain/repositories/image_repository.dart
abstract class ImageRepository {
  Future<Result<ImageData>> loadImage(String path);
  Future<Result<String>> saveImage({
    required ImageData image,
    required String fileName,
  });
}
```

**Key Repositories**:
- `ImageRepository` - Image loading, saving, resizing
- `BlurRepository` - Blur processing, mask generation

#### 3. Use Cases
Orchestrate business logic. One use case = one business operation.

```dart
// lib/features/editor/domain/use_cases/load_image_use_case.dart
class LoadImageUseCase extends UseCase<ImageData, LoadImageParams> {
  final ImageRepository _repository;

  LoadImageUseCase(this._repository);

  @override
  Future<Result<ImageData>> call(LoadImageParams params) async {
    // Step 1: Validate
    final validationResult = await _repository.validateImageSize(params.path);
    if (validationResult.isFailure) return validationResult;

    // Step 2: Load
    final loadResult = await _repository.loadImage(params.path);
    if (loadResult.isFailure) return loadResult;

    // Step 3: Resize if needed
    if (params.maxWidth != null) {
      return await _repository.resizeImage(/* ... */);
    }

    return loadResult;
  }
}
```

**Key Use Cases**:
- `LoadImageUseCase` - Load and validate images
- `ApplyBlurUseCase` - Apply blur with validation

#### 4. Commands
Implement undo/redo pattern.

```dart
// lib/features/editor/domain/commands/add_stroke_command.dart
class AddStrokeCommand extends UndoableCommand {
  final BrushStroke stroke;

  @override
  EditorState execute(EditorState currentState) {
    return currentState.copyWith(
      strokes: [...currentState.strokes, stroke],
    );
  }

  @override
  EditorState undo(EditorState currentState) {
    final newStrokes = List<BrushStroke>.from(currentState.strokes);
    if (newStrokes.isNotEmpty) newStrokes.removeLast();
    return currentState.copyWith(strokes: newStrokes);
  }
}
```

**Key Commands**:
- `AddStrokeCommand` - Add brush stroke (undoable)
- `ChangeBlurSettingsCommand` - Change blur settings (undoable)
- `ClearStrokesCommand` - Clear all strokes (undoable)

### Data Layer (`lib/features/*/data/`) - **Coming in Phase 2**

**Purpose**: Implements repository interfaces. Handles data sources, APIs, caching, persistence.

**Components** (planned):
- Repository implementations
- Data sources (local/remote)
- Data models (DTO/serialization)
- Mappers (Data models ↔ Domain entities)

### Presentation Layer (`lib/features/*/presentation/`)

**Purpose**: UI and state management. Depends on domain layer.

**Components**:

#### 1. Providers
Riverpod providers for dependency injection and state management.

```dart
// lib/features/editor/presentation/providers/editor_providers.dart

// State management with undo/redo
class EditorNotifier extends StateNotifier<EditorState> {
  CommandHistory _history = const CommandHistory();

  void addStroke(BrushStroke stroke) {
    final command = AddStrokeCommand(stroke: stroke);
    _executeCommand(command);  // Execute and add to history
  }

  void undo() {
    final command = _history.lastCommand;
    state = command.undo(state);
    _history = _history.moveToRedo();
  }
}

// Providers
final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>(...);
final loadImageUseCaseProvider = Provider<LoadImageUseCase>(...);
final canUndoProvider = Provider<bool>(...);
```

#### 2. Widgets
UI components that consume providers.

```dart
class EditorScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    final canUndo = ref.watch(canUndoProvider);

    return /* UI */;
  }
}
```

---

## Key Patterns

### 1. Repository Pattern

**Purpose**: Abstract data access to enable testing and flexibility.

**Structure**:
- **Interface** (Domain layer): Defines contract
- **Implementation** (Data layer): Provides actual implementation
- **Provider** (Presentation layer): Creates and injects instance

**Benefits**:
- Swap implementations (e.g., mock for testing)
- Change data sources without affecting business logic
- Test business logic without real data sources

### 2. Use Case Pattern

**Purpose**: Encapsulate single business operations.

**Rules**:
- One use case = one business operation
- Orchestrates repository calls
- Contains validation and business logic
- Returns `Result<T>` for error handling

**Example**:
```dart
// Good - Single responsibility
class LoadImageUseCase { }
class SaveImageUseCase { }

// Bad - Multiple responsibilities
class ImageUseCase {
  void load() { }
  void save() { }
}
```

### 3. Command Pattern

**Purpose**: Enable undo/redo functionality.

**Structure**:
- **Command**: Interface with `execute()` and `undo()`
- **CommandHistory**: Manages undo/redo stacks
- **Notifier**: Executes commands and updates state

**Benefits**:
- Unlimited undo/redo
- Command merging (e.g., consecutive strokes)
- Macro commands (execute multiple commands as one)
- History persistence (save/restore sessions)

### 4. Result Pattern

**Purpose**: Type-safe error handling without exceptions.

**Structure**:
```dart
@freezed
class Result<T> with _$Result<T> {
  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure error) = ResultFailure<T>;
}

// Usage
final result = await loadImageUseCase(params);
result.when(
  success: (image) => /* handle success */,
  failure: (error) => /* handle error */,
);
```

**Benefits**:
- Explicit error handling
- Type safety (can't forget to handle errors)
- Pattern matching for different error types
- No exception try/catch pollution

---

## Data Flow

### Read Flow (Display Data)

```
┌─────────┐
│ Widget  │ watches provider
└────┬────┘
     │
     ↓
┌─────────────┐
│  Provider   │ exposes state
└──────┬──────┘
       │
       ↓
┌──────────────┐
│   Notifier   │ holds state
└──────────────┘
```

### Write Flow (User Action)

```
┌─────────┐
│  User   │ taps button
└────┬────┘
     │
     ↓
┌─────────┐
│ Widget  │ calls notifier method
└────┬────┘
     │
     ↓
┌──────────────┐
│   Notifier   │ creates command
└──────┬───────┘
       │
       ↓
┌──────────────┐
│   Command    │ executes on state
└──────┬───────┘
       │
       ↓
┌──────────────┐
│  New State   │ triggers rebuild
└──────────────┘
```

### Use Case Flow (Business Operation)

```
┌─────────┐
│ Widget  │ initiates action
└────┬────┘
     │
     ↓
┌──────────────┐
│   Notifier   │ calls use case
└──────┬───────┘
       │
       ↓
┌──────────────┐
│   Use Case   │ validates & orchestrates
└──────┬───────┘
       │
       ↓
┌──────────────┐
│  Repository  │ fetches/saves data
└──────┬───────┘
       │
       ↓
┌──────────────┐
│ Result<T>    │ returns success or failure
└──────┬───────┘
       │
       ↓
┌──────────────┐
│   Notifier   │ updates state with result
└──────────────┘
```

---

## Error Handling

### Failure Types

All errors are represented as typed `Failure` objects:

```dart
@freezed
class Failure with _$Failure {
  const factory Failure.imageLoad({
    required String message,
    Object? error,
  }) = ImageLoadFailure;

  const factory Failure.outOfMemory({
    required String message,
    int? requiredBytes,
    int? availableBytes,
  }) = OutOfMemoryFailure;

  const factory Failure.permission({
    required String message,
    required String permissionType,
  }) = PermissionFailure;

  // ... more types
}
```

### Handling Failures

```dart
final result = await loadImageUseCase(params);

result.when(
  success: (image) {
    notifier.setOriginalImage(image);
  },
  failure: (failure) {
    failure.when(
      imageLoad: (message, error) {
        notifier.setError('Failed to load: $message');
      },
      outOfMemory: (message, required, available) {
        notifier.setError(
          'Image too large. Required: ${required}MB, Available: ${available}MB',
        );
      },
      permission: (message, permissionType) {
        showPermissionDialog(permissionType);
      },
      // ... handle other types
    );
  },
);
```

### Benefits

- **Type Safety**: Compiler ensures all error types are handled
- **Context**: Each failure type carries relevant data
- **Clarity**: Clear error categories vs generic exceptions
- **Testing**: Easy to test error scenarios

---

## State Management

### Riverpod Architecture

We use **Riverpod 2.x** with the following provider types:

#### StateNotifierProvider
For mutable state with actions.

```dart
final editorProvider = StateNotifierProvider<EditorNotifier, EditorState>(
  (ref) => EditorNotifier(),
);

// Usage
final state = ref.watch(editorProvider);
final notifier = ref.read(editorProvider.notifier);
notifier.addStroke(stroke);
```

#### Provider
For computed values and dependency injection.

```dart
final canUndoProvider = Provider<bool>((ref) {
  final notifier = ref.watch(editorProvider.notifier);
  ref.watch(editorProvider); // Rebuild when state changes
  return notifier.canUndo;
});

final loadImageUseCaseProvider = Provider<LoadImageUseCase>((ref) {
  final repository = ref.watch(imageRepositoryProvider);
  return LoadImageUseCase(repository);
});
```

#### FutureProvider
For async operations.

```dart
final imageLoadProvider = FutureProvider.family<Result<ImageData>, String>(
  (ref, imagePath) async {
    final useCase = ref.watch(loadImageUseCaseProvider);
    return await useCase(LoadImageParams(path: imagePath));
  },
);
```

### State Immutability

All state classes use `@freezed` for immutability:

```dart
@freezed
class EditorState with _$EditorState {
  const factory EditorState({
    ImageData? originalImage,
    @Default([]) List<BrushStroke> strokes,
    @Default(BlurSettings()) BlurSettings blurSettings,
  }) = _EditorState;
}

// Updating state always creates new instance
state = state.copyWith(strokes: [...state.strokes, newStroke]);
```

---

## Adding New Features

### Step-by-Step Guide

#### 1. Define Domain Entities

Create the business objects:

```dart
// lib/features/layers/domain/entities/layer.dart
@freezed
class Layer with _$Layer {
  const factory Layer({
    required String id,
    required String name,
    required ImageData image,
    @Default(1.0) double opacity,
    @Default(true) bool visible,
  }) = _Layer;
}
```

#### 2. Create Repository Interface

Define the contract:

```dart
// lib/features/layers/domain/repositories/layer_repository.dart
abstract class LayerRepository {
  Future<Result<Layer>> createLayer(ImageData image);
  Future<Result<List<Layer>>> loadLayers();
  Future<Result<void>> saveLayer(Layer layer);
}
```

#### 3. Implement Use Cases

Encapsulate business logic:

```dart
// lib/features/layers/domain/use_cases/create_layer_use_case.dart
class CreateLayerUseCase extends UseCase<Layer, CreateLayerParams> {
  final LayerRepository _repository;

  CreateLayerUseCase(this._repository);

  @override
  Future<Result<Layer>> call(CreateLayerParams params) async {
    // Validation
    if (params.image.bytes.isEmpty) {
      return Result.failure(
        Failure.imageProcess(message: 'Image data is empty'),
      );
    }

    // Business logic
    return await _repository.createLayer(params.image);
  }
}
```

#### 4. Create Commands (if undoable)

Implement command pattern:

```dart
// lib/features/layers/domain/commands/add_layer_command.dart
class AddLayerCommand extends UndoableCommand {
  final Layer layer;

  @override
  EditorState execute(EditorState currentState) {
    return currentState.copyWith(
      layers: [...currentState.layers, layer],
    );
  }

  @override
  EditorState undo(EditorState currentState) {
    final newLayers = List<Layer>.from(currentState.layers);
    newLayers.removeLast();
    return currentState.copyWith(layers: newLayers);
  }
}
```

#### 5. Create Providers

Wire up dependency injection:

```dart
// lib/features/layers/presentation/providers/layer_providers.dart

// Repository provider (placeholder until data layer implemented)
final layerRepositoryProvider = Provider<LayerRepository>((ref) {
  throw UnimplementedError('Will be implemented in data layer');
});

// Use case provider
final createLayerUseCaseProvider = Provider<CreateLayerUseCase>((ref) {
  final repository = ref.watch(layerRepositoryProvider);
  return CreateLayerUseCase(repository);
});

// State provider
final layersProvider = StateNotifierProvider<LayersNotifier, List<Layer>>(
  (ref) => LayersNotifier(),
);
```

#### 6. Implement UI

Create widgets that consume providers:

```dart
class LayersPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layers = ref.watch(layersProvider);
    final createLayerUseCase = ref.read(createLayerUseCaseProvider);

    return Column(
      children: [
        for (final layer in layers)
          LayerTile(layer: layer),
        FloatingActionButton(
          onPressed: () async {
            final result = await createLayerUseCase(/* params */);
            result.when(
              success: (layer) => /* handle success */,
              failure: (error) => /* handle error */,
            );
          },
          child: Icon(Icons.add),
        ),
      ],
    );
  }
}
```

#### 7. Write Tests

Test each layer independently:

```dart
// Domain layer test (pure Dart)
void main() {
  group('CreateLayerUseCase', () {
    late MockLayerRepository mockRepository;
    late CreateLayerUseCase useCase;

    setUp(() {
      mockRepository = MockLayerRepository();
      useCase = CreateLayerUseCase(mockRepository);
    });

    test('creates layer with valid image', () async {
      // Arrange
      final imageData = ImageData(/* ... */);
      when(() => mockRepository.createLayer(any()))
          .thenAnswer((_) async => Result.success(Layer(/* ... */)));

      // Act
      final result = await useCase(CreateLayerParams(image: imageData));

      // Assert
      expect(result.isSuccess, true);
      verify(() => mockRepository.createLayer(imageData)).called(1);
    });
  });
}
```

---

## Migration Guide

### From MVP to Clean Architecture

#### Before (MVP Pattern)

```dart
class EditorScreen extends StatefulWidget {
  // State mixed with UI
  List<Point> _brushStrokes = [];
  BlurSettings _settings = BlurSettings();

  void _addStroke(Point point) {
    setState(() {
      _brushStrokes.add(point);
    });
  }

  Future<void> _loadImage() async {
    // Direct file access in UI
    final bytes = await File(path).readAsBytes();
    setState(() {
      _image = bytes;
    });
  }
}
```

#### After (Clean Architecture)

```dart
// Domain
class LoadImageUseCase {
  Future<Result<ImageData>> call(LoadImageParams params) { }
}

// Presentation
class EditorNotifier extends StateNotifier<EditorState> {
  void addStroke(BrushStroke stroke) {
    final command = AddStrokeCommand(stroke: stroke);
    _executeCommand(command);
  }

  Future<void> loadImage(String path) async {
    final result = await _loadImageUseCase(LoadImageParams(path: path));
    result.when(
      success: (image) => state = state.copyWith(originalImage: image),
      failure: (error) => state = state.copyWith(error: error.message),
    );
  }
}

// UI
class EditorScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);

    return /* clean UI */;
  }
}
```

### Migration Steps

1. **Start with Domain**: Create entities, repositories, use cases
2. **Add Providers**: Wire up state management
3. **Update UI**: Migrate widgets to use providers
4. **Implement Data Layer**: Replace placeholder repositories
5. **Add Tests**: Test each layer independently
6. **Remove Old Code**: Delete MVP implementations

---

## Testing Strategy

### Layer-Specific Testing

#### Domain Layer (Unit Tests)

Test business logic without any dependencies:

```dart
test('BrushStroke.isEmpty returns true when no points', () {
  final stroke = BrushStroke(id: '1', points: [], size: 50);
  expect(stroke.isEmpty, true);
});

test('LoadImageUseCase validates image size', () async {
  // Mock repository
  when(() => mockRepo.validateImageSize(any()))
      .thenAnswer((_) async => Result.success(false));

  // Call use case
  final result = await useCase(LoadImageParams(path: 'test.jpg'));

  // Verify failure
  expect(result.isFailure, true);
});
```

#### Presentation Layer (Widget Tests)

Test UI components:

```dart
testWidgets('EditorScreen shows undo button when can undo', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        canUndoProvider.overrideWithValue(true),
      ],
      child: EditorScreen(),
    ),
  );

  expect(find.byIcon(Icons.undo), findsOneWidget);
});
```

#### Integration Tests

Test complete flows:

```dart
testWidgets('Loading image updates editor state', (tester) async {
  // Setup
  final container = ProviderContainer(
    overrides: [
      imageRepositoryProvider.overrideWithValue(MockImageRepository()),
    ],
  );

  // Execute
  await container.read(editorProvider.notifier).loadImage('test.jpg');

  // Verify
  expect(container.read(editorProvider).hasImage, true);
});
```

---

## Best Practices

### 1. Dependency Direction

✅ **Good**: Outer layers depend on inner layers
```dart
class EditorNotifier {
  final LoadImageUseCase _loadImageUseCase;  // Domain
  EditorNotifier(this._loadImageUseCase);
}
```

❌ **Bad**: Inner layers depend on outer layers
```dart
class LoadImageUseCase {
  final EditorNotifier _notifier;  // Presentation
  // WRONG! Use case shouldn't know about UI
}
```

### 2. Use Case Granularity

✅ **Good**: Single responsibility
```dart
class LoadImageUseCase { }
class ValidateImageUseCase { }
class ResizeImageUseCase { }
```

❌ **Bad**: Multiple responsibilities
```dart
class ImageUseCase {
  void load() { }
  void validate() { }
  void resize() { }
}
```

### 3. State Immutability

✅ **Good**: Create new instances
```dart
state = state.copyWith(strokes: [...state.strokes, newStroke]);
```

❌ **Bad**: Mutate existing state
```dart
state.strokes.add(newStroke);  // WRONG! Mutates state
```

### 4. Error Handling

✅ **Good**: Use Result<T>
```dart
Future<Result<ImageData>> loadImage(String path) async {
  try {
    final data = await source.load(path);
    return Result.success(data);
  } catch (e) {
    return Result.failure(Failure.imageLoad(message: e.toString()));
  }
}
```

❌ **Bad**: Throw exceptions
```dart
Future<ImageData> loadImage(String path) async {
  throw Exception('Failed to load');  // Forces caller to use try/catch
}
```

### 5. Provider Organization

✅ **Good**: Organize by feature
```
lib/features/
  editor/
    presentation/
      providers/
        editor_providers.dart
  export/
    presentation/
      providers/
        export_providers.dart
```

❌ **Bad**: Single providers file
```
lib/providers/
  all_providers.dart  // 1000+ lines
```

---

## Phase 2 Preview

The next phase will implement the **Data Layer**:

- Repository implementations
- Image loading/saving (using `image` package)
- Blur processing (pure Dart + GPU acceleration)
- Face detection (TFLite integration)
- Local persistence (Hive for settings/history)
- Caching strategies

---

## Resources

- [Clean Architecture (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Riverpod Documentation](https://riverpod.dev/)
- [Freezed Package](https://pub.dev/packages/freezed)
- [Example Integration](../lib/features/editor/presentation/examples/architecture_example.dart)

---

## Questions?

If you have questions about the architecture:

1. Check the [Example Integration](../lib/features/editor/presentation/examples/architecture_example.dart)
2. Review existing domain entities and use cases
3. Consult this guide's [Adding New Features](#adding-new-features) section
4. Follow the patterns established in Phase 1

**Remember**: When in doubt, follow the dependency rule - dependencies always point inward!
