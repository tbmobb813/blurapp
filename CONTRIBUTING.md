# Contributing to blurapp

Thank you for your interest in contributing! Please follow these guidelines:

## Pull Requests
- Fork the repo and create your branch from `main`.
- PRs must pass `flutter analyze` and `flutter test` for all flavors.
- Include tests for new features and bug fixes.
- Document public APIs with Dartdoc if non-obvious.

## Code Style
- Run `dart format .` before submitting.
- Use meaningful names and null-safety everywhere.
- Prefer composition over inheritance; keep functions < 50 lines.
- Avoid magic numbers and "god" widgets/services.

## Testing
- Add unit tests for pure functions in `test/unit/`.
- Add widget tests for UI in `test/widget/`.
- Ensure coverage for blur logic, file IO, and mask ops.

## Review Process
- PRs are reviewed for code quality, test coverage, and adherence to architecture.
- Large or untested feature drops will be rejected.

## Other Notes
- No network permissions, analytics, or ads.
- All processing must be offline.
- See `.github/copilot-instructions.md` for architecture and conventions.

## Build artifacts

Please do not commit build outputs or IDE caches (for example any `build/` directories under `app/`, `android/`, `ios/`, `build/`, or platform plugin folders). These files are machine-specific and can break CI (they may include absolute paths or platform-specific binaries).

To clean and rebuild locally:

```bash
# remove local build outputs
flutter clean

# fetch packages and run analyzer/tests
flutter pub get
flutter analyze
flutter test

# build the Android debug APK locally
flutter build apk --debug
```

If you find machine-specific files accidentally committed, remove them from the index and push a commit:

```bash
git rm -r --cached path/to/committed/build_dir
git commit -m "ci: remove committed build artifacts"
git push origin your-branch
```

