# Task #31 — Driver → Getin Support Chat

Implemented from the Driver roadmap:

- Real development/demo support-chat UI.
- Order-aware support context when launched from an active delivery.
- General support thread when there is no active order.
- Required quick topics:
  - Pickup issue
  - Customer unavailable
  - Address issue
  - Payment/verification issue
  - Damaged package
  - Safety issue
  - Talk to operations
- Local demo persistence uses an isolated support thread per order.
- Demo support acknowledgement is explicitly labeled and never presented as a real operations reply.
- Staging/production repository does not fabricate conversations before Laravel support APIs are connected.
- Existing Route to Branch Support action now opens the order-aware chat.
- Delivery Destination includes direct Getin Support access.
- The shell header includes a Getin Support action; if an active order exists its context is attached.
- Ratings review disputes open Getin Support with the review order and a draft message; customer reviews remain unchanged/read-only.
