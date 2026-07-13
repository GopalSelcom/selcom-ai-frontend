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

| User choice (ATT) | Facebook mode | UI | Token |
|-------------------|---------------|-----|-------|
| **Allow tracking** | `LoginTracking.enabled` | May open Facebook app | `ClassicToken` |
| **Ask not to track** | `LoginTracking.limited` | In-app sheet only | `LimitedToken` |

Limited Login **never** opens the native Facebook app — that is expected.

We use `app_tracking_transparency` to read ATT and pick the mode. Sign-in still works if the user declines tracking.

---

## Code changes

### 1. `lib/core/services/facebook_sign_in_service.dart`

- Always generate `rawNonce` + SHA-256 hash before login.
- **iOS:** request ATT if not determined; then:
  - authorized → `enabled`, `['email', 'public_profile']`, no nonce param
  - denied → `limited`, `['email']`, pass hashed nonce
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
2. **iOS — allow tracking:** may open Facebook app → `ClassicToken` → Firebase succeeds.
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
