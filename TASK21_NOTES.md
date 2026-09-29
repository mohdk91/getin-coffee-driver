# GETIN DRIVER — Task #21 Verification Error States

Task #21 extends the existing customer PIN/QR verification flow with explicit, non-bypassable error handling.

Supported states:
- invalid PIN / invalid QR
- expired challenge
- wrong order
- customer mismatch
- assigned-driver mismatch
- already used
- too many attempts
- customer cannot find code
- camera unavailable
- API unavailable

Safety rules:
- verification failure never marks the delivery verified
- Complete Delivery remains unavailable until a valid PIN or QR verification succeeds
- too many failed demo attempts lock that verification path
- camera unavailable offers retry or PIN fallback
- customer-can't-find-code help directs the driver to current order tracking, QR fallback, or support; it never bypasses verification
- staging/production repositories still refuse to fake Laravel acknowledgement

Development demo:
- valid PIN: 4821
- QR screen includes Simulate Customer QR Scan
- QR screen includes Simulate Camera Unavailable for Task #21 testing
