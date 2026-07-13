# Facebook Login Fix — Issue & Solution

> iOS + Android Facebook sign-in with Firebase.
> Covers Firebase credential fix and ATT-aware iOS login mode.

---

## What was broken?

Facebook login **opened and returned a token**, but **Firebase sign-in failed** with:

- Firebase error: `invalid-credential`
- Facebook error inside message: `{"code":190,"message":"Bad signature"}`

---

## Root cause (Firebase)

On iPhone, Facebook often returns a **Limited Login JWT** (`LimitedToken`), not a classic access token.

`FacebookAuthProvider.credential(tokenString)` only works for **classic** tokens.

Limited Login needs:

- `OAuthCredential` with `idToken` = JWT
- `rawNonce` = unhashed nonce from login start

---

## iOS login modes (ATT)

| User choice (ATT) | First attempt | Fallback |
|-------------------|---------------|----------|
| **Allow tracking** | `LoginTracking.enabled` (may open Facebook app) | If `LimitedToken` or failure → `limited` + nonce (same attempt) |
| **Ask not to track** | `LoginTracking.limited` + nonce | — |

Limited Login **never** opens the native Facebook app — that is expected on the fallback path.

We use `app_tracking_transparency` to read ATT. **Allow** tries classic first; if Facebook still returns a Limited JWT (common on SDK 18+), we automatically retry limited login with the same nonce so Firebase does not get `invalid-credential` / error 190.

---

## Code changes

### 1. `lib/core/services/facebook_sign_in_service.dart`

- Always generate `rawNonce` + SHA-256 hash before login (one pair per attempt).
- **iOS:** request ATT if not determined; then:
  - authorized → try `enabled`, `['email', 'public_profile']` (no nonce)
  - if classic fails or returns `LimitedToken` → `logOut` + retry `limited`, `['email']`, same hashed nonce
  - denied/restricted → `limited`, `['email']`, pass hashed nonce (single attempt)
- **Android:** `enabled`, `['email', 'public_profile']`
- Returns `FacebookSignInResult` (`accessToken` + `rawNonce`).

### 2. `lib/features/auth/data/repositories/auth_repository_impl.dart`

`_buildFacebookCredential()` by token type:

| Token | Firebase credential |
|-------|---------------------|
| `LimitedToken` | `OAuthCredential(idToken, rawNonce)` |
| `ClassicToken` | `FacebookAuthProvider.credential(tokenString)` |

### 3. iOS `Info.plist`

- `NSUserTrackingUsageDescription` — required for ATT prompt text.

### 4. `pubspec.yaml`

- `app_tracking_transparency` — read/request ATT on iOS only.

---

## Test plan

1. **iOS — decline tracking:** in-app Facebook sheet → login → Firebase succeeds.
2. **iOS — allow tracking:** may open Facebook app; if Limited JWT or failure, auto fallback to in-app limited login → Firebase succeeds.
3. **Android:** classic flow unchanged.

---

## Console setup

- **Firebase** → Auth → Facebook enabled (App ID + Secret).
- **Meta Developer** → Facebook Login, iOS bundle `com.selcom.go`, Android key hash.

---

## Files

- `lib/core/services/facebook_sign_in_service.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `ios/Runner/Info.plist`
- `pubspec.yaml`
