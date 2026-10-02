#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$ROOT"

: "${GETIN_API_BASE_URL:?Set GETIN_API_BASE_URL to the production HTTPS API URL}"
: "${GETIN_BUILD_NAME:?Set GETIN_BUILD_NAME, for example 1.0.0}"
: "${GETIN_BUILD_NUMBER:?Set GETIN_BUILD_NUMBER to an increasing integer}"

case "$GETIN_API_BASE_URL" in
  https://*) ;;
  *) echo "ERROR: GETIN_API_BASE_URL must use HTTPS" >&2; exit 2 ;;
esac

case "$GETIN_BUILD_NUMBER" in
  ''|*[!0-9]*) echo "ERROR: GETIN_BUILD_NUMBER must be numeric" >&2; exit 2 ;;
esac

# Codemagic must provide Apple signing and an App Store-compatible Xcode image.
flutter pub get
flutter build ipa --release \
  --build-name="$GETIN_BUILD_NAME" \
  --build-number="$GETIN_BUILD_NUMBER" \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL="$GETIN_API_BASE_URL"

echo "Driver iOS production IPA build: PASS"
