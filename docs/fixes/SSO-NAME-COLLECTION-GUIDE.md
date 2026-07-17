# SSO Name Collection — Requirement & Frontend Guide

> Collect a display name when Google, Apple, or Facebook sign-in does not provide one.
> Related API: `firebase_login` → `needs_name` flag, `POST /go/auth/set_name`

---

## Why is this needed?

After SSO (Google, Apple, Facebook), the app exchanges the Firebase session via `POST /go/auth/firebase_login`. In some cases **no display name** is available:

| Provider | Typical case |
|----------|----------------|
| **Apple** | Hide My Email / private relay — name is only shared on the **first** Apple sign-in; later logins or relay accounts often have no name |
| **Google** | Account has no display name set |
| **Facebook** | Profile name not returned or not linked |

Without a name, the rider profile is incomplete (support, receipts, driver-facing UI, etc.). The backend therefore exposes `needs_name` so the app can ask once and persist the name before continuing login.

---

## Backend contract (summary)

### 1. `firebase_login` response

New field in `data`:

```json
{
  "needs_name": true,
  "needs_phone": true
}
```

- `needs_name` — `true` when there is **no name** from Firebase SSO **and** none in the DB. Show the name field.
- `needs_phone` — unchanged; user must attach a phone number.
- **Independent flags** — both can be `true`; collect **name + phone on the same screen**.

### 2. `POST /v4/go/auth/set_name` (auth required)

Call when `needs_name === true`, using the `accessToken` from `firebase_login`.

**Headers:** `Authorization: Bearer <accessToken>`, `Content-Type: application/json`, plus usual `device_type`, `app_uuid`, `device_token`.

**Body:**

```json
{ "name": "John Doe" }
```

- `name` required, 1–120 characters.

**Success (200):**

```json
{
  "status_code": 200,
  "message": "Profile updated successfully",
  "data": {
    "user": {
      "_id": "6a4b5f7084fd290007222211",
      "name": "Priyansh"
    }
  }
}
```

`data.user` is **partial** (only `_id` and `name`). The app merges `name` into the locally stored user — it does not replace the full profile blob.

**Errors:** 400 (missing/invalid name), 403 (invalid/missing session).

### 3. Unchanged endpoints

`send_otp` and `verify_otp` are **not** modified.

---

## Frontend flow

```
SSO (Google / Apple / Facebook)
        ↓
firebase_login
        ↓
   needs_name?
    /        \
  false      true
   |          |
   |     Phone screen shows Full name field (above phone)
   |          |
   |     User taps Continue
   |          ↓
   |     POST /set_name  (Bearer accessToken)
   |          ↓
   +-----→ send_otp → verify_otp → …
```

**Order when both flags are true:** `set_name` → `send_otp` → `verify_otp`.

---

## What we implemented

### UI — `PhoneInputScreen`

- When `controller.needsName` is true, a **Full name** field appears **above** the phone number row.
- Uses the same `AppFocusInputField` styling as the phone input (app theme).
- Continue stays hidden until phone **and** name (if required) are valid.

### Controller — `AuthController`

| Piece | Role |
|-------|------|
| `needsName` | From `firebase_login` `needs_name`, or inferred on app resume if stored user has empty `name` |
| `userName` | Text entered in the name field |
| `setName()` | Validates 1–120 chars, calls API, updates local user, clears `needsName` |
| `sendOtpAndNavigate()` | If `needsName`, calls `setName()` first, then `sendOtp()` |
| `canRequestOtp` | Requires valid phone; also valid name when `needsName` is true |

### Data / API layer

| File | Purpose |
|------|---------|
| `verify_otp_response.dart` | Parses `needs_name` on `VerifyOtpData` |
| `set_name_request.dart` | Request body `{ "name": "…" }` |
| `set_name_response.dart` | Parses success envelope + `data.user` |
| `urls.dart` | `URLS.auth.setName` → `go/auth/set_name` |
| `auth_remote_data_source.dart` | `setName()` — authenticated POST |
| `set_name_use_case.dart` | Use case wrapper |
| `auth_binding.dart` | Registers `SetNameUseCase` on `AuthController` |

---

## App resume (splash)

If the user already has an access token and is sent back to the phone screen (phone attach flow), but the stored user has **no name**, `needsName` is set to `true` again so they still see the name field.

---

## How to test

1. Sign in with **Apple** (Hide My Email) or a **Google** account with no display name.
2. Confirm `firebase_login` returns `needs_name: true`.
3. On the phone screen, confirm **Full name** appears above the phone field.
4. Enter name + phone → Continue.
5. Verify network: `set_name` runs **before** `send_otp`.
6. Complete OTP — profile should show the saved name.

---

## Related code

- Screen: `lib/features/auth/presentation/screens/phone_input_screen.dart`
- Controller: `lib/features/auth/presentation/controllers/auth_controller.dart`
- SSO entry: `signInWithGoogle` / `signInWithApple` / `signInWithFacebook` → `_completeSocialSignIn` → `exchangeFirebaseSession` → `_persistLoginSession`
