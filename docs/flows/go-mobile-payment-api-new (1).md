# Go Wallet Top-up — Mobile Payment (Card) APIs

This document covers the 4 APIs for **wallet top-up by card** (plus a server-side Selcom callback the app never calls). All of them live under `/v4/go_wallet/` and require the JWT `Authorization` header like other Go APIs.

> ⚠️ All responses come back as **HTTP 200** — always check the `status_code` field **inside** the JSON body, not the HTTP status.

Amounts are in **TZS** and must be a positive number (no fixed minimum).

---

## The 4 APIs at a glance

| # | API | When to call |
|---|-----|--------------|
| 1 | `GET /v4/go_wallet/fetch_cards` | When opening the "Top up by card" screen — to show saved cards |
| 2 | `POST /v4/go_wallet/go_add_card_new` | **Main API.** Always call this to start a top-up (both new & saved card) |
| 3 | `POST /v4/go_wallet/go_pay_by_existing_card` | After #2 with `newCard: 1`, to charge a saved card token |
| 4 | `POST /v4/go_wallet/go_init_card_session` | Only for the native card-entry form (cardBin flow) instead of the webview |

---

## 1. Show saved cards — `GET fetch_cards`

Call this first when the card payment screen opens.

> ⚠️ **Different from the Duka food module.** In the food app this was `POST fetch_cards` with body `{ "type": "3" }`. Here it is a **`GET`** with **no body** — don't send `type`. The card object is the raw **Selcom stored-cards** shape (`card_token`, `masked_card`), **not** the dukadirect shape (`card_number`, `card_type`, `expiry_date`, `name_on_card`, `is_active`). Use `card_token` as the value you pass to `go_pay_by_existing_card`.

**Response:**
```json
{
  "reference": "...",
  "resultcode": "000",
  "result": "SUCCESS",
  "message": "...",
  "data": [ { "card_token": "...", "masked_card": "512345xxxxxx2345", ... } ]
}
```

- `resultcode == "000"` and `data` non-empty → show the saved cards list **+** an "Add new card" button.
- `resultcode == "404"` / empty `data` → user has no linked cards, show only "Add new card". (Also returned when the rider has no `gateway_buyer_uuid` yet — i.e. has never added a card.)

---

## 2. Start a top-up — `POST go_add_card_new` (MAIN API)

This creates the Selcom checkout order. Call it in **both** flows — the `newCard` flag decides what you get back.

**Request:**
```json
{ "amount": 5000, "newCard": 0 }
```

Optional: `type` (payment method, default `"CARD"`), `payment_mode` (default `"Mastercard/Visa"`).

> 🔁 **Reusing the food-module card screen?** `amount` also accepts the food frontend's `sendAmount` alias, and any extra food keys you send (`allCart_id`, `deliveryCharge`, `sqr_amount`, `promo_code`, …) are now **ignored** rather than rejected. Only `amount`/`sendAmount` + `newCard` are actually used for a wallet top-up — there is no cart, delivery, promo or billing-address logic here.

### Flow A — new card (webview): `newCard: 0`

**Response:**
```json
{ "status_code": 200, "message": "SUCCESS", "url": "https://...", "transid": "ABC123" }
```

→ Open `url` in a webview. The user enters card details on Selcom's hosted page. When payment finishes the page redirects (redirect.html) — close the webview. **You're done**: the wallet credit + success push notification happen via the server callback.

### Flow B — saved card: `newCard: 1`

**Response:**
```json
{ "status_code": 200, "message": "cardexists", "url": "", "transid": "ABC123" }
```

→ Keep the `transid` and go to step 3.

**Errors:** `status_code: 400` with `errorMsg` (order creation failed — show error, let user retry).

---

## 3. Charge a saved card — `POST go_pay_by_existing_card`

Call only after step 2 returned `"cardexists"`.

**Request:**
```json
{ "transid": "ABC123", "card_token": "<card_token from fetch_cards>" }
```

Every response also carries a boolean `result` (`true` only on `200`) and echoes back `transid`.

**Responses (by `status_code`):**
- `200` → debit accepted. Show success / "processing" — the confirmed credit + push notification arrive via callback within moments.
- `890` → debit unsuccessful (e.g. **insufficient funds** on the card). Show the `message`.
- `455` → this transid was already paid/completed (double-tap protection).
- `720` → debit failed for any other reason. Show the `message`, allow retry with another card.
- `404` → no order found for that `transid` (you called this before `go_add_card_new`, or sent a stale/wrong `transid`).

---

## 4. Native card form — `POST go_init_card_session`

Alternative to Flow A **only if** the app collects the card number natively (Selcom link-card session). `cardBin` = first 6 digits of the card the user typed.

**Request:**
```json
{
  "amount": 5000,
  "newCard": 0,
  "email": "user@mail.com",
  "mobile_number": "712345678",
  "country_code": "+255",
  "cardBin": "512345"
}
```
(Optional: `fname, lname, address, city, state, country, postalcode` — we default them if omitted.)

**Response:** `{ "status_code": 200, "message": "...", "url": "", "transid": "ABC123", "data": [ ...session data... ] }` — use `data` to continue the Selcom card session in-app. On failure: `status_code: 400` + `message`.

> ⚠️ **Different from the Duka food module.** The food app's `init_card_session_food` returned **Cybersource Silent Order Post** fields (`access_key`, `profile_id`, `transaction_uuid`, `signature`, `signed_field_names`, …) to post to Cybersource. This endpoint instead returns the **Selcom `init-linkcard-session`** payload — post `data` to Selcom, not Cybersource. Field names differ; drive the session off whatever `data` contains rather than hard-coding Cybersource keys.

---

## How success is confirmed (important!)

The **app never confirms the payment itself.** Selcom calls our webhook (`go_mobile_payment_callback`) when the money lands:

- We mark the transaction **Completed** and credit the wallet (`utilityref` = user's wallet account number, so funds settle straight onto their prepaid wallet).
- The user gets a **"Wallet top-up successful" push notification**.
- On failure they get a failure push instead.

So after initiating payment: listen for the push notification and/or **refresh the balance** with the existing `GET /v4/go_wallet/go_card_balance` when the user returns to the wallet screen.

---

## Quick decision tree

```
Open top-up screen
  └─ GET fetch_cards
       ├─ has cards → user picks saved card
       │     └─ POST go_add_card_new { amount, newCard: 1 }   → transid
       │           └─ POST go_pay_by_existing_card { transid, card_token }
       │                 ├─ 200 → success (push confirms)
       │                 ├─ 890 → insufficient funds
       │                 └─ 720 → failed, retry
       └─ no cards / "Add new card"
             ├─ webview flow → POST go_add_card_new { amount, newCard: 0 } → open url
             └─ native form  → POST go_init_card_session { ..., cardBin }  → continue session
```

---

## If you're porting from the Duka food-module card screens

These 4 APIs were ported from the food module (`food/food_add_card_new`, `food/food_pay_by_existing_card`, `food/init_card_session_food`, `fetch_cards`) with **all** Duka logic (carts, restaurants, promos, delivery, billing addresses) stripped out. Key differences to watch for:

| Topic | Duka food module | Go wallet top-up |
|-------|------------------|------------------|
| Endpoint prefix / names | `food/food_add_card_new`, etc. | `/v4/go_wallet/go_add_card_new`, etc. (`go_` prefix) |
| Amount field | `sendAmount` (String) | `amount` (Number) — **`sendAmount` still accepted as alias** |
| Extra body keys | `allCart_id`, `deliveryCharge`, `promo_code`, `billing_address_id`, `sqr_amount`, `service_fees`… | **ignored** (tolerated, not used) — no cart/delivery/promo/billing logic |
| `fetch_cards` | `POST` with `{ "type": "3" }` | **`GET`, no body**; card objects use Selcom `card_token`/`masked_card` shape |
| Native card session | Cybersource SOP fields (`access_key`, `signature`…) | Selcom `init-linkcard-session` `data` payload |
| `delete_card` | Available | **Not part of this flow** — cards are managed elsewhere |
| Callback | `add_card_callback` | Server-only `go_mobile_payment_callback` (you never call it) — success is confirmed by push + balance refresh |
| Settlement target | Duka order | Rider's prepaid wallet (`utilityref` = wallet account number) |

---

If any response shape doesn't match what you see in practice, reach out to the backend team and we'll adjust.
