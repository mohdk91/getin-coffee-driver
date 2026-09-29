# Task #38 — Offline behavior

Implemented from the Driver roadmap without changing Tasks #1–#37.

## Behavior

- Persistent offline banner across the primary Driver shell.
- Shows last successful sync time when known.
- Cached/read-only information remains visible while offline.
- Safe Retry reloads the Home sync without clearing the cached dashboard first.
- Server-confirmed critical actions are guarded while offline:
  - Accept Order
  - Received from Branch
  - Customer Verification (PIN or QR)
  - Complete Delivery
- When a guarded action is attempted offline, the repository mutation is not called and no delivery state is advanced.
- Production/staging behavior remains server-authoritative. Development demo behavior remains clearly labeled and only progresses when the app connectivity state is online.

## Connectivity source

Task #38 consumes `DriverHomeSnapshot.internetConnected` as the connectivity source already present in the Driver architecture. It does not invent a backend acknowledgement or mark a failed retry as synchronized.

## Validation

Installer runs formatting, dependency resolution, analyzer, all tests, and Android debug build.
