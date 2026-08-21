#!/bin/bash

##############################################################################
# WowCare iOS Release Build Script
#
# This script automates the iOS release build process with:
# - Clean project state
# - CocoaPods dependency resolution
# - Code obfuscation via bitcode
# - Optimized IPA generation
# - Split debug info for crash reporting
#
# Usage: ./scripts/build_ios_release.sh
##############################################################################

set -e  # Exit on any error

# AppColors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_OUTPUT_DIR="${PROJECT_ROOT}/build/ios/archive"
RELEASE_DIR="${PROJECT_ROOT}/releases"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}WowCare iOS Release Build${NC}"
echo -e "${BLUE}=================================================${NC}"
echo ""

# ============================================================================
# Step 1: Verify Prerequisites
# ============================================================================
echo -e "${YELLOW}[1/7] Verifying prerequisites...${NC}"

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}✗ Flutter not found in PATH${NC}"
    exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}✗ Xcode not found${NC}"
    exit 1
fi

if ! command -v pod &> /dev/null; then
    echo -e "${RED}✗ CocoaPods not found${NC}"
    exit 1
fi

if [ ! -f "${PROJECT_ROOT}/ios/Podfile" ]; then
    echo -e "${RED}✗ iOS Podfile not found${NC}"
    exit 1
fi

if [ ! -f "${PROJECT_ROOT}/pubspec.yaml" ]; then
    echo -e "${RED}✗ pubspec.yaml not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All prerequisites verified${NC}"
echo ""

# ============================================================================
# Step 2: Clean Build State
# ============================================================================
echo -e "${YELLOW}[2/7] Cleaning build state...${NC}"

cd "${PROJECT_ROOT}"

# Remove previous builds
rm -rf build/
rm -rf .dart_tool/flutter_build/

# Clean iOS
cd "${PROJECT_ROOT}/ios"
rm -rf Pods/
rm -rf Podfile.lock
rm -rf .symlinks/
rm -rf Flutter/Flutter.framework/
cd "${PROJECT_ROOT}"

echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# ============================================================================
# Step 3: Install CocoaPods Dependencies
# ============================================================================
echo -e "${YELLOW}[3/7] Installing CocoaPods dependencies...${NC}"

cd "${PROJECT_ROOT}/ios"

# Install pods with optimization flags
COCOAPODS_DISABLE_STATS=true pod install --repo-update 2>&1 | \
    grep -E "(Installing|Installing|Sending|downloaded|Pod installation|Generating|done)" || true

if [ ! -d "Pods/" ]; then
    echo -e "${RED}✗ Pod installation failed${NC}"
    exit 1
fi

cd "${PROJECT_ROOT}"
echo -e "${GREEN}✓ CocoaPods installation complete${NC}"
echo ""

# ============================================================================
# Step 4: Get Flutter Dependencies
# ============================================================================
echo -e "${YELLOW}[4/7] Getting Flutter dependencies...${NC}"

flutter clean
flutter pub get --no-precompile

echo -e "${GREEN}✓ Dependencies resolved${NC}"
echo ""

# ============================================================================
# Step 5: Generate Release Build
# ============================================================================
echo -e "${YELLOW}[5/7] Generating release build (this may take 3-7 minutes)...${NC}"

# Build iOS archive
echo "  → Building iOS archive..."

flutter build ipa \
    --release \
    --no-tree-shake-icons \
    --obfuscate \
    --split-debug-info="${RELEASE_DIR}/debug-symbols/${TIMESTAMP}" \
    2>&1 | grep -E "(Building|Built|error|Error|Compiling)" || true

echo -e "${GREEN}✓ iOS archive build complete${NC}"
echo ""

# ============================================================================
# Step 6: Verify Release Artifacts
# ============================================================================
echo -e "${YELLOW}[6/7] Verifying release artifacts...${NC}"

mkdir -p "${RELEASE_DIR}"
mkdir -p "${RELEASE_DIR}/debug-symbols/${TIMESTAMP}"

# Locate the build output
IPA_FILE=$(find "${PROJECT_ROOT}/build" -name "*.ipa" -type f 2>/dev/null | head -1)

if [ -z "$IPA_FILE" ]; then
    echo -e "${RED}✗ IPA file not found${NC}"
    echo "  Checked in: ${PROJECT_ROOT}/build"
    exit 1
fi

# Copy IPA
cp "$IPA_FILE" "${RELEASE_DIR}/app-release-${TIMESTAMP}.ipa"
echo -e "${GREEN}✓ IPA: app-release-${TIMESTAMP}.ipa${NC}"

# Copy debug symbols if generated
if [ -d "${RELEASE_DIR}/debug-symbols/${TIMESTAMP}" ] && [ -n "$(ls -A ${RELEASE_DIR}/debug-symbols/${TIMESTAMP})" ]; then
    echo -e "${GREEN}✓ Debug symbols: ${TIMESTAMP}${NC}"
else
    echo -e "${YELLOW}⚠ No debug symbols generated (normal for release)${NC}"
fi

echo ""

# ============================================================================
# Step 7: Display Build Summary
# ============================================================================
echo -e "${YELLOW}[7/7] Build summary...${NC}"
echo ""
echo -e "${GREEN}Release Build Complete!${NC}"
echo ""
echo "Output artifacts:"
echo "  📦 Location: ${RELEASE_DIR}"
ls -lh "${RELEASE_DIR}"/ 2>/dev/null | tail -n +2 || true
echo ""

# ============================================================================
# Build Statistics
# ============================================================================
if [ -f "${RELEASE_DIR}/app-release-${TIMESTAMP}.ipa" ]; then
    IPA_SIZE=$(du -h "${RELEASE_DIR}/app-release-${TIMESTAMP}.ipa" | cut -f1)
    echo -e "${BLUE}Build Statistics:${NC}"
    echo "  IPA Size: ${IPA_SIZE}"
fi

echo ""

# ============================================================================
# Next Steps
# ============================================================================
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Test IPA on real iOS devices:"
echo "     - Use Xcode Organizer or Apple TestFlight"
echo "     - Command: open -a Xcode ${RELEASE_DIR}/app-release-${TIMESTAMP}.ipa"
echo ""
echo "  2. Upload to App Store Connect:"
echo "     - Use Transporter or Xcode"
echo "     - File: ${RELEASE_DIR}/app-release-${TIMESTAMP}.ipa"
echo ""
echo "  3. Verify code optimization:"
echo "     - Debug symbols stored in: ${RELEASE_DIR}/debug-symbols/${TIMESTAMP}"
echo "     - Use symbols for crash reporting"
echo ""
echo "  4. Run security checks:"
echo "     - Scan with MobSF or similar static analysis tool"
echo "     - Test on jailbroken devices"
echo ""

echo -e "${GREEN}✓ Release build automation complete!${NC}"
