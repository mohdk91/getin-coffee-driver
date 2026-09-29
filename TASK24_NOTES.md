# Driver Task #24 — Active Delivery Timeline / State Machine

Task #24 formalizes the active delivery lifecycle and prevents impossible order-state jumps.

Core lifecycle:

- accepted
- going_to_branch
- arrived_at_branch
- picked_up
- out_for_delivery
- arrived_customer
- verification_pending
- delivered

Terminal/problem states:

- cancelled
- failed_delivery
- returned_to_branch

Key behavior:

- `accepted -> delivered` is rejected.
- `picked_up -> delivered` is rejected.
- Starting customer verification advances through `arrived_customer` before `verification_pending`.
- Delivery completion is only enabled from `verification_pending` after PIN/QR verification.
- Delivery exceptions move the active delivery to `failed_delivery` or `returned_to_branch` and lock normal progression.
- The Route to Branch and Delivery Destination screens display a read-only Active Delivery Timeline.
- Development state is local/in-memory only. Laravel remains the future source of truth for production transitions and audit timestamps.
