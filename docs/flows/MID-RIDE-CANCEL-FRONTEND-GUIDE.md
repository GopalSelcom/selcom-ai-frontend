# Frontend Integration Guide — Mid-Ride Driver Cancellation & Distance Charge

> Companion to **MID-RIDE-DRIVER-CANCEL-DISTANCE-CHARGE.md** (backend spec).
> Audience: **Delivery Agent app** team and **Selcom Go (rider) app** team.
> Read §1 for the shared concept, then your app's section. Backend is authoritative for
> all money/distance — the apps **display** values and **collect** intent; they never compute charges.

---

## 1. The feature in one paragraph

A driver can end a trip that has already started (vehicle breakdown, accident, unsafe
situation). The rider is **not** charged the full fare — only a **partial fare for the
distance already covered**, and that charge is **taken 30 minutes later**, giving the
rider a window to **dispute** it. Drivers who do this too often get **flagged**. The
driver app must let the driver trigger and confirm this; the rider app must explain the
charge, show the dispute window, and reflect the final settled amount.

---

## 2. Delivery Agent app

### 2.1 New action — "End trip / Report problem" (mid-ride only)
- Show a **"Can't continue this trip?"** action on the active-ride screen **only when** the
  ride is in a moving state (after the rider is picked up). Hide it before pickup (use the
  existing offer-cancel there).
- Tapping opens a **reason sheet** (required):
  - `vehicle_breakdown` — "Vehicle breakdown"
  - `accident` — "Accident"
  - `unsafe` — "Unsafe situation"
  - `other` — "Other" → free-text required
- Show a **consequence warning** before confirm:
  > "Ending trips early is recorded. Repeated early cancellations may lead to review or
  > penalties. The rider will be charged only for the distance already covered."
- Require an explicit **"Confirm — End Trip"** (second tap) to prevent accidents.

### 2.2 API call
```
POST {DA_BASE}/app/go/ride/:rideId/cancel-midride
Authorization: <driver token>
Body: {
  "reason": "vehicle_breakdown",
  "reason_text": "Bike chain snapped",        // required only when reason="other"
  "lat": -6.7924, "lng": 39.2083,             // current GPS
  "distance_covered_km": 3.2                  // best local estimate (cross-check only)
}
```
**Response**
```json
{ "status_code": 200, "data": {
    "ride_id": "...", "status": "cancelled",
    "flagged": false, "mid_ride_cancel_count": 1
} }
```
- If `flagged: true` or `mid_ride_cancel_count` is high, show a stronger warning toast
  ("You've ended several trips early. Your account is under review.").
- Send the **best available GPS** (`lat/lng`) — backend uses it as a fallback distance source.
- After success, the task disappears from the queue via the existing `rider:getTask`
  socket refresh; also handle `go:ride_offer_cancelled` for safety.

### 2.3 What the driver app does NOT do
- Does **not** show or compute the rider's charge (backend-owned).
- Does **not** decide flagging (server returns it).

### 2.4 Driver-side states to handle
- Network failure on the call → allow retry; the trip stays active until a `200`.
- Already-cancelled (race) → treat `409`/terminal response as success and refresh tasks.

---

## 3. Selcom Go (rider) app

### 3.1 New mid-ride status: driver ended the trip
Listen on the existing ride status channel `ride:${rideId}:status`:

**Event `ride:driver_cancelled`**
```json
{ "ride_id":"...", "reason":"vehicle_breakdown",
  "distance_covered_km": 3.2, "partial_fare": 1850,
  "capture_at":"2026-06-30T12:30:00Z",
  "dispute_deadline":"2026-06-30T12:30:00Z", "can_dispute": true }
```
On receipt:
- Move the ride UI to a **"Trip ended by driver"** screen (not the normal completion screen).
- Show empathetic copy + reason (e.g. "Your driver had a vehicle breakdown and couldn't
  finish the trip.").
- Show the **charge summary**: "You'll be charged **TZS 1,850** for the 3.2 km covered."
- Show a **countdown / deadline**: "This will be charged at 12:30. If something's wrong,
  you can dispute it before then." + a **"Dispute charge"** button (enabled while `can_dispute`).
- Money is **still held**, not yet taken — wording must say *"will be charged"*, not *"charged"*.

### 3.2 Dispute action (within 30 min)
```
POST {GO_BASE}/v4/go/rides/:id/dispute-charge
Authorization: <rider token>
Body: { "reason": "Driver cancelled but I was charged unfairly" }   // optional
```
**Response** → `{ status_code:200, data:{ released_amount, status:"disputed" } }`
- On success: show "We've released the hold and our team will review this. You won't be
  charged while we investigate." Hide the countdown.
- Also handle the socket event **`ride:charge_disputed`** `{ ride_id, released_amount }`
  (covers the case where the dispute was filed on another device).
- If the window already closed (`400`/`already captured`), route the user to **Support/Help**
  with the ride pre-filled instead of erroring.

### 3.3 Final settlement
**Event `ride:charge_settled`** `{ ride_id, captured_amount, net_refund }` (fires ~30 min later):
- Update the screen to "Charged **TZS X** for distance covered. **TZS Y** released back to
  your wallet."
- Trigger a wallet-balance refresh.
- Also delivered as a push (`notifyMidRideChargeSettled`) for backgrounded apps.

### 3.4 Receipts / history
- In ride history, render this ride as **"Cancelled by driver — partial charge"** with the
  `distance_covered_km`, `partial_fare`/`captured_amount`, and dispute status.
- Surface the data from the ride-detail response (`mid_ride_cancel` block) so history is
  correct even if the app missed the live socket events.

### 3.5 Rider states to handle
| Backend `mid_ride_cancel.capture_status` | Rider UI |
|---|---|
| `scheduled` (now < capture_at) | "Will be charged TZS X at HH:MM" + Dispute button |
| `scheduled` (now ≥ capture_at) | "Finalising your charge…" (settlement imminent) |
| `captured` | "Charged TZS X · TZS Y refunded" |
| `disputed` | "Under review — not charged" |
| `released`/`waived` | "No charge — fully refunded" |

---

## 4. Shared contract summary

| Direction | Transport | Name | Notes |
|---|---|---|---|
| DA app → DA backend | REST | `POST /app/go/ride/:rideId/cancel-midride` | driver token |
| Rider app → Go backend | REST | `POST /v4/go/rides/:id/dispute-charge` | rider token, window-gated |
| Go backend → Rider app | socket `ride:${id}:status` | `ride:driver_cancelled` | held, not charged |
| Go backend → Rider app | socket | `ride:charge_settled` | after capture |
| Go backend → Rider app | socket | `ride:charge_disputed` | after dispute |
| Go backend → Rider app | push | mid-ride scheduled / settled | background |

> **Time fields are ISO-8601 UTC.** Render countdowns from `capture_at`; never trust device
> clock for the *decision* — the button may be shown a little past the deadline, but the
> backend is the source of truth and will reject a late dispute gracefully (route to Support).

---

## 5. Copy / strings (suggested, localise EN/SW)

- DA confirm: *"End this trip? This is recorded. The rider is charged only for distance covered."*
- Rider banner: *"Your driver couldn't finish the trip ({reason})."*
- Rider charge: *"You'll be charged TZS {partial_fare} for {distance} km. Charged at {time}."*
- Rider dispute success: *"Hold released. Our team will review — you won't be charged while we check."*
- Rider settled: *"Charged TZS {captured}. TZS {refund} returned to your wallet."*

---

## 6. QA checklist

**Driver app**
- [ ] Action hidden before pickup, shown only mid-ride.
- [ ] Reason required; `other` requires text.
- [ ] Two-step confirm; GPS sent.
- [ ] Task removed from queue after success; retry on network error.
- [ ] Flag warning shown when `flagged`/high count.

**Rider app**
- [ ] `ride:driver_cancelled` switches to the dedicated screen with correct amount & deadline.
- [ ] Countdown accurate; Dispute disabled after deadline.
- [ ] Dispute → release confirmation + balance refresh; `ride:charge_disputed` handled.
- [ ] `ride:charge_settled` updates amounts + balance; push handled when backgrounded.
- [ ] History/receipt shows partial charge + dispute status (from `mid_ride_cancel`).
- [ ] App missing live events still reconstructs state from ride-detail on reopen.

**Both**
- [ ] Wording: "will be charged" pre-capture vs "charged" post-capture.
- [ ] Values match backend (apps display only).
