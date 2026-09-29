# Task #39 — Background operation

Implemented from the Driver roadmap without changing Tasks #1–#38.

## Tracking policy

Background location is policy-driven rather than permanently hardcoded into the UI:

- Track while the driver is **Online** when the Getin policy requires it.
- Track while a **non-terminal active delivery** is running.
- If an active delivery continues while the network is offline, GPS may continue locally but server location sync is explicitly paused.
- Stop background GPS while offline with no active delivery.
- Stop background GPS when there is no active delivery and the driver is not Online.
- Block background tracking when Task #37 reports disabled GPS, denied permission, denied background permission, stale location, or inaccurate GPS.

## Battery and platform behavior

- Online profile uses a lower-frequency/distance-filtered update profile.
- Active-delivery profile uses a tighter update profile.
- Android device mode uses a foreground location notification with wake-lock disabled.
- iOS enables the location background mode and allows the platform to pause non-delivery updates automatically.
- Android manifest includes background-location and foreground-location-service permissions.

## Development vs production

Development uses an explicit demo policy and a safe demo location runner by default, so widget/unit tests do not invoke native location channels.

To exercise the real device background stream in development on a physical device:

```bash
flutter run -d <device-id> \
  --dart-define=APP_ENV=dev \
  --dart-define=DRIVER_REAL_BACKGROUND_GPS=true
```

Staging/production use the device runner but do not invent a tracking policy. Background tracking waits for the Laravel driver API to provide that policy.

## Visibility

`Home → GPS & Service Region` now includes a **Background operation** card showing:

- tracking/stopped/blocked/error state
- policy version
- device vs demo location runner
- whether server location sync is allowed or paused
- interval and distance profile when active
- last background fix when available

## Validation

The installer runs formatting, dependency resolution, analyzer, all tests, and Android debug build.
