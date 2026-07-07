#!/bin/bash
# Copies the environment-specific GoogleService-Info.plist into the app bundle.
# Runs as an Xcode Run Script Build Phase (added automatically via Podfile post_install).
#
# Flutter passes --dart-define values as comma-separated base64 strings in $DART_DEFINES.
# We decode each token, find ENVIRONMENT=<value>, and lower-case it to pick the folder.
set -euo pipefail

ENVIRONMENT="local"

if [ -n "${DART_DEFINES:-}" ]; then
  IFS=',' read -ra DEFINES <<< "$DART_DEFINES"
  for token in "${DEFINES[@]}"; do
    decoded=$(echo "$token" | base64 --decode 2>/dev/null || true)
    if [[ "$decoded" == ENVIRONMENT=* ]]; then
      ENVIRONMENT="${decoded#ENVIRONMENT=}"
      ENVIRONMENT=$(echo "$ENVIRONMENT" | tr '[:upper:]' '[:lower:]')
      break
    fi
  done
fi

SRC="${SRCROOT}/firebase/${ENVIRONMENT}/GoogleService-Info.plist"
DST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

if [ ! -f "$SRC" ]; then
  echo "error: [Firebase] Missing ${SRC}"
  echo "error: Download GoogleService-Info.plist from the Firebase console for the '${ENVIRONMENT}' project"
  echo "error: and place it at ios/firebase/${ENVIRONMENT}/GoogleService-Info.plist"
  exit 1
fi

cp "$SRC" "$DST"
echo "note: [Firebase] Copied ${ENVIRONMENT}/GoogleService-Info.plist → app bundle"
