# blurapp

## Stack
- **Framework:** Flutter (Dart 3.x)
- **Native:** C++ (image blur core)
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

Contributing
See .github/copilot-instructions.md for architecture and conventions.
PRs must pass lints and tests for all flavors.