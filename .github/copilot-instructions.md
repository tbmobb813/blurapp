# Copilot Onboarding — Blur App (Flutter, iOS + Android)

## Purpose
Build a **privacy-first, offline photo blur app** for iOS & Android. Users can import a photo, apply adjustable blur effects (background, face/object areas, full-image), then export/share. No accounts, no subscriptions, no network calls for core editing.

## Non-Goals (for now)
- No cloud services or telemetry.
- No ads/subscriptions/paywalls.
- No social feed or backend API assumptions.

## Tech & Targets
- **Framework:** Flutter (stable channel), Dart 3.x
- **Minimum OS:** Android 8 (API 26)+, iOS 14+
- **Build modes:** debug/release; CI must pass `analyze` + tests

### Allowed Packages (prefer lightweight, well-maintained)
- Image IO/UI: `image_picker`, `share_plus`, `path_provider`
- Image processing: start with Flutter/dart image ops; if needed, prefer `image` package.
- State mgmt: `flutter_riverpod` (simple, testable)
- Testing: `flutter_test`, `mocktail`
> If adding any new dependency, include justification in the PR description and keep the app fully offline.

## Architecture & Conventions
- **Clean-ish modular structure:** core (foundation) → features (editor) → app (routing/theme).
- Pure Dart for image transforms where possible. Keep platform channels minimal.
- Small, testable units; avoid “god” widgets/services.

lib/
├─ app/
│ ├─ app.dart # MaterialApp, routes
│ ├─ router.dart # GoRouter or simple Navigator 2.0 (keep minimal)
│ └─ theme/
├─ core/
│ ├─ utils/ # result types, image helpers, validators
│ ├─ services/ # file IO, permissions, logging (no network)
│ └─ widgets/ # shared UI atoms
├─ features/
│ └─ editor/
│ ├─ presentation/ # screens, widgets, controllers
│ ├─ application/ # providers (Riverpod), use-cases
│ └─ domain/ # entities (EditSession, Mask, BlurParams)
└─ main.dart
test/
├─ unit/ # pure functions (e.g., blur param math)
└─ widget/ # editor screen interactions


### Coding Standards
- Run `dart format .` and `flutter analyze` clean.
- Prefer composition over inheritance; functions < 50 lines.
- Null-safety everywhere; meaningful names; no magic numbers.
- Public APIs documented with Dartdoc where non-obvious.

## UX Scope (MVP)
1. **Home → Editor**: pick image (gallery/camera), show preview.
2. **Blur controls**: slider for radius/intensity; mode toggle:
   - Full-image blur
   - Background blur (manual brush/mask MVP)
   - Face/object blur (stub provider; can start with manual masking)
3. **Export**: save to device; optional share sheet.
4. **Settings**: “Offline by default” note; clear temp cache.

## Testing Requirements
- **Unit**: blur param math, file IO paths, simple mask ops.
- **Widget**: editor screen loads image; slider changes preview; export path invoked.
- All PRs must include or update tests for changed code.

## Performance & Privacy
- All editing runs **on-device**; do not add network permissions.
- Keep memory use low (downscale preview, process at export).
- Guardrails: fail gracefully on large images; show progress indicators.

## What Copilot Should Generate First (Initial PR)
1. Flutter project scaffold with the folder structure above.
2. Dependencies + `analysis_options.yaml` (strict lints).
3. Basic screens:
   - `HomeScreen` (Pick Image)
   - `EditorScreen` (image preview, blur slider, mode toggle)
4. Services:
   - `ImagePickerService`, `ImageSaverService`, temp file manager
5. Core blur pipeline:
   - Start with full-image Gaussian blur for preview + export
   - Abstraction so manual mask mode can plug in next
6. Tests:
   - Unit tests for blur param mapping and path utils
   - Widget test: loads image mock, adjusts slider, triggers export
7. CI skeleton:
   - GitHub Actions: `flutter pub get`, `flutter analyze`, `flutter test`

## Acceptance Criteria for PRs
- Build passes locally with `flutter build apk --debug` and `flutter test`.
- `flutter analyze` returns **0** issues.
- App flows: pick → preview → adjust blur → save → share (happy path).
- No network permissions; no analytics; no secrets.

## Things to Avoid
- Adding heavy native libs without discussion.
- Introducing runtime permissions not needed for MVP.
- Using deprecated packages or unstable forks.
- Large, untested feature drops.

## Commands (reference)
```bash
# Setup
flutter pub get

# Lint & test
flutter analyze
flutter test

# Run
flutter run

# Build (debug sample)
flutter build apk --debug
