#!/bin/bash
# Install Git pre-commit hooks for BlurApp
# This script sets up automatic code quality checks before commits

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "Installing Git pre-commit hooks..."

# Create pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook for BlurApp
# Runs format checks and linting before allowing commit

set -e

echo "Running pre-commit checks..."

# Navigate to app directory
cd "$(git rev-parse --show-toplevel)/app"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "Warning: Flutter not found in PATH. Skipping pre-commit checks."
    exit 0
fi

# 1. Format check
echo "→ Checking code formatting..."
if ! flutter format --set-exit-if-changed lib test; then
    echo "❌ Code formatting issues detected!"
    echo "   Run 'flutter format .' to fix formatting."
    exit 1
fi
echo "✓ Code formatting OK"

# 2. Analyze
echo "→ Running static analysis..."
if ! flutter analyze --fatal-infos; then
    echo "❌ Analysis issues detected!"
    echo "   Fix the issues above before committing."
    exit 1
fi
echo "✓ Static analysis OK"

# 3. Run tests (optional - can be slow, uncomment to enable)
# echo "→ Running tests..."
# if ! flutter test; then
#     echo "❌ Tests failed!"
#     echo "   Fix failing tests before committing."
#     exit 1
# fi
# echo "✓ Tests OK"

echo "✅ All pre-commit checks passed!"
exit 0
EOF

# Make hook executable
chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Pre-commit hooks installed successfully!"
echo ""
echo "The following checks will run before each commit:"
echo "  • Code formatting (flutter format)"
echo "  • Static analysis (flutter analyze)"
echo ""
echo "To temporarily skip hooks, use: git commit --no-verify"
echo ""
