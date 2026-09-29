# Getin Driver — Task #40 Production Readiness Audit

Task #40 hardens the Flutter client without pretending unavailable backend services are production-ready.

## Hardened in this task

- Active delivery recovery cache survives app process kill/restart.
- Completed-order marker and last successful sync are persisted with the runtime recovery cache.
- App resume triggers a fresh Home sync and re-evaluates background-location context.
- Duplicate route pushes are single-flight guarded to reduce double-tap navigation races.
- Order acceptance is globally single-flight in V1 so two different orders cannot be accepted concurrently from the same screen.
- Existing critical offline guards remain authoritative for Accept Order, Received from Branch, Customer Verification, and Complete Delivery.
- Android release builds no longer fall back to the debug signing key. Real release signing is read only from gitignored `android/key.properties` when supplied.
- Android location/background-service permissions and `adjustResize` keyboard behavior are audited by the Task #40 installer.
- iOS foreground/background location usage descriptions and `UIBackgroundModes=location` are audited by the Task #40 installer.
- Final QA tests include compact 320×568 layout coverage, app resume reload, restart recovery, navigation single-flight, corrupt-cache tolerance, and V1 single acceptance.

## Production blockers that still require real infrastructure

These are intentionally not faked by the Flutter app:

1. Laravel production APIs and server acknowledgements for authentication, order locking, pickup custody, customer verification, delivery completion, chat/support, notifications, profile, earnings/commissions, documents, assignments, and background-location sync.
2. Platform secure-storage implementation for real auth/session tokens (`SecureStore` is still an explicit boundary).
3. Real native biometric implementation behind the biometric gateway.
4. Real Android release keystore and `android/key.properties`.
5. App Store / Play signing, release certificates/profiles, store metadata, and final production bundle/archive validation.
6. Real push-notification transport (APNs/FCM or the selected backend provider) for Task #29 notifications.
7. Shared Laravel contract with the Getin Customer App so Out for Delivery, driver details, chat/call, delivery code/QR, completion, and rating stay consistent across both apps.

## Release gate

Before a production release, run at minimum:

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug` for the current development validation path
- signed Android release AAB with the real Getin keystore
- iOS archive/build using the real bundle identifier, certificates, and provisioning
- physical-device tests for small Android screens, background/resume, permission changes, GPS disabled/stale/inaccurate states, slow/no network, process kill/restart, and each critical order transition

A successful Task #40 validation means the current Flutter client passes its local QA/hardening suite. It does not mean the app is production-connected until the blockers above are completed.
