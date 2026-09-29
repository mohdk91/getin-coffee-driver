# Driver Task #29 — Notifications

Task #29 adds the Driver notification center and the required categories:

- New Order
- Order Accepted Elsewhere
- Order Updated
- Branch Ready
- Customer Message
- Cancellation
- Delivery Verification Issue
- Earnings
- Document Expiry
- System

Development uses explicit local demo notifications with three unread alerts so the existing Home badge can be tested. Read state is mutable only inside the demo repository for this session. Staging and production use the unavailable repository until Laravel notifications are connected; they never fabricate alerts.

The notification bell now opens the full center. Marking one or all notifications read updates the shell unread badge and the Home dashboard notification status. Notification deep links and real push delivery are intentionally not invented in this task; Laravel remains the source of truth for content, delivery, read state and future actions.
