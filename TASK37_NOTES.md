# Task #37 — GPS Handling

Implemented the Driver roadmap GPS handling states:

- location services disabled
- foreground location permission denied / blocked
- background location permission denied
- stale location fix
- inaccurate GPS fix
- retry / recovery actions

## Device GPS

`DeviceDriverGpsGateway` uses the `geolocator` plugin to read device location-service state, permission state, current/last-known position, fix age, and accuracy. The GPS screen does not silently substitute demo coordinates when device GPS is unavailable.

Thresholds currently used by the device adapter match the existing eligibility engine defaults:

- maximum GPS fix age: 3 minutes
- maximum GPS accuracy radius: 50 metres

These are adapter defaults and can later be supplied from Laravel policy/config rather than becoming permanent business rules.

## Permissions

Android includes coarse, fine, and background location declarations. iOS includes When In Use and Always/When In Use purpose strings. Background permission is treated as a distinct readiness state. The app does not start a permanent background tracking service in Task #37; this task handles permission/readiness and recovery only.

## Home integration

When the driver opens GPS & Service Region, the live GPS state is reported back to the Home dashboard so Ready / Disabled / Permission denied / Background denied / Stale / Inaccurate can be surfaced instead of keeping the previous hard-coded Ready state.

## Testing

`DemoDriverGpsGateway` exists for deterministic widget/unit tests and can simulate every required Task #37 state. The normal app screen uses `DeviceDriverGpsGateway` unless a test/demo gateway is injected.
