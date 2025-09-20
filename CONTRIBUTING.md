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
