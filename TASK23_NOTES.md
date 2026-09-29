# Driver Task #23 — Delivery Exceptions

Implemented exception reasons:
- customer unavailable
- wrong address
- customer refused
- cannot access building
- damaged order
- safety issue
- support required
- return to branch

Safety rules:
- reporting an exception never marks an order Delivered;
- development reports are local/demo only;
- production does not change order state without Getin/Laravel acknowledgement;
- an active exception blocks Complete Delivery in the current delivery flow;
- demo exception state is retained in memory for the active order;
- Task #24 will formalize terminal/problem state transitions.
