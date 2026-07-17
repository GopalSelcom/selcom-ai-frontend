# Session Expiry Flow

This document explains how the Selcom Go frontend handles an expired or revoked user session.

## Goal

When the backend says the user's session is no longer valid, the app should:

1. Stop authenticated background activity
2. Clear local session state exactly once
3. Show one session-expired dialog
4. Send the user to `Login` only after they acknowledge the dialog
5. Prevent duplicate dialogs and auth-refresh loops while teardown is in progress

## Main Files

- `lib/core/services/session_expiry_service.dart`
- `lib/core/network/api_service.dart`
- `lib/features/auth/presentation/screens/splash_screen.dart`
- `lib/features/profile/presentation/controllers/profile_controller.dart`
- `lib/features/home/presentation/controllers/home_controller.dart`
- `lib/features/ride/presentation/controllers/driver_accepted_controller.dart`

## Entry Points

The flow usually starts from `AuthInterceptor` in `api_service.dart`.

Typical triggers:

- backend returns `401`
- backend returns auth error codes like:
  - `AUTH_NO_TOKEN`
  - `AUTH_INVALID_TOKEN`
  - `AUTH_SESSION_REVOKED`
  - `AUTH_TOKEN_EXPIRED`
- backend returns a session-expired style message
- token refresh fails

## High-Level Flow

```text
API/auth failure
  -> AuthInterceptor detects expired session
  -> SessionExpiryService.handleSessionExpired()
  -> stop background authenticated work
  -> clear local session once
  -> show one session-expired dialog
  -> user taps Login
  -> navigate to Login screen
  -> successful login calls SessionExpiryService.resetOnLogin()
```

## Detailed Runtime Flow

### 1. Expired session is detected

`AuthInterceptor.onError()` checks whether the backend response means the session is no longer valid.

If yes, it calls:

```dart
SessionExpiryService.handleSessionExpired()
```

### 2. Coordinator marks teardown in progress

`SessionExpiryService.handleSessionExpired()` first sets internal flags:

- `_isHandling = true`
- `_userLoggedOut = true`

These flags are exposed via:

```dart
SessionExpiryService.isHandling
```

That flag is used to tell the app:

- do not start new authenticated requests
- do not try token refresh again
- do not reopen the same dialog
- do not navigate back to authenticated routes

### 3. Background authenticated work is stopped

Current scope of forced shutdown:

- Home active-ride polling
- Driver accepted fallback polling
- socket disconnect
- all in-flight REST requests via `ApiService().cancelAllRequests()`

This is coordinated from:

- `_stopAllBackgroundWork()` in `session_expiry_service.dart`

### 4. Local session is cleared once

`clearLocalSessionForReLogin()` is called from `handleSessionExpired()`.

That clears:

- wallet/session UI caches
- Firebase auth session (best effort)
- storage via `StorageService().deleteAll()`
- in-memory auth session via `SessionAuthService.instance.clearInMemorySession()`

Important:

- this flow does **not** call backend `logout()`
- the reason is simple: the backend session is already invalid

### 5. One dialog is shown

After cleanup, the coordinator calls:

```dart
ApiService().showLogoutPopup()
```

That popup is guarded by:

```dart
SessionExpiryService.tryMarkSessionExpiredDialogShown()
```

So if multiple failing requests hit the same path, only the first one can show the dialog.

## Why the dialog does not open twice

There are two layers of protection:

### Guard 1: session is already being handled

`handleSessionExpired()` starts with:

```dart
if (_isHandling) return;
```

So the coordinator only starts once.

### Guard 2: popup already marked shown

`showLogoutPopup()` starts with:

```dart
if (!SessionExpiryService.tryMarkSessionExpiredDialogShown()) return;
```

So even if multiple paths somehow reach the popup method, the second call is ignored.

## What happens when the user taps Login

The Login button inside the dialog does **not** wipe storage again.

That work already happened before the popup was shown.

The button now only:

1. calls `SessionExpiryService.acknowledgeExpiredSessionForReLogin()`
2. closes the dialog
3. navigates to `AppRoutes.login`

This is important because it avoids repeating cleanup and keeps the dialog flow simple.

## Why `acknowledgeExpiredSessionForReLogin()` exists

It keeps the teardown flags active while the app is on the Login screen.

This prevents:

- in-flight old requests from reopening the dialog
- auth-refresh logic from retrying with the dead session
- accidental routing back into logged-in screens before a fresh login succeeds

## When flags are reset

The expired-session flags should only be reset after a real successful login.

That is done by:

```dart
SessionExpiryService.resetOnLogin()
```

This resets:

- `_isHandling`
- `_userLoggedOut`
- `_localSessionCleared`
- `_sessionExpiredDialogShown`
- `AuthInterceptor.isLoggingOutDueToAuthFailure`

## Manual logout vs session expiry

These are intentionally different.

### Manual logout

Used when the user explicitly logs out from profile/settings.

Flow:

1. optional backend logout request
2. stop background work
3. sign out Firebase
4. clear storage
5. navigate to Login

### Session expiry

Used when backend says the session is no longer valid.

Flow:

1. stop background work
2. clear local session
3. show one session-expired dialog
4. user taps Login
5. navigate to Login

No backend logout is needed in this case.

## Splash screen behavior

Splash checks the session-expiry flags before routing to Home.

This prevents a race where:

1. splash starts
2. a background API call expires the session
3. splash still tries to open Home

The guard ensures splash stays quiet while expired-session teardown is active.

## Request blocking behavior

`AuthInterceptor.onRequest()` blocks any new authenticated request when:

```dart
SessionExpiryService.isHandling == true
```

Exception:

- requests with `skip-auth-interceptor == true`

Those are allowed because they are used for flows like:

- login
- OTP
- refresh token
- other pre-login requests

## Current intentional scope

The current session-expiry teardown intentionally stops:

- active-ride background polling
- ride/driver-accepted fallback polling
- sockets
- in-flight REST

It intentionally does **not** force-stop every feature-local timer in the app.

In particular, payment-related top-up polling remains owned by the payment feature itself and is not centrally shut down from `SessionExpiryService`.

## Maintenance Notes

If a new authenticated background process is added later, ask:

1. Can it outlive the screen that created it?
2. Can it keep calling the API after session expiry?
3. Should it be stopped from the central session-expiry flow?

If the answer is yes, add that stop path inside:

- `SessionExpiryService._stopAllBackgroundWork()`

or expose a feature-level `onSessionExpired()` method and call it from there.
