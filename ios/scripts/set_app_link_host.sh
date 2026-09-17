#!/bin/bash
# Sets the Associated Domains host in Runner-Release.entitlements (the
# entitlements file used for Profile/Release/ipa builds — see project.pbxproj
# CODE_SIGN_ENTITLEMENTS) to match the environment a Makefile release target
# is building for.
#
# Called from the Makefile immediately before `flutter build …` and followed
# by `git checkout -- ios/Runner/Runner-Release.entitlements` right after, so
# the tracked file is only mutated for the duration of that one build and the
# working tree is clean again once it finishes (or fails).
#
# Usage: ios/scripts/set_app_link_host.sh <local|qa|uat|prod>
set -euo pipefail

ENVIRONMENT="$(echo "${1:-uat}" | tr '[:upper:]' '[:lower:]')"

if [ "$ENVIRONMENT" = "prod" ]; then
  HOST="wowcare.childcarewow.app"
else
  # LOCAL/QA/UAT all share the one UAT well-known host — only PROD gets its
  # own AASA/assetlinks.json, per the gateway's WellKnownController config.
  HOST="wowcare-uat.childcarewow.app"
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENTITLEMENTS="${REPO_ROOT}/ios/Runner/Runner-Release.entitlements"

/usr/libexec/PlistBuddy -c "Set :com.apple.developer.associated-domains:0 applinks:${HOST}" "$ENTITLEMENTS"
echo "note: [AppLinks] env=${ENVIRONMENT} → applinks:${HOST} (Runner-Release.entitlements)"
