# Route Deviation & Ride Cancellation Requests — Rider App Integration

**Audience:** rider app (Flutter) developer
**Backend status:** shipped and testable on staging. Nothing here needs a backend change to start.

---

## 1. What this is

The backend now watches every in-progress ride against the *optimized route* it
quoted (pickup → stops → destination). If the driver gets more than **500 m**
away from that route (configurable, admin-tunable), the ride is flagged and the
rider is alerted.

Today the rider only gets a push notification and can do nothing about it. Your
job is the screen that follows: **show what happened, and give them a way out.**

Two things to build:

1. **A deviation banner** on the active-ride / tracking screen.
2. **A "Request cancellation" sheet** behind it, plus the pending/decided states.

> **Important:** a rider still **cannot** cancel a started ride themselves.
> `PUT /v4/go/rides/:id/cancel` continues to reject `ride_started` /
> `ride_in_progress` / `near_destination`. The request flow below is the only
> path once the trip is underway — the rider asks, Customer Care decides.
> Do **not** wire the deviation banner to the existing cancel endpoint.

---

## 2. Where the data comes from

Everything is served **pre-rendered** — title, subtitle and distance text are
built server-side (same helper feeds the REST payload and the socket event), so
please render the strings as-is rather than composing your own. That keeps the
copy consistent and lets us change wording without an app release.

### 2.1 REST — on screen load / cold start / reconnect

Both existing endpoints gained one new key. **No new call needed.**

`GET /v4/go/rides/:id` → `data.route_deviation`
`GET /v4/go/rides/active` → `data.rides[].route_deviation`

```jsonc
// null when the ride was never flagged — render nothing.
{
  "flagged": true,
  "state": "off_route",              // "off_route" | "on_route"
  "deviation_meters": 700,
  "distance_text": "700 m",          // pre-formatted ("700 m" / "1.2 km")
  "alert_count": 1,
  "max_deviation_meters": 700,
  "last_event_at": "2026-07-31T09:14:02.111Z",

  "title": "Your driver is off the planned route",
  "subtitle": "Your driver is about 700 m away from your agreed route. If this doesn't look right, contact support.",

  "can_contact_support": true,
  "can_request_cancellation": true,  // false once a request is already pending

  "cancellation_request": null       // or the object below, once raised
}
```

When a request exists:

```jsonc
"cancellation_request": {
  "ticket_id": "66b1f0...",
  "ticket_number": "GO-8F2A114",
  "status": "pending",               // pending | approved | rejected | withdrawn
  "requested_at": "2026-07-31T09:15:40.220Z"
}
```

`flagged` stays `true` for the rest of the trip even after the driver rejoins —
it records that an incident happened. Use **`state`** to decide the banner's
tone (red while `off_route`, muted/green once `on_route`), not `flagged`.

### 2.2 Socket — live, while the screen is open

Room: `ride:<ride_id>:status` **and** `ride:<ride_id>:track` (you already join
both via `join_ride_room`). Event fires on both — de-dupe by `ride_id` +
`detected_at`.

**`ride:route_deviation`**

```jsonc
{
  "ride_id": "…",
  "event": "deviated",               // "deviated" | "rejoined"
  "state": "off_route",              // "off_route" | "on_route"
  "deviation_meters": 700,
  "threshold_meters": 500,
  "distance_text": "700 m",
  "driver_location": { "lat": -6.7934, "lng": 39.2501 },
  "detected_at": "2026-07-31T09:14:02.111Z",

  "title": "Your driver is off the planned route",
  "subtitle": "Your driver is about 700 m away …",
  "can_contact_support": true,
  "can_request_cancellation": true
}
```

Same fields as the REST banner, so you can feed both into one view-model.

**`ride:cancellation_request_update`** — fires when CC **declines** the request:

```jsonc
{ "ride_id": "…", "ticket_id": "…", "ticket_number": "GO-8F2A114",
  "status": "rejected", "note": "Driver confirmed a road closure — trip continues." }
```

**`ride:status_update`** — fires when CC **approves** and cancels the ride.
You already handle this event; just handle the new `cancelled_by` value:

```jsonc
{ "ride_id": "…", "status": "cancelled", "cancelled_by": "support",
  "cancellation_fee": 0, "reason": "…",
  "message": "Your ride was cancelled by support. You have not been charged." }
```

Render `message` verbatim on the cancellation screen — it states the charge
correctly for both the 0 and non-zero case.

### 2.3 Push notifications (app backgrounded)

All are `type: 500` (RIDE_STATUS) with `ride_id`, so they deep-link to the ride
screen through your existing handler. Branch on the `status` data key:

| `data.status` | Title | When |
|---|---|---|
| `route_deviation` | Driver is off your route | Deviation confirmed. Also carries `deviation_meters`. |
| `route_rejoined` | Back on route | Driver returned to the route |
| `cancellation_request_rejected` | Cancellation Request Declined | CC declined |
| `cancelled` + `cancelled_by: "support"` | Ride Cancelled by Support | CC cancelled. Carries `charge_amount`. |

All FCM `data` values arrive as **strings** — `deviation_meters` is `"700"`,
not `700`.

---

## 3. Endpoints to call

### 3.1 Raise a cancellation request

```
POST /v4/go/rides/:id/cancellation-request
Authorization: Bearer <token>

{ "reason": "route_deviation", "description": "Driver has ignored two turns" }
```

`reason` (required) is one of — fetch the labelled list from
`GET /v4/go/support/reasons` → `data.cancellation_reasons`, don't hardcode:

| value | label |
|---|---|
| `route_deviation` | Driver is going off the route |
| `wrong_direction` | Driver is heading the wrong way |
| `driver_unsafe` | I feel unsafe with this driver |
| `other` | Another reason |

Pre-select `route_deviation` when opening the sheet from the deviation banner.
`description` is optional free text.

**Success — `201` (created) or `200` (one already existed):**

```jsonc
{ "status_code": 201, "message": "…",
  "data": { "ticket_id": "…", "ticket_number": "GO-8F2A114",
            "status": "pending", "already_requested": false } }
```

The endpoint is **idempotent** — one pending request per ride. A double-tap or a
retry after a dropped response returns the same ticket with
`already_requested: true` instead of creating a second one. Treat `200` and
`201` identically; surface the ticket number either way.

**Errors:** `404 RIDE_NOT_FOUND` · `409 RIDE_NOT_ACTIVE` (ride already ended —
refresh the screen) · `400 VALID_INVALID_FIELD` (bad `reason`).

### 3.2 Withdraw a pending request

```
POST /v4/go/support/tickets/:ticket_id/withdraw-cancellation
```

`200` on success. `409 ALREADY_DECIDED` if CC got there first — refresh and show
the decided state.

### 3.3 Following the ticket

The request **is** a support ticket, so your existing support screens already
work on it — no new integration:

- `GET /v4/go/support/tickets` — appears in the rider's ticket list
- `GET /v4/go/support/tickets/:id` — full thread; CC replies land here
- `POST /v4/go/support/tickets/:id/replies` — rider can chat with CC

The ticket carries a `cancellation_request` object with the live `status`. When
CC approves, a `system` reply is appended recording the outcome and any charge.

---

## 4. Suggested UX flow

```
Tracking screen, ride in progress
        │
        ├── route_deviation == null ──────────► nothing (normal trip)
        │
        └── state == "off_route"
              ┌──────────────────────────────────────────┐
              │ ⚠  Your driver is off the planned route   │  ← title
              │    Your driver is about 700 m away from   │  ← subtitle
              │    your agreed route…                     │
              │                                           │
              │  [ Contact support ]  [ Request to cancel ]│
              └──────────────────────────────────────────┘
                        │                    │
      opens your existing         opens the reason sheet
      support/chat screen         (3.1) → confirmation:
      with ride_id attached
                                  "Request sent. Support will
                                   review and call you shortly.
                                   Ticket GO-8F2A114"
                                   [ Withdraw request ]
                                            │
              ┌─────────────────────────────┼─────────────────────────────┐
        approved                        rejected                     withdrawn
   ride:status_update              ride:cancellation_          back to the banner
   cancelled_by: "support"         request_update              (can request again)
   → cancellation screen,          → "Support reviewed…
     render `message`                 your ride continues"
```

**States to cover:**

| Condition | Show |
|---|---|
| `route_deviation == null` | nothing |
| `state == "off_route"`, `can_request_cancellation == true` | full banner + both buttons |
| `state == "on_route"`, `flagged == true` | muted "Back on route" banner (dismissible) |
| `cancellation_request.status == "pending"` | "Request sent · GO-XXXX" + Withdraw |
| `cancellation_request.status == "rejected"` | "Support declined — your ride continues" + note |
| `status == "cancelled"`, `cancelled_by == "support"` | cancellation screen with `message` |

---

## 5. Notes & gotchas

- **Drive the banner from REST on load, then patch it from the socket.** The
  socket only fires on a *transition*; a rider who backgrounds and returns needs
  the REST value. Both carry the same fields for exactly this reason.
- **`can_request_cancellation` is the gate for the button**, not `state`. It goes
  `false` while a request is pending so the rider can't stack duplicates.
- **Charges:** today a support cancellation charges the rider **0** and releases
  the full hold. The percentage is admin-configurable, so don't hardcode "free" —
  read `cancellation_fee` / `charge_amount` off the cancellation payload and
  render `message`, which is already correct for both cases.
- **Don't add your own 500 m logic.** The threshold, the confirmation count, the
  cooldown and the alert cap all live in admin settings and can change without an
  app release. The app should react to events only.
- **False positives are possible** (tunnels, bad GPS, a legitimate diversion).
  The copy is deliberately "if this doesn't look right" rather than accusatory —
  please keep that tone and don't escalate it visually beyond a warning banner.

---

## 6. Quick test on staging

1. Book a ride, get it to `ride_started`.
2. Have the driver app (or a GPS mock) move ~700 m off the route for ~20 s
   (two consecutive pings past the threshold).
3. Expect: FCM push + `ride:route_deviation` on the socket, and
   `GET /rides/:id` → `route_deviation.state == "off_route"`.
4. `POST /rides/:id/cancellation-request` → note the ticket number; confirm
   `can_request_cancellation` flips to `false` on the next fetch.
5. Ask CC (admin portal → **Support → Cancellation requests**) to approve it.
6. Expect: `ride:status_update` with `cancelled_by: "support"`, the
   "Ride Cancelled by Support" push, and the ride ending with no charge.

Ping me if any payload doesn't match this doc — that's a backend bug, not
something to work around in the app.
