# Ride Chaining — Frontend / App Changes

> Companion to [GO-RIDE-CHAINING-FINISHING-DRIVER.md](./GO-RIDE-CHAINING-FINISHING-DRIVER.md) (the
> backend plan). This doc lists **only what the two apps must change**.
>
> - **Driver app** = the **Delivery Agent** app (talks to `delivery_agent_backend`).
> - **Rider app** = the **Selcom Go** rider app (talks to `selcom_go_backend`).
>
> Everything here is gated by the backend flag `GO_CHAIN_RIDES`. While it is `false`, the backend
> never sends the new fields/events, so **older app builds keep working unchanged**. Apps should treat
> every new field as optional and every new event as additive.

---

## 0. The feature in one line
When no free driver is nearby, a driver who is **finishing their current trip within 3 minutes near the
new rider's pickup** is offered the new ride as a **"Next ride"** while they are still driving. They
accept it before they are free, and roll straight into it the moment they drop off.

Two ideas the apps must newly support:
1. **Driver app:** a driver can hold **two rides** — one active, one "queued/next".
2. **Rider app:** a ride can go **back to searching** after it was already "driver assigned" (if the
   chain is broken). Status is no longer strictly forward-only.

---

## PART A — Driver app (Delivery Agent)

### A1. New socket event fields on `go:ride_offer`
The existing offer event gains two fields when the offer is a chained/queued one:

```jsonc
// socket event: "go:ride_offer"
{
  "ride_id": "…",
  "task_id": "…",
  "pickup":  { "lat": 0, "lng": 0, "address": "…" },
  "destination": { "lat": 0, "lng": 0, "address": "…" },
  "distance_km": 3.2,
  "vehicle_type": "Bike",
  "rider_name": "…",
  "offer_expires_at": "2026-07-13T10:00:30.000Z",

  "queued": true,                 // NEW — this is a "next ride", driver is still on a trip
  "active_ride_id": "…"           // NEW — the ride they are currently finishing
}
```

- **`queued` absent / false** → today's behaviour (normal offer to a free driver). No change.
- **`queued: true`** → render as a **"Next ride"** card *on top of* the active-ride screen, not as a
  replacement.

### A2. Also arrives via `rider:getTask`
When the offer is sent, the ride's task is added to the agent's `current_task[]`, so `rider:getTask`
now returns **two tasks** (the active one + the queued one). The app already renders `current_task`
as a list; it must:
- Not assume "only one Go ride at a time".
- Flag the newest task as **queued/next** (match it by the `ride_id`/`task_id` from `go:ride_offer`,
  or by the `queued` marker DA sets on it).

### A3. UI: the "Next ride" card
While on an active ride, if a `queued` offer arrives:
- Show a compact card/banner: **"Next ride available near your drop-off"** with pickup, distance,
  fare, rider name, and a **countdown** (from `offer_expires_at`).
- Two actions: **Accept** and **Decline** (or let the countdown auto-decline).
- Accepting/declining **must not** interrupt the active ride's navigation or status.

### A4. Accept / Decline
- **Accept:** call the same accept path the app already uses to accept a ride (the backend treats it
  the same — the ride becomes "assigned" to this driver). After accept, show the queued ride as
  **"Upcoming"** somewhere non-intrusive.
- **Decline / timeout:** the card disappears; nothing else changes; the driver keeps their active ride.

### A5. On active-ride completion → promote the next ride
When the driver completes the current ride and they have an accepted **next ride**:
- The backend flips the next ride to **active** (`active_ride` promoted, driver is **not** returned to
  the free pool).
- The app should **auto-surface** the next ride and start navigation to its pickup.
  - Whether it auto-starts or waits for a driver tap is an **open product decision** (see backend §8 Q2).
    Build it to support both; default to auto-surface with a clear "Start" affordance.

### A6. Withdrawal — handle `cancel_offer` and `rider:getTask` shrink
A queued ride can be **withdrawn** before or after accept (rider cancels, the finishing ride changed
its destination out of range, or the offer timed out). The app must:
- On the existing `cancel_offer` / task-removal signal, **remove the "Next ride" / "Upcoming" card**.
- If `rider:getTask` comes back with the queued task gone, drop it from the list.
- Optional toast: **"The queued ride was withdrawn."** Never let a stale next-ride card linger.

### A7. Guardrails
- Only **one** queued ride at a time. If a second `queued` offer somehow arrives, ignore it while one
  is already held.
- The queued card must never block, pause, or overlay the **active** ride's critical controls
  (navigation, arrived, start, complete, SOS).

---

## PART B — Rider app (Selcom Go)

### B1. The important new behaviour: status can go **backwards**
Today the rider status moves forward only (`searching → driver_assigned → … → completed`). With
chaining, a ride that was **`driver_assigned`** (via a chained driver) can revert to **`searching`** if
the chain is broken (the finishing driver's trip changed destination/added a stop and no longer fits —
backend §5.1). The app must:
- Accept a `ride:status_update` that moves **`driver_assigned` → `searching`** without crashing or
  getting stuck on the driver card.
- On that transition, return to the **"Finding your driver"** UI and show a friendly message:
  **"We're finding you another driver."**

### B2. Optional: "driver finishing a nearby trip" status
While the rider is reserved/assigned to a finishing driver, the driver is **still completing another
trip**, so the first ETA to pickup may be larger and the driver may initially move *away* (toward their
current drop-off) before heading to the rider. Two options — **confirm with product** (backend §8 Q3):
- **Minimal (no app change):** rider just sees normal "Driver assigned" + live ETA. Works today.
- **Nicer (small app change):** if the backend emits a status/among `ride:status_update` such as
  `"driver_finishing_nearby"` (or a boolean flag on the assigned payload), show copy like
  **"Your driver is finishing a nearby trip and will reach you in ~N min."**

> Decide with backend whether this extra signal is emitted. If yes, handle the new status/flag; if no,
> **no rider-app change is required for the assigned state** — only B1 (status regression) is mandatory.

### B3. ETA / map expectations
- Do not assume the driver heads straight to the rider immediately after assignment. The driver may
  first finish their current drop-off. The existing `ride:tracking_update` ETA already reflects the
  driver's real position — just make sure the map/ETA UI does not "snap" or show an error if the driver
  moves away briefly before turning toward the pickup.

### B4. What does NOT change for the rider app
- Booking, payment/pre-auth, fare confirmation, cancellation, rating — **all unchanged**. Chaining only
  changes *which* driver is assigned and adds the possible `driver_assigned → searching` regression.

---

## PART C — Contract quick-reference

| Event / field | Direction | New? | App action |
|---|---|---|---|
| `go:ride_offer` → `queued: true` | DA → driver app | **new field** | Render "Next ride" card over active ride |
| `go:ride_offer` → `active_ride_id` | DA → driver app | **new field** | Know which ride is being finished |
| `rider:getTask` returns 2 tasks | DA → driver app | behaviour | Support 2 Go rides; flag the queued one |
| `cancel_offer` / task removed | DA → driver app | existing | Remove queued/upcoming card |
| active-ride completion → next ride active | DA → driver app | behaviour | Auto-surface next ride, navigate to pickup |
| `ride:status_update` `driver_assigned → searching` | Go backend → rider app | **new transition** | Return to "finding driver"; message rider |
| `driver_finishing_nearby` status/flag (optional) | Go backend → rider app | **optional** | Show "driver finishing nearby" copy |

---

## PART D — Test hooks for the frontend teams
- Backend flag `GO_CHAIN_RIDES=true` in the test environment turns the new fields/events on.
- Tunables to reproduce edge cases quickly: `GO_CHAIN_ETA_THRESHOLD_SEC` (3-min gate),
  `GO_CHAIN_RADIUS_KM` (drop-off proximity), `GO_CHAIN_FREE_DRIVER_RADIUS_KM` (3-km free-driver gate),
  `GO_CHAIN_RESERVE_WINDOW_MS`.
- See [GO-RIDE-CHAINING-MANUAL-TESTING.md](./GO-RIDE-CHAINING-MANUAL-TESTING.md) for step-by-step
  scenarios both apps should be validated against.

---

## Summary of mandatory vs optional app work

| App | Mandatory | Optional |
|---|---|---|
| **Driver (Delivery Agent)** | A1–A7: render/accept/decline a queued "Next ride", support 2 rides, promote on completion, handle withdrawal | — |
| **Rider (Selcom Go)** | B1: handle `driver_assigned → searching` regression | B2: "driver finishing nearby" copy |
