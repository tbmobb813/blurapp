## Upgrade toolchain: Gradle, Android Gradle Plugin (AGP), and Kotlin

### Goal

Bring the Android build toolchain into alignment with Java 21 (current CI target) by upgrading:

- Gradle wrapper to at least 8.7
- Android Gradle Plugin (AGP) to at least 8.6.0
- Kotlin plugin to at least 2.1.0

### Why

- CI currently uses Java 21. Newer AGP/Gradle/Kotlin improve compatibility and remove deprecation warnings seen in CI logs.
- Upgrading reduces build warnings and avoids future breakage when Flutter/Android tooling drops support for older toolchain versions.

### Proposed changes (minimal, staged)

1. Update `android/gradle/wrapper/gradle-wrapper.properties` to Gradle 8.7 (or latest 8.x recommended by Flutter).
2. Update AGP in `android/build.gradle` (or `settings.gradle` plugins block) to `com.android.tools.build:gradle:8.6.0`.
3. Update Kotlin in `android/build.gradle` (or `buildSrc`/`settings.gradle`) to `org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0` and the `kotlin_version` ext if present.
4. Run `./gradlew wrapper --gradle-version 8.7` locally to regenerate wrapper artifacts and commit the resulting `gradle-wrapper.properties` and `gradle/wrapper/` jars.
5. Adjust `gradle.properties` tuned values (heap/workers) only if CI shows OOM; prefer to set `GRADLE_OPTS` in CI runner instead of permanently increasing for local dev.

### Checks and validation

- Run `flutter pub get` and `flutter analyze` in `app/`.
- Run `flutter test` (unit + widget tests).
- Run `flutter build apk --debug` on a local machine and/or in CI to ensure assembleDebug completes without Jetify/transform OOMs.
- Verify native build & test jobs (Linux/macOS/Windows) still pass.
- If any plugin (e.g., tflite, image_picker) needs a version bump to satisfy new AGP/Gradle, fix/lock those minimal bumps and run tests.

### Risk and rollback

- Upgrading AGP/Kotlin can surface plugin compatibility issues. Mitigate by:
  - Doing staged changes per module: first Gradle, then AGP, then Kotlin.
  - Bumping only packages that are required by the toolchain upgrade and keeping the bump minimal.
- Rollback: revert the branch (or revert the specific commits) if CI fails and investigate incompatibilities.

### Implementation plan (tasks)

1. Create branch `feat/upgrade-toolchain` from `main`.
2. Update `gradle-wrapper.properties` and commit wrapper files.
3. Update AGP and Kotlin in `android/build.gradle` / `settings.gradle` and commit.
4. Run local smoke builds and tests.
5. Open PR titled: "chore: upgrade Gradle/AGP/Kotlin for Java 21 compatibility" with upgrade notes and CI run link.

### Notes

- This is a moderately invasive change; recommend running the PR through CI but keeping it small and iterative.
- I can prepare the initial branch and PR with the `gradle-wrapper.properties` bump and a concrete testing checklist. Reply "create PR" and I will push the branch and attempt to open the PR on GitHub (using `gh`).
