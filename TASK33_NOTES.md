# Task #33 — Vehicle

Implements the Driver Vehicle module from the roadmap.

## Required fields

- Vehicle type
- Plate
- Make/model
- Color
- Vehicle status
- Document status

## Edit permissions

Vehicle field editability is data-driven. The repository supplies `editableFields`; Flutter does not permanently decide which production fields a driver may change. The development demo permits make/model and color only so the permission behavior can be tested. Vehicle type and plate remain Getin-managed in the demo. Vehicle status and document status are always presented as operational state and are not edited from this screen.

## Environment behavior

Development uses clearly labeled local demo data. Staging/production use the unavailable repository until the Laravel vehicle endpoints are connected and do not fabricate vehicle records or approval state.
