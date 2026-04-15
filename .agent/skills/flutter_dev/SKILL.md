---
name: flutter_dev
description: Selcom-specific Flutter coding standards and Rule 18/19 implementation.
---

# 🚀 Flutter Development Guidelines

## 0. Shared brain (`.agent/`)

Canonical rules and API docs for this app are **not** only in `.cursor/rules/` — they resolve through **`.agent/`** (symlinks to `selcom-go-ai-agent`). Before large changes, align with:

- `.agent/context/shared/RULES.md`
- `.agent/context/backend/API_CONTRACT.md`
- `.agent/agents/frontend/AGENT.md`

See `.agent/README.md` in the repo root’s `.agent` folder.

## 1. FVM Enforcement (Rule 18)
All Flutter commands must be prefixed with `fvm`.
```bash
fvm flutter run
fvm flutter pub get
```

## 2. API Headers (Rule 19)
All API requests must include the identification headers. Use the `AuthInterceptor` in `api_service.dart` and the `commonHeaders()` builder in `headers.dart`.

**Header Specifications:**
- `app_uuid`: Persistent unique application ID.
- `device_type`: 1 (Android) or 2 (iOS).
- `authorization`: JWT Bearer token.
- `access_token`: Access token.
- `encryption_disabled`: "true".
- `device_token`: FCM token.
- `app_version`: Package version.
- `language`: "en".

## 3. Architecture (Clean Architecture + GetX)
- **Features:** Modularized by domain (auth, home, ride, booking).
- **Core:** Core services (FCM, Storage, API clients).
- **Shared:** Common widgets, theme, constants.

## 4. UI Standards
- **Font:** Poppins (AppTextStyles).
- **Primary Color:** 0xFFF01C4B (AppColors.primary).
- **Border Radius:** 12pt (AppRadius.card).

## 5. Network Architecture (MANDATORY)

All API classes MUST follow the `network/` folder pattern. **Never** use raw `Dio` directly.

### File Structure
```
lib/core/network/
├── api_service.dart              # ApiService singleton, ApiRequest model, AuthInterceptor
├── api_constants.dart            # Params keys, ResultCode status codes
├── headers.dart                  # commonHeaders() builder function
├── urls.dart                     # URLS endpoint registry (grouped subclasses)
├── failed_request_queue.dart     # Request queue with MD5 deduplication
├── retry_manager.dart            # Auto-retry with batch processing + connectivity
└── network_connectivity_service.dart  # DNS-based connectivity monitor
```

### ApiService Singleton
- **Always** use `ApiService().call(request: ApiRequest(...))` for API calls.
- **Never** instantiate `Dio` directly in repositories or controllers.
- The singleton is initialized once in `injection_container.dart` via `ApiService().init(...)`.

### ApiRequest Model
Every API call uses the `ApiRequest` model:
```dart
final response = await ApiService().call(
  request: ApiRequest(
    endpoint: URLS.auth.sendOtp,         // Use URLS registry
    method: ApiMethod.post,              // get, post, put, delete, patch, multipart
    version: "v4",                       // API version prefix
    body: {'mobile_number': phone},      // Request body
    queryParams: {'page': '1'},          // Query parameters
    headers: {'custom-header': 'value'}, // Extra headers (merged with common)
    skipAuthInterceptor: false,          // Skip 401 handling
    shouldQueue: true,                   // Queue on network failure
    errorPresentationType: ErrorPresentationType.dialog, // none, dialog, snackbar
  ),
);
```

### URLS Endpoint Registry
- All endpoints go in `urls.dart` using grouped subclasses.
- Access: `URLS.auth.sendOtp`, `URLS.ride.estimateFare`, `URLS.home.homeScreen`.
- **Never** hardcode endpoint strings in repositories or controllers.

### Adding New Endpoints
1. Create a private `_XxxEndpoints` class with `const` constructor.
2. Add endpoint `final` fields.
3. Register in `URLS` abstract class as `static const xxx = _XxxEndpoints();`.

### Token Management
- Tokens are stored in `FlutterSecureStorage` with keys: `authorization_token`, `access_token`, `refresh_token`.
- `AuthInterceptor` handles automatic 401 → refresh → retry flow.
- **Never** store tokens in `SharedPreferences`.

### Error Handling
- `ApiService` returns `Response` objects — check `statusCode` in repositories.
- Network errors are auto-queued and retried via `RetryManager`.
- `ErrorPresentationType` controls whether errors show UI (dialog/snackbar/none).
