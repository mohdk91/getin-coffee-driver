# GETIN Driver — Task #17 Customer Contact

Implemented:
- CALL | CHAT controls on the Out for Delivery navigation screen.
- Protected call repository architecture; development does not invent or expose a customer phone number.
- Order-specific customer chat using the same conceptual thread id shape as the Customer App: `driver:<orderId>`.
- Local development persistence with SharedPreferences.
- Driver/customer/system message roles and Customer App-aligned bubble layout.
- Production/staging repository refuses to fake customer chat until Laravel is connected.
- Task #30 quick replies intentionally not added yet.

Scope intentionally deferred:
- Full delivery address and instructions: Task #18.
- Customer delivery PIN/QR: Tasks #19-21.
- Driver quick replies and richer driver-to-customer chat behavior: Task #30.
- Getin support chat: Task #31.
