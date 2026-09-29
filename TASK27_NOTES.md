# GETIN DRIVER — Task 27

Task 27 adds Driver Commissions without making Flutter the business-rule source of truth.

## Added
- Dedicated Driver Commissions screen reachable from Earnings.
- Backend-ready commission policy model and repository boundary.
- Version/effective-date metadata.
- Demo policy for development only.
- Rules for base earning, distance bonus, peak bonus, tips and adjustments.
- Historical snapshot/audit requirements.
- Production/staging repository that refuses to invent rules before Laravel is connected.

## Important
The demo amounts and percentages are sample policy data returned by the demo repository. They are not permanent business rules and are not a production payout promise.
