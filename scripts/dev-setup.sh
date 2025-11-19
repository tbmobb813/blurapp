#!/bin/bash
# Development environment setup script for BlurApp
# Run this once to set up your development environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Setting up BlurApp development environment..."
echo ""

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found!"
    echo "   Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✓ Flutter found: $(flutter --version | head -n 1)"

# Navigate to app directory
cd "$PROJECT_ROOT/app"

# Install dependencies
echo ""
echo "→ Installing Flutter dependencies..."
flutter pub get

# Run code generation (if needed in future)
# echo ""
# echo "→ Running code generation..."
# flutter pub run build_runner build --delete-conflicting-outputs

# Verify setup
echo ""
echo "→ Verifying setup with format and analyze..."
flutter format lib test
flutter analyze

echo ""
echo "→ Running tests to verify everything works..."
flutter test

echo ""
echo "✅ Development environment setup complete!"
echo ""
echo "Next steps:"
echo "  1. Install Git hooks: ./scripts/install-hooks.sh"
echo "  2. Run the app: cd app && flutter run"
echo "  3. Build APK: ./scripts/build.sh"
echo ""
