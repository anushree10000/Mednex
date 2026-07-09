#!/bin/bash
# ──────────────────────────────────────────────────────────
#  MedNex Unit Test Runner
#  Run from the MedNex project root:  sh run_tests.sh
# ──────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC="$SCRIPT_DIR/MedNex/Shared/Models"
EXT="$SCRIPT_DIR/MedNex/Shared/Extensions"
TEST_SRC="$SCRIPT_DIR/MedNexTests/MedNexAllTests.swift"
BUILD_DIR="/tmp/MedNexTestBuild"
OUTPUT="$BUILD_DIR/MedNexTestRunner"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║           MedNex — Comprehensive Unit Test Suite          ║"
echo "╠════════════════════════════════════════════════════════════╣"
echo "║  Compiling models + extensions + tests …                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Prepare build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Copy model + extension files into build dir (these are library files)
for f in "$SRC"/*.swift "$EXT/Date+Formatting.swift"; do
    cp "$f" "$BUILD_DIR/"
done

# The test file must be the ONLY file allowed top-level code.
# Swift requires the file with top-level code to be named main.swift
# when compiling with -parse-as-library for the other files.
# Approach: compile everything without -parse-as-library and use
# -Xfrontend -entry-point-function-name with -main-class or just
# compile the test as the single main.swift

# Simpler: copy test file as main.swift — only one file can have top-level code
cp "$TEST_SRC" "$BUILD_DIR/main.swift"

# Remove original model names that clash (Date+Formatting → already copied)
# The main.swift IS the test file, other .swift files are the models

# Verify files exist
FILE_COUNT=$(ls "$BUILD_DIR"/*.swift 2>/dev/null | wc -l | tr -d ' ')
echo "  📁 Compiling $FILE_COUNT Swift files …"
echo ""

SDK_PATH=$(xcrun --show-sdk-path --sdk macosx)

swiftc \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macos14.0 \
    "$BUILD_DIR"/*.swift \
    -o "$OUTPUT" 2>&1

if [ $? -ne 0 ]; then
    echo ""
    echo "  ❌ Compilation failed. See errors above."
    rm -rf "$BUILD_DIR"
    exit 1
fi

echo "  ✅ Compilation successful!"
echo ""

# Run the test binary
echo "  Running tests …"
echo ""

"$OUTPUT"
EXIT_CODE=$?

# Cleanup
rm -rf "$BUILD_DIR"

exit $EXIT_CODE
