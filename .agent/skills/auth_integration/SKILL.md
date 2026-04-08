---
name: auth_integration
description: Selcom Identity and API integration specifications.
---

# 🔑 Auth Integration

## Identity Specifications
OTP-based logic to verify the user and issue a JWT.

### 1-OTP Request
```bash
POST /v4/send_otp
{
  "mobile_number": "07XXXXXXXX",
  "country_code": "+254"
}
```

### 2-OTP Verify
```bash
POST /v4/verify_otp
{
  "mobile_number": "07XXXXXXXX",
  "otp": "9876", // Rule 2 — 4 digits
  "country_code": "+254"
}
```

## Security Post-Verify
Upon success, several tokens are returned and must be stored securely:
- `authorization_token` (JWT): Injected as `Authorization: Bearer <token>`
- `access_token`: Injected as `access_token` header.
- `refresh_token`: For token refreshing (Phase 1).

**Never** store tokens in `SharedPreferences`. Use `FlutterSecureStorage`.
