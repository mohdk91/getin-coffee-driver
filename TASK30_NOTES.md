# GETIN Driver — Task #30 Driver → Customer Chat

Implemented:
- Preserves Task #17 order-specific customer chat thread (`driver:<orderId>`).
- Adds the six roadmap quick replies as one-tap messages.
- Quick replies use the same repository path as typed messages, so they remain tied to the active order.
- Development keeps clearly local/demo persistence; staging/production still refuse to fake Laravel chat.
- Customer phone/privacy behavior from Task #17 remains unchanged.

Quick replies:
- I’m arriving soon
- I’m outside
- Please come down
- Please check your phone
- I’m at the entrance
- Where should I meet you?

Deferred:
- Driver → Getin Support Chat is Task #31.
