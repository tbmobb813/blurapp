#!/bin/bash
# Build script for BlurApp
# Builds debug or release APK with proper configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parse arguments
BUILD_TYPE="${1:-debug}"

if [[ "$BUILD_TYPE" != "debug" && "$BUILD_TYPE" != "release" ]]; then
    echo "Usage: $0 [debug|release]"
    echo "  debug   - Build debug APK (default)"
    echo "  release - Build release APK"
    exit 1
fi

echo "🔨 Building BlurApp ($BUILD_TYPE mode)..."
echo ""

cd "$PROJECT_ROOT/app"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found in PATH"
    exit 1
fi

# Clean previous builds
echo "→ Cleaning previous builds..."
flutter clean

# Get dependencies
echo "→ Getting dependencies..."
flutter pub get

# Run pre-build checks
echo "→ Running format check..."
flutter format --set-exit-if-changed lib

echo "→ Running static analysis..."
flutter analyze --fatal-infos

# Build APK
echo ""
echo "→ Building $BUILD_TYPE APK..."
START_TIME=$(date +%s)

if [ "$BUILD_TYPE" = "release" ]; then
    flutter build apk --release
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
else
    flutter build apk --debug
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Display build info
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo ""
    echo "✅ Build completed in ${DURATION}s"
    echo ""
    echo "📦 APK Info:"
    echo "   Path: $APK_PATH"
    echo "   Size: $APK_SIZE"
    echo ""

    if [ "$BUILD_TYPE" = "debug" ]; then
        echo "To install: adb install $APK_PATH"
    else
        echo "Release APK ready for distribution"
    fi
else
    echo "❌ Build failed - APK not found"
    exit 1
fi
