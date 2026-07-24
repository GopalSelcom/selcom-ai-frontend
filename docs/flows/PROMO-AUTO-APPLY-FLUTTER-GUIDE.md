# Auto-Apply Promo Codes — Flutter App Guide

**Audience:** Selcom GO rider-app (Flutter) developer
**Status:** Backend + Admin Portal shipped. App changes required.
**Owner:** Backend team (yash@selcom.net)

---

## 1. What changed & why

Until now a rider could only get a discount by **typing a promo code** on the fare
screen. We've added **Auto-Apply promos**: campaigns an admin marks as `is_auto_apply`
that the **backend applies automatically** to an eligible fare — the rider gets the
discount **without entering anything**.

Nothing about the *manual code* flow changes. Auto-apply is a **fallback that only
kicks in when the rider has NOT typed a code.**

### Rules the backend enforces (you don't have to)
- A **typed code always wins.** If the rider enters a code, auto-apply is ignored.
- If **several** auto-apply promos qualify, the backend picks the **one with the
  biggest discount** — per vehicle type.
- All the usual guards still apply (validity window, `min_ride_amount`, applicable
  vehicle types, total `usage_limit`, `per_user_limit`). An auto promo can never
  break a rule a typed code would hit.
- Auto-apply is computed **per vehicle type** on the estimate — different vehicles
  can show different auto promos (or none).

> **You do not implement any selection logic.** The server decides. Your job is to
> **display** what the server returns and let the rider **opt out**.

---

## 2. The one field you own: `disable_auto_promo`

The rider must be able to **remove** an auto-applied discount (e.g. they want to
save the promo, or a code didn't apply). To support that, send a boolean:

| Field | Type | Where | Meaning |
|---|---|---|---|
| `disable_auto_promo` | `bool` (optional, default `false`) | estimate + book request bodies | `true` = do NOT auto-apply any promo |

- Default/omit → auto-apply is **on**.
- Send `true` only when the rider explicitly taps **"Remove"** on the auto discount.
- **Precedence:** if you also send a non-empty `promo_code`, the code wins and
  `disable_auto_promo` is ignored.

---

## 3. Endpoint changes

### 3.1 `POST /v4/go/rides/estimate_fare`  (and it's cached variant)

**Request** — add the optional opt-out (everything else unchanged):
```jsonc
{
  "pickup": { "lat": -6.79, "lng": 39.20 },
  "destination": { "lat": -6.81, "lng": 39.28 },
  "vehicle_type_id": "665f...",        // optional
  "promo_code": "WEEKEND20",           // optional — if present, wins over auto
  "disable_auto_promo": false          // NEW — optional, default false
}
```

**Response** — each object in `data.estimates[]` may now carry promo fields.
These fields already existed for the manual-code path; **two are new**:
`promo_code` (per-estimate) and `promo_auto_applied`.

```jsonc
{
  "status_code": 200,
  "data": {
    "estimates": [
      {
        "vehicle_type_id": "665f...",
        "vehicle_name": "Boda",
        "display_name": "Bike",
        "fare_estimate": 5000,           // ORIGINAL fare (pre-discount)

        // ── promo block (present when a promo applies to this vehicle) ──
        "promo_applied": true,
        "promo_code": "FIRST10",         // NEW — the code that applied here
        "promo_discount": 500,
        "discounted_fare": 4500,         // what the rider pays
        "promo_auto_applied": true,      // NEW — true = auto, false = typed code
        "promo_description": "10% off your ride",
        "promo_error": null
      }
    ]
  }
}
```

Field reference:

| Field | When present | Use it for |
|---|---|---|
| `promo_applied` | always when a promo is evaluated | show/hide the discount row |
| `promo_code` | when `promo_applied == true` | the code label to show |
| `promo_discount` | when applied | the "− TZS 500" line |
| `discounted_fare` | when applied | **the price you show as payable** |
| `promo_auto_applied` | when applied | `true` → show "Auto-applied" chip + a Remove action; `false` → it's the rider's typed code |
| `promo_description` | when applied | optional subtitle |
| `promo_error` | manual code only, when it fails | the reason the typed code was rejected (e.g. `VALID_PROMO_EXPIRED`) |

> **Important nuances**
> - `fare_estimate` is always the **original** fare. When a promo applies, show
>   `discounted_fare` as the price (strike-through `fare_estimate` if you like).
> - When **no** promo applies to a vehicle, the estimate has **none** of the promo
>   fields — treat missing as "no discount". Guard every read with null-safety.
> - For the **manual** path, the payload also has a top-level `data.promo_code`
>   (the echoed typed code) — unchanged, keep using it if you already do.

### 3.2 `POST /v4/go/rides/book`

**Request** — same opt-out field. **Do not** send the discounted fare; the server
recomputes the fare and applies the promo itself.
```jsonc
{
  "vehicle_type_id": "665f...",
  "payment_method": "wallet",
  "promo_code": "WEEKEND20",      // optional — wins over auto
  "disable_auto_promo": false,    // NEW — optional
  "idempotency_key": "…",
  "pickup": { … }, "destination": { … }
}
```

Behaviour:
- `promo_code` present → server validates & applies it (existing behaviour; returns
  `400` with an `error_code` if invalid — unchanged).
- `promo_code` absent **and** `disable_auto_promo != true` → server auto-applies the
  best eligible promo. This is **best-effort**: if it can't (e.g. limit just ran
  out), the ride is **still booked at full fare** — no error is thrown.
- `disable_auto_promo == true` and no code → no discount.

The created ride / receipt reflects the applied promo in `fare_breakdown`:
```jsonc
"fare_breakdown": {
  "ride_charge": 4500,
  "booking_fee": 500,
  "promo_code": "FIRST10",
  "promo_discount": 500,
  "promo_auto_applied": true,     // NEW
  "total_amount": 4500
}
```

### 3.3 `GET /v4/go/promo/available`

Each promo now includes `"is_auto_apply": true|false`. Use it if you want to badge
auto promos differently in any promo list you render. (Auto promos are applied for
the rider anyway, so you generally don't need to surface them here — but the flag is
available.)

---

## 4. ⚠️ Payment block amount — read this

The pre-auth flow is unchanged, but note the interaction:

- `POST /v4/go/validate_ride_payment` blocks (pre-authorises) the amount in
  `fare_estimate`. **Keep sending the ORIGINAL fare** (`fare_estimate`, not
  `discounted_fare`) so enough funds are held.
- The server captures the **discounted** amount at booking time. Blocking the full
  fare and capturing less is intentional and safe.
- **Do not** subtract the auto-discount yourself before calling
  `validate_ride_payment` — if you under-block, the hold may be insufficient.

Net: **display** `discounted_fare`, but **block** `fare_estimate`.

---

## 5. UI checklist

On the vehicle-selection / fare screen, **per vehicle row**:

- [ ] If `promo_applied == true`: show `discounted_fare` as the price; show the
      original `fare_estimate` struck through; show a "− `promo_discount`" line.
- [ ] If `promo_auto_applied == true`: show an **"Auto-applied"** chip with the
      `promo_code` (and optional `promo_description`), plus a **Remove** control.
- [ ] **Remove** → re-call `estimate_fare` with `disable_auto_promo: true`, and keep
      that flag through `validate_ride_payment` (unaffected) and `book`.
- [ ] If the rider types a code: send it as `promo_code`. It overrides auto — you can
      stop sending `disable_auto_promo` (or leave it, code wins regardless).
- [ ] If a typed code fails, use `promo_error` to message the rider. On failure you
      may offer to fall back to auto (just resend without the code).
- [ ] On the receipt/history screen, if `promo_auto_applied == true`, you can label
      the discount "Auto-applied promo" vs a manually entered one.

### Suggested state model
```
enum PromoMode { auto, manualCode, none }

// none  => user tapped "Remove"      => disable_auto_promo: true, no promo_code
// auto  => default                    => (send neither / disable_auto_promo: false)
// code  => user typed a code          => promo_code: "XYZ"
```
Persist this choice across estimate → validate → book so the rider's intent is
consistent through the whole flow.

---

## 6. Edge cases

| Case | Expected app behaviour |
|---|---|
| Rider changes vehicle type | Re-read the promo block from that vehicle's estimate — it may differ or be absent. |
| No promo for the selected vehicle | No promo fields present → show plain fare. |
| Rider typed an invalid code | `promo_error` set on the estimate; price stays at `fare_estimate`. Offer retry or auto. |
| Auto promo runs out between estimate and book | Ride books at full fare, no error. Show the real charged amount from the booking/receipt response. |
| Rider removed auto, then cleared the code field | Send `disable_auto_promo: true` to keep auto off; otherwise it re-applies. |

---

## 7. Quick test script (staging)

1. Ask backend to create a promo with `is_auto_apply: true`, e.g. 10% off,
   `min_ride_amount: 0`, no vehicle restriction, active window covering now.
2. `estimate_fare` **without** `promo_code` → estimates should show
   `promo_auto_applied: true` and a `discounted_fare`.
3. `estimate_fare` **with** `disable_auto_promo: true` → no promo fields.
4. `estimate_fare` **with** a valid `promo_code` → `promo_auto_applied: false`, code
   wins.
5. `book` without a code → receipt `fare_breakdown.promo_auto_applied == true`,
   `promo_discount > 0`.
6. Cancel the ride pre-pickup → confirm the promo usage is released (backend voids
   it automatically; the rider should be able to use it again).

---

## 8. TL;DR for the app

1. Add optional `disable_auto_promo` (bool) to `estimate_fare` and `book` bodies.
2. Read the per-estimate promo block; **new fields**: `promo_code`,
   `promo_auto_applied`.
3. Show `discounted_fare` as the price; badge auto promos; give a **Remove** action
   that sets `disable_auto_promo: true`.
4. A typed `promo_code` always overrides auto — no client logic needed.
5. Keep blocking the **original** `fare_estimate` in `validate_ride_payment`.
