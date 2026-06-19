# Selcom Go — Android build guide

Step-by-step checklist to build a **release APK** (or App Bundle).  
Use this before every build so nothing is missed.

---

## 1. Machine setup (one-time)

| Verify | Item |
|--------|------|
| ☐ | **Flutter 3.41.9** — this repo uses FVM (see `.fvmrc`). Install: `fvm install` then use `fvm flutter` for all commands below. |
| ☐ | **Android SDK** installed (Android Studio → SDK Manager). |
| ☐ | **JDK 17** — required by `android/app/build.gradle.kts`. |
| ☐ | `fvm flutter doctor` shows no blocking errors for Android toolchain. |

---

## 2. Get the project

| Verify | Item |
|--------|------|
| ☐ | Repo cloned and on the correct branch. |
| ☐ | `fvm flutter pub get` completes without errors. |

---

## 3. Environment file (`.env`)

`.env` lives at the **project root** (next to `pubspec.yaml`).  
It is **not on GitHub** — get values from your team lead if you don’t have the file.

### 3.1 Required keys

| Verify | Key | Purpose |
|--------|-----|---------|
| ☐ | `API_HOST_STAGING` | Staging REST API host (no `/api` suffix) |
| ☐ | `API_HOST_PRODUCTION` | Production REST API host |
| ☐ | `API_HOST_DEV` | Optional dev override (empty = use staging) |
| ☐ | `SOCKET_BASE_URL_STAGING` | Staging socket host |
| ☐ | `SOCKET_BASE_URL_PRODUCTION` | Production socket host |
| ☐ | `SOCKET_BASE_URL_DEV` | Optional dev override (empty = use staging) |
| ☐ | `ERROR_REPORT_HOST_STAGING` | Staging error-report host |
| ☐ | `ERROR_REPORT_HOST_PRODUCTION` | Production error-report host |
| ☐ | `AGORA_APP_ID` | Agora voice calling |
| ☐ | `AGORA_TOKEN_MODE` | `none` \| `ride_api` \| `api` |
| ☐ | `AGORA_TOKEN_ENDPOINT` | Only if token mode is `api` |
| ☐ | `SELCOM_PESA_DEEPLINK_HOST` | Selcom Pesa deep link (default: `spd.selcommobile.com`) |

### 3.2 Generate Dart config from `.env`

After creating or editing `.env`, **always** run:

```bash
dart run build_runner build
```

| Verify | Item |
|--------|------|
| ☐ | Command finishes with no errors |
| ☐ | `lib/core/env/env.g.dart` exists and is up to date |

### 3.3 When you change URLs (or any `.env` value)

Old values live in **`lib/core/env/env.g.dart`**. Editing `.env` alone does **not** update the app until you regenerate.

**Do this every time you change `.env`:**

| Step | Command | Why |
|------|---------|-----|
| 1 | Edit `.env` at project root | Source of truth |
| 2 | `dart run build_runner clean` | Clears old generated / cached config |
| 3 | `dart run build_runner build` | Creates a **new** `env.g.dart` from `.env` |
| 4 | `fvm flutter clean` (optional) | Clears old APK build cache if URLs still look wrong |
| 5 | `fvm flutter run` or `fvm flutter build apk ...` | Rebuild app so new URLs are inside the binary |

**Clean + regenerate (copy-paste):**

```bash
dart run build_runner clean
dart run build_runner build
```

**Do not:**
- Edit `lib/core/env/env.g.dart` by hand (it is auto-generated; changes will be overwritten)
- Commit `.env` to git (secrets stay local; only `env.g.dart` is built from it)

**Quick check that new URLs are applied:**
- Open `lib/core/env/env.g.dart` — file timestamp should be **after** your `.env` edit
- Run the app and confirm API/socket hit the new host (logs / network tab)

---

## 4. Choose runtime target (staging vs production)

Default when you run the app: **`dev`** → uses **staging** URLs from `.env`.

For a **production** release build, pass:

```bash
--dart-define=ENV=prod
```

| Build type | `ENV` value | API / socket used |
|------------|-------------|-------------------|
| Local / QA APK (staging) | `dev` or `staging` (default) | Staging hosts in `.env` |
| Store / live APK | `prod` | Production hosts in `.env` |

---

## 5. Android signing (release APK)

Release builds need a keystore. Files are **not** in git.

| Verify | File / setting | Location |
|--------|----------------|----------|
| ☐ | `key.properties` exists | `android/app/key.properties` |
| ☐ | Keystore file (`.jks` / `.keystore`) path in `key.properties` is correct and file exists |
| ☐ | `keyAlias`, `keyPassword`, `storePassword` are set in `key.properties` |

Example `android/app/key.properties` (get real values from team):

```properties
storePassword=***
keyPassword=***
keyAlias=***
storeFile=../path/to/your-release.keystore
```

| Verify | Item |
|--------|------|
| ☐ | `applicationId` is `com.selcom.go` (`android/app/build.gradle.kts`) |
| ☐ | `pubspec.yaml` `version:` bumped if shipping a new release (`1.0.0+19` → increment build number) |

---

## 6. Firebase & native keys

| Verify | Item | Location |
|--------|------|----------|
| ☐ | `google-services.json` present for `com.selcom.go` | `android/app/google-services.json` |
| ☐ | Google Maps API key valid for release package | `android/app/src/main/AndroidManifest.xml` |
| ☐ | Facebook app id / client token (if using FB login) | `android/app/src/main/res/values/string.xml` |

---

## 7. Pre-build checks

Run these before building:

```bash
fvm flutter pub get
dart run build_runner build
fvm flutter analyze
```

| Verify | Item |
|--------|------|
| ☐ | No analyzer errors on changed code |
| ☐ | App runs on a device in debug (`fvm flutter run`) |
| ☐ | Login, map, and one ride flow work against the intended backend |

---

## 8. Build commands

### 8.1 Debug APK (quick test, no store)

```bash
fvm flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### 8.2 Release APK — staging / QA

```bash
fvm flutter build apk --release
```

Uses default `ENV=dev` (staging URLs).

Output: `build/app/outputs/flutter-apk/app-release.apk`

### 8.3 Release APK — production

```bash
fvm flutter build apk --release --dart-define=ENV=prod
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### 8.4 App Bundle (Google Play)

```bash
fvm flutter build appbundle --release --dart-define=ENV=prod
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## 9. After build — verify APK

| Verify | Check |
|--------|--------|
| ☐ | Install APK on a real device: `adb install build/app/outputs/flutter-apk/app-release.apk` |
| ☐ | App opens without crash |
| ☐ | API calls hit the **correct** environment (staging vs prod) |
| ☐ | Socket connects (active ride / nearby drivers) |
| ☐ | Push notifications work (Firebase) |
| ☐ | Maps load |
| ☐ | Agora call connects (if testing voice) |
| ☐ | Version shown in app matches `pubspec.yaml` |

---

## 10. Common failures

| Problem | What to check |
|---------|----------------|
| Build fails on keystore | `android/app/key.properties` and `storeFile` path |
| Wrong API / staging data on prod build | Missing `--dart-define=ENV=prod` on release command |
| Env values not applied | Re-run `dart run build_runner build` after `.env` edit |
| Missing `.env` | Create from team template; file must be at project root |
| `google-services.json` error | Package name must be `com.selcom.go` |
| Maps blank | Maps API key + SHA-1 registered in Google Cloud Console |

---

## Quick reference (copy-paste)

**Staging release APK:**

```bash
fvm flutter pub get
dart run build_runner build
fvm flutter build apk --release
```

**Production release APK:**

```bash
fvm flutter pub get
dart run build_runner build
fvm flutter build apk --release --dart-define=ENV=prod
```

**Production Play Store bundle:**

```bash
fvm flutter pub get
dart run build_runner build
fvm flutter build appbundle --release --dart-define=ENV=prod
```
