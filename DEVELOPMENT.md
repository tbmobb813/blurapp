# Development setup

This project uses Android Studio (snap) for Android development. The repository expects developers to point Flutter to a single Android Studio installation and, optionally, to the JDK bundled with that IDE.

Recommended setup (snap)

1. Install Android Studio via snap (classic):

   sudo snap install android-studio --classic

2. Configure Flutter to use the snap-mounted Android Studio and its JDK (run on each dev machine):

   flutter config --android-studio-dir="/snap/android-studio/current"
   flutter config --jdk-dir="/snap/android-studio/current/jbr"

Notes

- We prefer the snap install because it exposes a full IDE layout and bundles a consistent JDK (OpenJDK 21) compatible with the project's Android Gradle Plugin and Java target.
- If you use a different Android Studio install method (JetBrains tarball, Toolbox, or distro package), update the `--android-studio-dir` and `--jdk-dir` values accordingly.
- If you previously used a Flatpak Android Studio, remove any shim you created (for example `~/.local/android-studio-flatpak-shim`) to avoid confusion.

Troubleshooting

- If `flutter doctor` still lists Android Studio as "version unknown", this is usually cosmetic with snap installs; builds will still work as long as the Android SDK and JDK are detected.
- Ensure your SDK is installed and `ANDROID_SDK_ROOT` points to the correct SDK folder (e.g., `/home/<user>/Android/Sdk`).
