# blurapp

## Stack

- **Framework:** Flutter (Dart 3.x)
- **Nati## MediaPipe / TFLite models

For optional on-device auto-detection (to auto-blur faces or background), you need to download pre-built TensorFlow Lite models. The MediaPipe v0.10.26 package you have contains source code, not the compiled models.

### Where to get the models

### Option 1: Kaggle Models (recommended)

MediaPipe models are now hosted on Kaggle Models. You'll need to download them manually:

1. **Face Detection**: Visit [https://www.kaggle.com/models/mediapipe/face-detection](https://www.kaggle.com/models/mediapipe/face-detection)
   - Download the `.tflite` file (usually named something like `face_detection_short_range.tflite`)
   - Place it in `app/assets/models/face_detection_short_range.tflite`

2. **Selfie Segmentation**: Visit [https://www.kaggle.com/models/mediapipe/selfie-segmentation](https://www.kaggle.com/models/mediapipe/selfie-segmentation)
   - Download the `.tflite` file (usually named something like `selfie_segmentation.tflite`)
   - Place it in `app/assets/models/selfie_segmentation.tflite`

### Option 2: Alternative sources

You can also find these models in MediaPipe examples or other repositories:

- Check the MediaPipe GitHub repository examples
- Look for community repositories that bundle these models

### Option 3: Build from source

If you want to build models from the MediaPipe source you downloaded, see the MediaPipe documentation for building TFLite models.

### Models needed

- `selfie_segmentation.tflite` — background/foreground segmentation
- `face_detection_short_range.tflite` — face box detection for close subjects

### Placement

- Copy these files into `app/assets/models/`.
- `app/pubspec.yaml` already declares `assets/` and `assets/models/` under the `flutter.assets` section, so they'll be bundled automatically.

### Manual download steps

Since the direct URLs are no longer available, follow these steps:

1. Visit the Kaggle model pages above
2. Download the `.tflite` files
3. Copy them to your project:

```bash
# Navigate to your Flutter app's assets/models directory (example)
cd ~/Projects/blurapp/app/assets/models

# Copy your downloaded files here (adjust paths as needed)
# Example (Linux/macOS):
# mv ~/Downloads/face_detection_short_range.tflite .
# mv ~/Downloads/selfie_segmentation.tflite .
```

- **State Management:** Riverpod (recommended) or Bloc
- **Database:** Isar or Hive (lightweight, offline)
- **Media IO:** ffmpeg_kit_flutter, image, exif, camera
- **Permissions:** permission_handler

## App IDs & Package Names

- **Android:**
  - Application ID: `com.blurapp.free` (free), `com.blurapp.pro` (pro)
- **iOS:**
  - Bundle ID: `com.blurapp.free` (free), `com.blurapp.pro` (pro)

## Build Flavors

- **Android:**
  - Configure flavors in `android/app/build.gradle`:
    - `free` (default)
    - `pro` (premium features)
- **iOS:**
  - Set up schemes for `Free` and `Pro` in Xcode

## Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  ffmpeg_kit_flutter: ^latest
  image: ^latest
  exif: ^latest
  camera: ^latest
  permission_handler: ^latest
  isar: ^latest # or hive: ^latest
  flutter_riverpod: ^latest # or flutter_bloc: ^latest

BUILD AND RUN

flutter pub get
flutter analyze
flutter test
flutter run --flavor free
flutter run --flavor pro

Notes
All processing is offline; no network permissions.
For native C++ integration, see native/ and platform bridge files.
For CI, ensure both flavors build and pass tests.

Note about project root
----------------------
This repository contains the Flutter application under the `app/` subfolder. If you run Flutter commands from the repository root you may see errors like:

```

Expected to find project root in current working directory.

```

Fix: change directory into the `app/` folder first, for example:

```bash
cd app
flutter pub get
```

You can run all other Flutter commands from `app/` (e.g., `flutter run`, `flutter analyze`, `flutter test`).

## MediaPipe / TFLite models

For optional on-device auto-detection (to auto-blur faces or background), you need to download pre-built TensorFlow Lite models. The MediaPipe v0.10.26 package you have contains source code, not the compiled models.

### Download commands

**✅ Working direct downloads from Google Cloud Storage:**

```bash
# Navigate to your Flutter app's assets/models directory (example)
cd ~/Projects/blurapp/app/assets/models

# Download face detection model (short-range, ~224KB)
curl -L -o face_detection_short_range.tflite \
  "https://storage.googleapis.com/mediapipe-assets/face_detection_short_range.tflite"

# Download selfie segmentation model (~244KB)
curl -L -o selfie_segmentation.tflite \
  "https://storage.googleapis.com/mediapipe-assets/selfie_segmentation.tflite"
```

### Models included

- `face_detection_short_range.tflite` — face box detection for close subjects
- `selfie_segmentation.tflite` — background/foreground segmentation

Placement:

- Copy these files into `app/assets/models/`.
- `app/pubspec.yaml` already declares `assets/` and `assets/models/` under the `flutter.assets` section, so they’ll be bundled automatically.

Example usage:

```dart
// Create an interpreter-backed detector using a bundled model asset
final detector = await AutoDetectService.create(
  modelPath: 'assets/models/face_detection_short_range.tflite',
);
final rects = await detector.detect(imageBytes);
```

Notes:

- You may see multiple `.tflite` files in the MediaPipe package. For this app’s MVP, only the two above are needed. Face landmarks or full object detection models are heavier and not required right now.
- If you don’t add models, manual masking still works; auto-detect features will be inactive.

## Contributing

See .github/copilot-instructions.md for architecture and conventions.
PRs must pass lints and tests for all flavors.
