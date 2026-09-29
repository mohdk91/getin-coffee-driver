# Getin Driver

Flutter driver application for Getin Coffee.

## Current roadmap status

**Driver Task #1 — Project foundation + design system**

Task #1 contains project/environment configuration, API and repository boundaries, the Getin operational design tokens, reusable responsive scaffold/navigation, status/warning/loading/error/empty patterns, secure-storage-ready and localization-ready contracts, and Android/iOS launcher branding.

Authentication, onboarding and delivery workflows are intentionally **not** implemented in Task #1.

## Environments

Development (default):

```bash
flutter run -d 2209116AG --dart-define=APP_ENV=dev
```

Staging:

```bash
flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging.example.com/api
```

Production architecture:

```bash
flutter run --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://api.example.com/api
```

`API_BASE_URL` is intentionally empty by default. The UI must not imply the Laravel backend is connected when it is not.

## Android compatibility note

The Driver project uses the same uploaded Android Gradle baseline as the existing working Customer App reference: Gradle 7.6.3 / Android Gradle Plugin 7.3.0 / Kotlin Android plugin 1.9.0. This is a targeted fix for the previous Kotlin 1.7.10 resolution failure, not a blind project-wide upgrade.
