# Facebook Login Fix — Issue & Solution

> Simple guide for the Facebook sign-in fix on iOS (and Android).
> Commit: `fix(auth): support Facebook Limited Login for Firebase sign-in`

---

## What was broken?

Facebook login **opened and returned a token**, but **Firebase sign-in failed** with:

- Firebase error: `invalid-credential`
- Facebook error inside message: `{"code":190,"message":"Bad signature"}`

So the user could log in with Facebook, but the app could not complete sign-in.

---

## Why did it happen? (simple explanation)

On **iPhone**, Facebook often uses **Limited Login**. That gives a **JWT token** (a long `eyJ...` string), not the old-style Facebook access token.

Our old code always did this:

```dart
FacebookAuthProvider.credential(tokenString)
```

That works for **classic** Facebook tokens (common on Android).

It does **not** work for **Limited Login** tokens on iOS. Firebase needs a different credential:

- put the JWT in `idToken` (not as a plain access token)
- also send the **raw nonce** that was used when starting Facebook login

Without that, Firebase rejects the token → **Bad signature (190)**.

---

## What was NOT the problem?

- `currentUser == null` before sign-in is **normal** when the user is not already logged into Firebase.
- `firebase_auth_data_source.dart` was fine — it only calls Firebase; the bug was in how we built the Facebook credential.

---

## What we changed

### 1. `lib/core/services/facebook_sign_in_service.dart`

**Before:** Returned only `AccessToken` from Facebook login.

**After:**

- Generate a **random nonce** before login.
- Send **SHA-256 hash of nonce** to Facebook (`nonce` parameter).
- Keep the **original raw nonce** for Firebase.
- On iOS use `LoginTracking.limited`.
- Return `FacebookSignInResult` with:
  - `accessToken`
  - `rawNonce`

### 2. `lib/features/auth/data/repositories/auth_repository_impl.dart`

**Before:** Always used `FacebookAuthProvider.credential(tokenString)`.

**After:** New helper `_buildFacebookCredential()`:

| Token type | Platform | Firebase credential |
|------------|----------|---------------------|
| `LimitedToken` | iOS (Limited Login) | `OAuthCredential` with `idToken` + `rawNonce` |
| `ClassicToken` | Android / classic iOS | `FacebookAuthProvider.credential(tokenString)` |

---

## Flow after fix (short)

1. User taps **Sign in with Facebook**.
2. App creates nonce → Facebook login runs.
3. Facebook returns token (limited or classic).
4. App builds the **correct** Firebase credential for that token type.
5. Firebase `signInWithCredential` succeeds.
6. App continues with backend session exchange (same as Google/Apple).

---

## How to test

1. Run on a **real iPhone** (Limited Login is an iOS behavior).
2. Tap **Sign in with Facebook** on the login screen.
3. Complete Facebook login.
4. Expect: no `invalid-credential` / `Bad signature` error.
5. User should reach the normal post-login flow (profile / phone attach, etc.).

Also test on **Android** to confirm classic token path still works.

---

## Console setup (must already be correct)

These are not code changes, but login will still fail if misconfigured:

- **Firebase Console** → Authentication → Facebook enabled (App ID + App Secret).
- **Facebook Developer** → app has Facebook Login, correct iOS bundle ID and Android key hash.

---

## Files touched

- `lib/core/services/facebook_sign_in_service.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`

No other features were changed in this fix.
