#!/usr/bin/env bash
set -u

REPORT_ONLY=0
if [ "${1:-}" = "--report-only" ]; then
  REPORT_ONLY=1
  shift
fi

DRIVER_ROOT="${1:-$(cd "$(dirname "$0")/../.." && pwd)}"
LARAVEL_ROOT="${2:-}"

BLOCKERS=0
CHECKS=0

pass() {
  CHECKS=$((CHECKS + 1))
  printf 'PASS %s\n' "$1"
}

block() {
  CHECKS=$((CHECKS + 1))
  BLOCKERS=$((BLOCKERS + 1))
  printf 'BLOCKED %s\n' "$1"
}

contains() {
  grep -q -- "$2" "$1" 2>/dev/null
}

printf 'GETIN Driver Release Candidate Gate\n'
printf 'Driver: %s\n' "$DRIVER_ROOT"
if [ -n "$LARAVEL_ROOT" ]; then
  printf 'Laravel: %s\n' "$LARAVEL_ROOT"
fi
printf '%s\n' '----------------------------------------'

if contains "$DRIVER_ROOT/tool/release/build_android.sh" '--dart-define=APP_ENV=prod' \
  && contains "$DRIVER_ROOT/tool/release/build_ios_codemagic.sh" '--dart-define=APP_ENV=prod'; then
  pass 'release scripts use APP_ENV=prod'
else
  block 'release scripts must use APP_ENV=prod'
fi

if [ -f "$DRIVER_ROOT/android/key.properties" ]; then
  pass 'Android release signing configuration exists locally'
else
  block 'android/key.properties is missing (real Android release signing required)'
fi

if contains "$DRIVER_ROOT/pubspec.yaml" 'firebase_messaging:'; then
  pass 'Flutter firebase_messaging dependency is present'
else
  block 'Flutter Driver native push is not wired (firebase_messaging missing)'
fi

if [ -f "$DRIVER_ROOT/android/app/google-services.json" ]; then
  pass 'Android Firebase configuration exists'
else
  block 'android/app/google-services.json is missing'
fi

if [ -f "$DRIVER_ROOT/ios/Runner/GoogleService-Info.plist" ]; then
  pass 'iOS Firebase configuration exists'
else
  block 'ios/Runner/GoogleService-Info.plist is missing'
fi

case "${GETIN_API_BASE_URL:-}" in
  https://*) pass 'GETIN_API_BASE_URL is HTTPS' ;;
  *) block 'GETIN_API_BASE_URL must be exported as the production HTTPS API URL' ;;
esac

if [ -n "$LARAVEL_ROOT" ] && [ -d "$LARAVEL_ROOT" ]; then
  if [ -f "$LARAVEL_ROOT/.env" ]; then
    PUSH_DRIVER="$(sed -n 's/^TRANSACTIONAL_PUSH_DRIVER=//p' "$LARAVEL_ROOT/.env" | tail -1 | tr -d '\r')"
    QUEUE_CONNECTION="$(sed -n 's/^QUEUE_CONNECTION=//p' "$LARAVEL_ROOT/.env" | tail -1 | tr -d '\r')"
    FIREBASE_CREDENTIALS="$(sed -n 's/^FIREBASE_CREDENTIALS=//p' "$LARAVEL_ROOT/.env" | tail -1 | tr -d '\r')"

    if [ "$PUSH_DRIVER" = "fcm" ]; then
      pass 'Laravel transactional push driver is FCM'
    else
      block 'Laravel TRANSACTIONAL_PUSH_DRIVER must be fcm'
    fi

    if [ -n "$FIREBASE_CREDENTIALS" ]; then
      pass 'Laravel FIREBASE_CREDENTIALS is configured'
    else
      block 'Laravel FIREBASE_CREDENTIALS is missing'
    fi

    if [ -n "$QUEUE_CONNECTION" ] && [ "$QUEUE_CONNECTION" != "sync" ]; then
      pass 'Laravel queue connection is asynchronous'
    else
      block 'Laravel QUEUE_CONNECTION must not be sync'
    fi
  else
    block 'Laravel .env is unavailable for local production-readiness audit'
  fi
else
  block 'Laravel root was not supplied to the release-candidate gate'
fi

printf '%s\n' '----------------------------------------'
printf 'Checks: %s | Blockers: %s\n' "$CHECKS" "$BLOCKERS"

if [ "$BLOCKERS" -eq 0 ]; then
  printf 'RC_STATUS=READY\n'
  exit 0
fi

printf 'RC_STATUS=BLOCKED\n'
if [ "$REPORT_ONLY" -eq 1 ]; then
  exit 0
fi
exit 2
