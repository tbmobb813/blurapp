# Development Guide

Complete guide for setting up and developing BlurApp.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Environment Setup](#environment-setup)
3. [Development Workflow](#development-workflow)
4. [Testing](#testing)
5. [Building](#building)
6. [Troubleshooting](#troubleshooting)

---

## Quick Start

```bash
# 1. Clone repository
git clone <repository-url>
cd blurapp

# 2. Run setup script
./scripts/dev-setup.sh

# 3. Install git hooks (recommended)
./scripts/install-hooks.sh

# 4. Run the app
cd app
flutter run
```

---

## Environment Setup

### Prerequisites

- **Flutter SDK** (stable channel)
- **Android Studio** (for Android development)
- **Xcode** (for iOS development, macOS only)
- **Git**

### Android Studio Setup (Recommended)

This project uses Android Studio (snap) for Android development. The repository expects developers to point Flutter to a single Android Studio installation and, optionally, to the JDK bundled with that IDE.

**Recommended setup (snap):**

1. Install Android Studio via snap (classic):
   ```bash
   sudo snap install android-studio --classic
   ```

2. Configure Flutter to use the snap-mounted Android Studio and its JDK:
   ```bash
   flutter config --android-studio-dir="/snap/android-studio/current"
   flutter config --jdk-dir="/snap/android-studio/current/jbr"
   ```

**Notes:**
- We prefer the snap install because it exposes a full IDE layout and bundles a consistent JDK (OpenJDK 21) compatible with the project's Android Gradle Plugin and Java target.
- If you use a different Android Studio install method (JetBrains tarball, Toolbox, or distro package), update the `--android-studio-dir` and `--jdk-dir` values accordingly.
- If you previously used a Flatpak Android Studio, remove any shim you created (for example `~/.local/android-studio-flatpak-shim`) to avoid confusion.

### Flutter Setup

1. **Install Flutter:**
   ```bash
   # Follow instructions at https://flutter.dev/docs/get-started/install
   ```

2. **Verify installation:**
   ```bash
   flutter doctor
   ```

3. **Install dependencies:**
   ```bash
   cd app
   flutter pub get
   ```

### VS Code Setup (Optional)

If using VS Code, install recommended extensions:
- Dart
- Flutter
- Flutter Snippets
- GitLens
- Error Lens

Configuration is already provided in `.vscode/` directory.

---

## Development Workflow

### Daily Development

1. **Pull latest changes:**
   ```bash
   git pull origin main
   cd app && flutter pub get
   ```

2. **Run app in debug mode:**
   ```bash
   cd app
   flutter run
   # or use VS Code "Run and Debug"
   ```

3. **Make changes** with hot reload (press `r` in terminal)

4. **Before committing:**
   ```bash
   flutter format lib test
   flutter analyze
   flutter test
   ```

   Or let pre-commit hooks handle it automatically!

### Code Style

- **Formatting:** Use `dart format` (runs automatically on save in VS Code)
- **Linting:** Follow rules in `analysis_options.yaml`
- **Line length:** 80 characters (enforced by formatter)
- **Imports:** Organize imports alphabetically

### Git Workflow

1. **Create feature branch:**
   ```bash
   git checkout -b feat/your-feature-name
   ```

2. **Make changes and commit:**
   ```bash
   git add .
   git commit -m "feat: add your feature"
   # Pre-commit hooks will run automatically
   ```

3. **Push and create PR:**
   ```bash
   git push -u origin feat/your-feature-name
   # Create PR on GitHub
   ```

### Available Scripts

Located in `scripts/` directory:

```bash
# Setup development environment
./scripts/dev-setup.sh

# Install git hooks
./scripts/install-hooks.sh

# Build APK
./scripts/build.sh [debug|release]

# Run tests with coverage
./scripts/test.sh
```

---

## Testing

### Running Tests

```bash
# All tests
cd app && flutter test

# With coverage
flutter test --coverage

# Specific test file
flutter test test/unit/blur_engine_mvp_test.dart

# Using script
../scripts/test.sh
```

### Test Structure

```
app/test/
├── integration/       # User workflow tests
├── performance/       # Performance benchmarks
├── unit/             # Unit tests
├── widget/           # Widget tests
└── test_runner.dart  # Test bootstrap with mocks
```

### Writing Tests

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MyFeature', () {
    test('should do something', () {
      // Arrange
      final input = 42;

      // Act
      final result = myFunction(input);

      // Assert
      expect(result, equals(84));
    });
  });
}
```

### Coverage Goals

- **Target:** 80%+ code coverage
- **Current:** Check CI/CD coverage reports
- **View locally:** `open coverage/html/index.html` (after generating with genhtml)

---

## Building

### Debug Build

```bash
# Using script (recommended)
./scripts/build.sh debug

# Manual
cd app
flutter build apk --debug
```

### Release Build

```bash
# Using script
./scripts/build.sh release

# Manual
cd app
flutter build apk --release
```

### Build Configuration

- **JVM Heap:** 8GB (configured in `app/android/gradle.properties`)
- **Gradle Workers:** 2 (memory optimization)
- **Jetifier:** Disabled (not needed)

### Build Troubleshooting

**Out of memory errors:**
- Already optimized with 8GB heap
- Disable other applications
- Check available RAM

**Gradle sync issues:**
- Clean build: `cd app && flutter clean`
- Re-sync: `cd app/android && ./gradlew --refresh-dependencies`

---

## Troubleshooting

### Flutter Doctor Issues

**"Android Studio version unknown":**
- Usually cosmetic with snap installs
- Builds will still work if SDK and JDK detected
- Verify: `flutter doctor -v`

**SDK not found:**
```bash
# Set SDK path
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
# Add to ~/.bashrc or ~/.zshrc
```

### Build Failures

**"Java heap space" errors:**
- ✅ Already fixed with 8GB heap configuration
- If still occurs, check available system RAM

**"Plugin not found" errors:**
```bash
cd app
flutter clean
flutter pub get
```

**Gradle issues:**
```bash
cd app/android
./gradlew clean
cd ../..
flutter clean
flutter pub get
```

### Runtime Issues

**Hot reload not working:**
- Try hot restart (`R` instead of `r`)
- Restart app completely
- Check for syntax errors

**App crashes on startup:**
- Check logcat: `flutter logs`
- Verify dependencies: `flutter pub get`
- Clean and rebuild

### Performance Issues

**Slow performance:**
- Use profile or release mode (not debug)
- See `docs/PROFILING.md` for detailed guide
- Check memory usage in DevTools

---

## Performance Profiling

For detailed performance profiling instructions, see:
**[docs/PROFILING.md](docs/PROFILING.md)**

Quick commands:
```bash
# Profile mode (recommended for performance testing)
flutter run --profile

# Open DevTools
flutter pub global run devtools
```

---

## Additional Resources

### Documentation

- [README.md](README.md) - Project overview
- [ARCHITECTURE.md](ARCHITECTURE.md) - Architecture details
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [PROFILING.md](docs/PROFILING.md) - Performance profiling guide

### External Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Flutter Performance Best Practices](https://flutter.dev/docs/perf/rendering/best-practices)

---

## Getting Help

1. **Check existing documentation** (above)
2. **Search issues** on GitHub
3. **Ask in discussions** or create an issue
4. **Check CI logs** for build failures

---

## Environment Variables

None required. All configuration is in code or gradle.properties.

## IDE Shortcuts (VS Code)

- `Ctrl/Cmd + Shift + P` - Command palette
- `F5` - Start debugging
- `Shift + F5` - Stop debugging
- `Ctrl/Cmd + F5` - Run without debugging
- `r` (in debug terminal) - Hot reload
- `R` (in debug terminal) - Hot restart

---

Last updated: 2025-11-15
