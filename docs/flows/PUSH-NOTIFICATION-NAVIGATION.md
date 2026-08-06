# Push notification navigation (by `type`)

Rider-app behaviour when the user **taps** an FCM / local notification.

| Source of truth | Path |
|---|---|
| Router | `lib/shared/utils/push_notification_navigation.dart` |
| Queue / flush / tray | `lib/core/services/notification_service.dart` |
| Splash flush | `lib/features/auth/presentation/controllers/splash_controller.dart` |
| Ongoing vs details | `lib/shared/utils/ride_active_navigation.dart` (`rideStatusIsOngoingActive`) |
| Pickup-phase chat | `lib/shared/utils/ride_status_normalizer.dart` (`isDriverPickupEnRouteStatus`) |

---

## 1. Payload contract

Backend sends `data` fields (and usually a visible `notification` block for the tray).

| Field | Required | Notes |
|---|---|---|
| `type` | Yes (preferred) | Numeric `500`–`504`, or string alias (`RIDE_STATUS`, `CHAT`, …) |
| `ride_id` | Per type | Also accepts `rideId` / `order_id` |
| `url` | Type 504 | Also accepts `link` / `deep_link` |
| `title` / `body` | For tray | Used when showing local banners for data-only pushes |
| `click_action` | Android | `FLUTTER_NOTIFICATION_CLICK` (intent-filter in `AndroidManifest.xml`) |
| `status` | Optional | Ride status string; routing always re-fetches live details |

### Type codes

| `type` | Alias | Name |
|---|---|---|
| `500` | `RIDE_STATUS` | Ride status update |
| `501` | `CHAT` | In-ride chat message |
| `502` | `REVIEW` | Rate / review ride |
| `503` | `PAYMENT` | Payment / wallet |
| `504` | `MARKETING` | Marketing / deep link |

Non-routing type (not part of 500–504):

| `type` | Behaviour |
|---|---|
| `LIVE_TRACKING` | Backend GPS/ETA updates for the sticky Android order-tracking notification. **No** push-nav; **no** extra local tray from `showFromBackgroundMessage`. Refresh is handled in the FCM background handler via `AndroidOrderTrackingManager`. |

> Backend only sends `LIVE_TRACKING` (not a separate `TRACKING` type).

---

## 2. App lifecycle scenarios (all types)

These apply **before** type-specific routing.

| App state when user taps | What happens |
|---|---|
| **Cold start** (killed) → splash | FCM tray tap → `getInitialMessage` queued; after Home, splash flushes. Android ignores stale **local** launch-details when there is no FCM initial (prevents icon-open re-nav). |
| **Cold start** → onboarding / phone / OTP | Pending nav is **cleared** (user must finish auth) |
| **Background** (process alive) | `onMessageOpenedApp` → navigate if route is ready |
| **Foreground** | System may not show tray; in-app handling is separate from this tap router |
| Tap while splash / auth routes | Queued until past blocked routes (`/`, onboarding, login, phone, OTP, profile loading) |
| Duplicate FCM + local tap (same key) within ~2s after **successful** open | Second tap ignored |
| Second tap while first open still in flight | Coalesced; latest payload runs after first finishes |
| `GET go/rides/:id` fails / missing | Fallback → **Home** |

**Why queue on splash:** navigating during splash is wiped by `Get.offAllNamed(home)` (~2.5s later) and looks like the app “opened then closed”.

---

## 3. Shared ride destination rules

Used by **500**, **501** (after pickup), **502**, and **503** (when `ride_id` resolves).

Flow after `GET go/rides/:id`:

```
mid-ride driver cancel block?
  → mid-ride cancel dialog
else rideStatusIsOngoingActive(status)?
  → live tracking (finding driver / driver accepted)  [= My Rides card]
else
  → Ride Details screen  [= My Rides card]
```

### Ongoing vs terminal

| Status (examples) | `rideStatusIsOngoingActive` | Destination |
|---|---|---|
| `searching`, `driver_assigned`, `driver_arriving`, `driver_arrived`, `ride_started`, `ride_in_progress`, `near_destination` | **true** | Ongoing / live ride UI |
| `ride_completed`, `cancelled`, `no_driver_found` | **false** | Ride details |

---

## 4. Type matrix

### 500 — `RIDE_STATUS`

**Keys:** `ride_id` required.

| Scenario | Destination |
|---|---|
| Missing `ride_id` | Home |
| Fetch fails | Home |
| Mid-ride cancel block present | Mid-ride cancel dialog |
| Ongoing status (e.g. driver arrived / trip started) | **Ongoing ride** (live tracking) |
| Terminal status (completed / cancelled / no driver) | **Ride details** |

Example payload:

```json
{
  "type": "500",
  "ride_id": "6a7325f596d78b0007806412",
  "status": "driver_arrived",
  "title": "Driver arrived at pickup",
  "body": "Your driver has arrived!",
  "click_action": "FLUTTER_NOTIFICATION_CLICK"
}
```

---

### 501 — `CHAT`

**Keys:** `ride_id` required.

In-app chat button exists only on the **pickup-phase** sheet (before `ride_started`). After the trip starts, chat is hidden in UI — push must not open chat in that case.

| Scenario | Destination |
|---|---|
| Missing `ride_id` | Home |
| Fetch fails | Home |
| Pickup phase: `driver_assigned` / `driver_arriving` / `driver_arrived` (and aliases) | **Chat screen** (`/ride-message`) |
| `ride_started` or any later **ongoing** status | **Ongoing ride** |
| Terminal status | **Ride details** |
| Mid-ride cancel (post-pickup path) | Mid-ride cancel dialog |

| Phase | Status examples | Opens |
|---|---|---|
| Pickup (chat UI shown) | assigned / arriving / arrived | Chat |
| In trip | `ride_started`, `ride_in_progress`, `near_destination` | Ongoing ride |
| Done | completed / cancelled | Ride details |

---

### 502 — `REVIEW`

**Keys:** `ride_id` required.

Does **not** open the rating bottom sheet. Rating lives on **Ride details**.

| Scenario | Destination |
|---|---|
| Missing `ride_id` | Home |
| Fetch fails | Home |
| Ongoing (unexpected for review push) | Ongoing ride |
| Completed / cancelled / etc. | **Ride details** (review section on that screen) |

---

### 503 — `PAYMENT`

**Keys:** `ride_id` optional.

Same ongoing-vs-details rules as **500** when a ride exists (e.g. “Funds Reserved” during an active trip → **ongoing ride**).

| Scenario | Destination |
|---|---|
| No `ride_id` (null / empty) | **Wallet** |
| With `ride_id`, fetch fails / ride unavailable | **Wallet** |
| With `ride_id`, mid-ride cancel block | Mid-ride cancel dialog |
| With `ride_id`, ongoing status | **Ongoing ride** (live tracking) |
| With `ride_id`, terminal status | **Ride details** |

---

### 504 — `MARKETING`

**Keys:** `url` / `link` / `deep_link` optional.

| Scenario | Destination |
|---|---|
| Empty / missing URL | Home |
| In-app path starting with `/` (e.g. `/wallet`) | `Get.toNamed(url)` |
| `http` / `https` URL | External browser (`launchUrl`) |
| Launch fails / unsupported scheme | Home |

---

### Other / unknown / legacy

| Scenario | Destination |
|---|---|
| Unknown `type` (not 500–504) | Home |
| No `type` key, but `ride_id` present | Treated as **500** (legacy) |
| `type: LIVE_TRACKING` | **No navigation** |
| Empty / nonsense payload | Home |

---

## 5. Decision flowchart (tap)

```
User taps notification
        │
        ▼
On splash / auth route?
  yes → queue (or clear if landing onboarding/phone)
  no  → PushNotificationNavigation.handle
        │
        ▼
type == LIVE_TRACKING? → stop
        │
        ▼
Recent successful same key (<2s)? → stop
In-flight handle? → coalesce latest
        │
        ▼
     switch(type)
        │
   ┌────┼────┬────┬────┬────┐
  500  501  502  503  504  other
   │    │    │    │    │     │
   │    │    │    │    │     └─► Home
   │    │    │    │    └─► URL / home
   │    │    │    └─► wallet (no ride) or ongoing/details
   │    │    └─► ongoing or ride details (no rating sheet)
   │    └─► pickup? chat : ongoing/details
   └─► ongoing or ride details
```

---

## 6. Platform notes

### Android

- Intent-filter for `FLUTTER_NOTIFICATION_CLICK` required for system notification taps.
- Data-only pushes (no `notification` block): background isolate may show a local notification via `NotificationService.showFromBackgroundMessage` (skipped for `LIVE_TRACKING`).
- Sticky order-tracking (`order_tracking_channel`) is updated from `LIVE_TRACKING` (and other ride-status data with `ride_id` + `status`) via `AndroidOrderTrackingManager` — separate from type 500–504 routing.

### iOS

- Same Dart router.
- Reliable tray + tap needs a proper `notification` / `aps.alert` payload from FCM/APNs.
- `click_action` is Android-specific.

---

## 7. Logging (debug)

Filter logcat / console for:

| Tag | Meaning |
|---|---|
| `PushNav` | Type resolution and destination decisions |
| `Notification` / `OPENED_APP` | FCM opened-from-tray |
| `Push nav queued until past splash/auth` | Tap deferred |
| `CHAT pickup phase … → chat screen` | 501 → chat |
| `CHAT after pickup phase … → ongoing/details` | 501 → live / details |
| `REVIEW … → ride details` | 502 → details |
| `Push nav ignored (recent success)` | Dedupe after success |
| `Push nav coalesced (in-flight)` | Tap waiting on previous open |

---

## 8. Quick QA checklist

- [ ] **500** + `driver_arrived` → ongoing (driver accepted)
- [ ] **500** + completed ride → ride details
- [ ] **501** + arrived (pickup) → chat
- [ ] **501** + `ride_started` → ongoing (not chat)
- [ ] **501** + completed → ride details
- [ ] **502** → ride details (no rating bottom sheet)
- [ ] **503** without `ride_id` → wallet
- [ ] **503** with `ride_id` → ride details
- [ ] **504** with `https://…` → browser
- [ ] **504** with `/wallet` → wallet route
- [ ] Unknown type → home
- [ ] Cold start + 500 → lands on destination after home (not wiped by splash)
- [ ] `LIVE_TRACKING` tap does not open ride status router
