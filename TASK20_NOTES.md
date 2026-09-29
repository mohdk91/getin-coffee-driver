# Driver Task #20 — Customer QR Verification

Task #20 adds a second customer-handoff verification method alongside the existing PIN flow.

## Implemented
- Customer verification now offers **Enter Delivery Code** OR **Scan Customer QR**.
- PIN remains the fallback when QR/camera scanning cannot be used.
- QR verification is bound conceptually to order, customer reference, assigned driver, expiry, and one-time use.
- Successful QR verification returns the same delivery verification receipt concept as PIN with `verificationType: qr`.
- Complete Delivery remains separate and locked for Task #22.
- Development uses a clearly labeled simulated QR scan; it does not claim the device camera or Laravel is connected.
- Staging/production repositories never invent QR data or a successful server acknowledgement.

## Deferred intentionally
- Task #21: full verification error-state UX including camera unavailable / too many attempts / customer cannot find code.
- Task #22: server-confirmed Complete Delivery.
