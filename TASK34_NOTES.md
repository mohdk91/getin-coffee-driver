# Task #34 — Documents

Implements the Driver Documents module from the roadmap.

## Required records and states

- ID
- Driver license
- Vehicle documents
- Insurance when applicable
- Approval state
- Expiry date
- Expiry warning
- Replacement upload flow

## Replacement behavior

Development uses the native file picker for PDF/JPG/JPEG/PNG selection. Demo mode records only the selected file name and moves the document to Pending review locally; it does not transmit file bytes. No production approval is fabricated. The repository boundary is ready for the Laravel documents API to replace the demo implementation.

## Environment behavior

Development uses local demo records with masked references. Staging/production use the unavailable repository until Laravel document endpoints are connected. The production-facing path does not invent document records, approval states, expiry dates or replacement success.
