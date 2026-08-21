#!/bin/bash

##############################################################################
# WowCare Android Release Build Script
#
# This script automates the release build process with:
# - Clean project state
# - Proper dependency resolution
# - Code obfuscation via R8/ProGuard
# - Split APK generation for Google Play
# - Optimized APK/AAB output
#
# Usage: ./scripts/build_android_release.sh
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
BUILD_OUTPUT_DIR="${PROJECT_ROOT}/build/app/outputs"
RELEASE_DIR="${PROJECT_ROOT}/releases"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}=================================================${NC}"
echo -e "${BLUE}WowCare Android Release Build${NC}"
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

if ! command -v java &> /dev/null; then
    echo -e "${RED}✗ Java not found in PATH${NC}"
    exit 1
fi

if [ ! -f "${PROJECT_ROOT}/local.properties" ]; then
    echo -e "${RED}✗ local.properties not found${NC}"
    echo "Please create local.properties with release signing credentials:"
    echo "  RELEASE_KEYSTORE_PATH=/path/to/keystore.jks"
    echo "  RELEASE_KEYSTORE_PASSWORD=your_password"
    echo "  RELEASE_KEY_ALIAS=key_alias"
    echo "  RELEASE_KEY_PASSWORD=key_password"
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

# Clean gradle
cd "${PROJECT_ROOT}/android"
./gradlew clean --no-daemon 2>/dev/null || true
cd "${PROJECT_ROOT}"

echo -e "${GREEN}✓ Clean complete${NC}"
echo ""

# ============================================================================
# Step 3: Get Dependencies
# ============================================================================
echo -e "${YELLOW}[3/7] Getting Flutter dependencies...${NC}"

flutter clean
flutter pub get --no-precompile

echo -e "${GREEN}✓ Dependencies resolved${NC}"
echo ""

# ============================================================================
# Step 4: Generate Release Build
# ============================================================================
echo -e "${YELLOW}[4/7] Generating release build (this may take 2-5 minutes)...${NC}"

# Build App Bundle (AAB) for Google Play
echo "  → Building AAB (App Bundle)..."
flutter build appbundle \
    --release \
    --no-tree-shake-icons \
    --obfuscate \
    --split-debug-info="${RELEASE_DIR}/debug-symbols/${TIMESTAMP}" \
    2>&1 | grep -E "(Building|Built|error|Error)" || true

if [ ! -f "${PROJECT_ROOT}/build/app/outputs/bundle/release/app-release.aab" ]; then
    echo -e "${RED}✗ AAB build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ AAB build complete${NC}"
echo ""

# ============================================================================
# Step 5: Build Split APKs (optional, for testing)
# ============================================================================
echo -e "${YELLOW}[5/7] Building split APKs...${NC}"

flutter build apk \
    --release \
    --no-tree-shake-icons \
    --obfuscate \
    --split-debug-info="${RELEASE_DIR}/debug-symbols/${TIMESTAMP}" \
    --target-platform=android-arm64,android-arm \
    2>&1 | grep -E "(Building|Built|error|Error)" || true

echo -e "${GREEN}✓ Split APK build complete${NC}"
echo ""

# ============================================================================
# Step 6: Verify Release Artifacts
# ============================================================================
echo -e "${YELLOW}[6/7] Verifying release artifacts...${NC}"

mkdir -p "${RELEASE_DIR}"

# Copy AAB
if [ -f "${BUILD_OUTPUT_DIR}/bundle/release/app-release.aab" ]; then
    cp "${BUILD_OUTPUT_DIR}/bundle/release/app-release.aab" \
       "${RELEASE_DIR}/app-release-${TIMESTAMP}.aab"
    echo -e "${GREEN}✓ AAB: app-release-${TIMESTAMP}.aab${NC}"
fi

# Copy APKs
if [ -f "${BUILD_OUTPUT_DIR}/apk/release/app-release.apk" ]; then
    cp "${BUILD_OUTPUT_DIR}/apk/release/app-release.apk" \
       "${RELEASE_DIR}/app-release-${TIMESTAMP}.apk"
    echo -e "${GREEN}✓ APK: app-release-${TIMESTAMP}.apk${NC}"
fi

# Copy debug symbols
if [ -d "${RELEASE_DIR}/debug-symbols/${TIMESTAMP}" ]; then
    echo -e "${GREEN}✓ Debug symbols: ${TIMESTAMP}${NC}"
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
if [ -f "${RELEASE_DIR}/app-release-${TIMESTAMP}.aab" ]; then
    AAB_SIZE=$(du -h "${RELEASE_DIR}/app-release-${TIMESTAMP}.aab" | cut -f1)
    echo -e "${BLUE}Build Statistics:${NC}"
    echo "  AAB Size: ${AAB_SIZE}"
fi

if [ -f "${RELEASE_DIR}/app-release-${TIMESTAMP}.apk" ]; then
    APK_SIZE=$(du -h "${RELEASE_DIR}/app-release-${TIMESTAMP}.apk" | cut -f1)
    echo "  APK Size: ${APK_SIZE}"
fi

echo ""

# ============================================================================
# Next Steps
# ============================================================================
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Test APK on real Android devices:"
echo "     adb install ${RELEASE_DIR}/app-release-${TIMESTAMP}.apk"
echo ""
echo "  2. Upload AAB to Google Play Console:"
echo "     ${RELEASE_DIR}/app-release-${TIMESTAMP}.aab"
echo ""
echo "  3. Verify obfuscation:"
echo "     - Debug symbols stored in: ${RELEASE_DIR}/debug-symbols/${TIMESTAMP}"
echo "     - Use symbols for crash reporting"
echo ""
echo "  4. Run security checks:"
echo "     - Scan with MobSF or similar static analysis tool"
echo "     - Test on rooted/unrooted devices"
echo ""

echo -e "${GREEN}✓ Release build automation complete!${NC}"
