# Driver Task #16 — Navigation

Task #16 adds external navigation launching while preserving Tasks #1–#15.

Implemented:
- System/default navigation app on Android (`geo:` intent).
- Google Maps app launch with universal Google Maps fallback.
- Apple Maps launch on iOS.
- Preferred navigation app stored with SharedPreferences.
- Navigation app chooser.
- Branch navigation from the existing Route to Branch flow using branch coordinates.
- After Start Delivery, resuming the active delivery opens a destination-area navigation screen.
- Destination-area navigation is intentionally labeled as area-level only until Task #18 supplies the exact customer pin/address/building/floor/apartment/instructions.
- No embedded turn-by-turn map; external routing only.

Privacy/scope:
- Customer name, phone and account information are not added in Task #16.
- Task #17 customer contact is not implemented here.
- Task #18 exact destination/instructions are not implemented here.
