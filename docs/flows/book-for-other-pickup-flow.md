# Book-for-other pickup flow

When the rider confirms pickup on **Confirm Location** (`ride_pickup` flow), the app decides whether to show the **“Are you booking for someone else?”** bottom sheet and which options appear.

## Related code

| File | Role |
|------|------|
| `lib/features/home/presentation/controllers/confirm_location_controller.dart` | Orchestrates API calls and sheet presentation |
| `lib/shared/utils/book_for_other_prompt_policy.dart` | `CheckBookModeGate`, `BookForOtherPromptAction`, active-ride matrix |
| `lib/shared/utils/active_rides_parser.dart` | Parses active rides; `hasSelfActiveRide`, `countBookedForOtherRides` |
| `lib/features/ride/presentation/widgets/booking_for_someone_else_flow_bottom_sheet.dart` | Choice + passenger details UI |
| `lib/features/ride/presentation/controllers/vehicle_selection_controller.dart` | `_guardActiveRideLimits` before payment |

## APIs and settings

### Settings — `GET /go/settings`

```json
"book_for_other": {
  "enabled": true,
  "distance_threshold_km": 1,
  "max_active": 1
}
```

| Field | Meaning |
|-------|---------|
| `enabled` | Master switch. When `false`, always book for self (no sheet). |
| `distance_threshold_km` | Used by **backend** in `check-book-mode` only — **not** evaluated on the client. |
| `max_active` | Max concurrent rides with `is_booked_for_other: true`. The rider’s own ride does **not** count. |

### Distance gate — `GET /go/check-book-mode`

Query: `rider_lat`, `rider_lng`, `pickup_lat`, `pickup_lng`

Response (relevant field):

```json
{
  "data": {
    "show_book_for_other_option": true,
    "distance_km": 1.4,
    "threshold_km": 1
  }
}
```

- `show_book_for_other_option: true` → pickup is far enough from rider GPS (backend applies `distance_threshold_km`).
- `show_book_for_other_option: false` → pickup near rider → **no sheet**, book for self.
- Requires device GPS. The frontend does **not** compute distance locally.

### Active rides — `GET /go/rides/active`

Each ride includes `is_booked_for_other`:

- `false` → rider’s own trip (max **one** active self ride).
- `true` → booked for someone else (counts toward `max_active`).

## Decision flow

```
User taps Confirm on pickup map
              │
              ▼
     book_for_other.enabled?
         │              │
        no             yes
         │              │
         ▼              ▼
   Book for me    Load active rides
   (no sheet)            │
                          ▼
              Has self active ride
              AND otherCount < max_active?
                    │            │
                   yes           no
                    │            │
                    ▼            ▼
         Sheet: "For          Call check-book-mode
          someone else"       (if GPS available)
          only                     │
                    ┌──────────────┼──────────────┐
                    │              │              │
              API false      API true       GPS off / API error
              (near pickup)       │              │
                    │              │              │
                    ▼              └──────┬───────┘
              Book for me                 │
              (no sheet)                  ▼
                              Active-ride option matrix
```

## Active-ride option matrix

After the distance gate passes (or is skipped), compute:

```
canBookSelf  = no active ride with is_booked_for_other == false
canBookOther = count(is_booked_for_other == true) < max_active
```

| canBookSelf | canBookOther | Result |
|-------------|--------------|--------|
| yes | yes | Choice sheet: **For me** + **For someone else** |
| no | yes | Choice sheet: **For someone else** only |
| yes | no | Book for me — **no sheet** (at book-for-other limit) |
| no | no | **Blocked** — error dialog |

### Sheet steps

1. **Choice step** — “For me” and/or “For someone else” (see `showSelfOption` / `showOtherOption` on the bottom sheet).
2. **Details step** — passenger name and phone (only when “For someone else” is chosen).

When only one option is shown, the user still sees the **choice step** first (not passenger details directly).

## Special cases

### Active self ride

If the rider already has a trip (`is_booked_for_other: false`), any **new** booking must be for someone else:

- Skips `check-book-mode` (distance irrelevant).
- Shows choice sheet with **only** “For someone else”.

### Location off / GPS denied

- `check-book-mode` cannot run → distance gate is **skipped**.
- Active-ride matrix still applies (sheet can show when no active rides and limits allow).

### Location on, pickup near rider

- API returns `show_book_for_other_option: false`.
- **No sheet** — book for self. This decision comes **only from the API**, not frontend distance math.

### Only “for me” available

When `canBookSelf` is true but `canBookOther` is false (e.g. already at `max_active` book-for-other rides):

- **No sheet** — continues as self booking directly.

## Payment guard (second check)

Before `POST` validate/book, `VehicleSelectionController._guardActiveRideLimits` re-checks:

- Self booking blocked if any self active ride exists.
- Book-for-other blocked if `countBookedForOtherRides >= max_active`.

## Output to ride flow

Pickup confirm returns to location selection with:

```dart
{
  'isBookedForOther': bool,
  'passengerName': String?,  // when booked for other
  'passengerPhone': String?, // E.164 when booked for other
  // ... pickup lat/lng/address
}
```

These fields are passed through vehicle selection and into `book_ride` / `validate_ride_payment` requests as `is_booked_for_other`, `passenger_name`, `passenger_phone`.
