# Task #35 — Branch / Region Assignment

Implemented the driver operational-assignment module without changing Tasks #1–#34.

## Scope

- Assigned city
- Service regions
- Allowed branches
- Service radius
- Backend-policy governance for assignment changes
- Profile entry point
- Demo-only development data; no fabricated staging/production assignments

## Data ownership

The Driver App is not the source of truth for operational assignment. City, regions,
allowed branches, service radius and change permission must ultimately come from
Laravel. Development uses clearly labeled local demo data only.
