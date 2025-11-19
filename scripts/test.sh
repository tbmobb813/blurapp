#!/bin/bash
# Test script for BlurApp
# Runs tests with coverage and generates reports

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Parse arguments
COVERAGE="${1:-true}"

if [[ "$COVERAGE" != "true" && "$COVERAGE" != "false" ]]; then
    COVERAGE="true"
fi

echo "🧪 Running BlurApp tests..."
echo ""

cd "$PROJECT_ROOT/app"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found in PATH"
    exit 1
fi

# Run tests
START_TIME=$(date +%s)

if [ "$COVERAGE" = "true" ]; then
    echo "→ Running tests with coverage..."
    flutter test --coverage
else
    echo "→ Running tests..."
    flutter test
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo "✅ Tests completed in ${DURATION}s"

# Generate coverage summary if coverage was collected
if [ "$COVERAGE" = "true" ] && [ -f "coverage/lcov.info" ]; then
    echo ""
    echo "📊 Coverage Summary:"
    TOTAL_LINES=$(grep -c "^DA:" coverage/lcov.info || echo "0")
    COVERED_LINES=$(grep "^DA:" coverage/lcov.info | grep -v ",0$" | wc -l || echo "0")

    if [ "$TOTAL_LINES" -gt 0 ]; then
        COVERAGE_PCT=$((COVERED_LINES * 100 / TOTAL_LINES))
        echo "   Coverage: $COVERAGE_PCT% ($COVERED_LINES/$TOTAL_LINES lines)"
        echo "   Report: coverage/lcov.info"
        echo ""

        # Suggest viewing coverage
        if command -v lcov &> /dev/null; then
            echo "To generate HTML report:"
            echo "  genhtml coverage/lcov.info -o coverage/html"
            echo "  open coverage/html/index.html"
        fi
    else
        echo "   No coverage data found"
    fi
fi

echo ""
