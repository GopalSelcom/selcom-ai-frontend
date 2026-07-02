# Selcom Pesa link & to-Go-wallet flow

Selcom Go lets users **link Selcom Pesa phone numbers** and **top up the Go wallet** from Selcom Pesa on one screen. Linking and self top-up share **Selcom Pesa to Go Wallet** (`/selcom-pesa-to-wallet`).

---

## Entry points

| Where | Action | Opens |
|-------|--------|--------|
| Wallet → Add money | Tap **Selcom Pesa** | `SelcomPesaToWalletScreen` |
| Payment Methods | Tap **Selcom Pesa** row | Same screen |

Route: `AppRoutes.selcomPesaToWallet` → `/selcom-pesa-to-wallet`

---

## Screen layout (Selcom Pesa to Go Wallet)

Same UI as the former bottom sheet, now a full screen.

| Section | When / what |
|---------|-------------|
| **Payment methods** | Title + Selcom Pesa card(s) |
| **Linked list** | One card per `LINKED` account from `GET linked_accounts` |
| **Account selection** | Circle selector on the **right** of each linked card; **none selected** by default |
| **Link another** | Shown below linked cards while count &lt; **5** |
| **Unlinked** | Single card: connect subtitle + **Link account** |
| **Remove account** | `AppCupertinoTextButton` on each linked card (local unlink until API) |
| **Pull to refresh** | Reloads linked list via `GET linked_accounts` |
| **Use another number** | Opens other-number top-up bottom sheet (separate controllers) |
| **Amount** | TZS field (screen-owned `TextEditingController`) |
| **Done** | See top-up rules below |

Tap linked card body → **no action** (only the right selector toggles selection).

**Done button:**

| Selection | Flow |
|-----------|------|
| **None** | Self top-up (current flow: app install check, short code, open Selcom Pesa) |
| **One linked account** | Other-number API path with that account’s SP `mobile_number` — **no app open**, payment pending dialog + polling |

**Balance (linked cards only):**

- Default: `••••••` (hidden)
- Tap **eye** → `POST main_balance` with that account’s **SP** `country_code` + `mobile_number`
- Shows balance (currency from API response)
- Auto-hides to dots after **30 seconds**

Tap **Link account** on unlinked card → phone number bottom sheet (no connect-steps screen).

---

```
Tap "Link account" on unlinked card
        │
        ▼
Phone number bottom sheet
(SelcomPesaFlowBottomSheet)
        │
        ▼
User enters TZ number (+255 in UI)
Body: sp_country_code + sp_mobile_number (9 digits, no trunk 0)
        │
        ▼
POST go/selcom_pesa/send_link_request
        │
        ├── status LINKED ──► Already-linked dialog
        │
        └── otherwise ──────► Request-sent message dialog + Got it
```

There is **no polling** during link. User stays in Selcom Go; app refreshes via `GET linked_accounts` (on screen open, after link request, or pull-to-refresh).

### Unlink (current)

```
Tap "Remove account" on linked card
        │
        ▼
Local list update + success dialog
(no backend call yet)
        │
        ▼
Pull-to-refresh may restore row until unlink API ships
```

---

## APIs

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `POST` | `go/selcom_pesa/send_link_request` | Start / repeat link request |
| `GET` | `go/selcom_pesa/linked_accounts` | Linked (and pending) accounts for UI |
| `POST` | `go/selcom_pesa/main_balance` | Optional balance on linked detail sheet |

### `POST send_link_request`

**Body:**

```json
{
  "sp_country_code": "255",
  "sp_mobile_number": "711410410"
}
```

- UI shows **+255**; send **9-digit NSN** without leading `0`.
- Headers: `device_type`, `device_token`, `language_code`, `int_udid` + JWT (`selcom_pesa_link_headers.dart`).

**Response (relevant):** `status` (`PENDING` | `LINKED` | …), phone/name fields.

### `GET linked_accounts`

- Returns linked and pending rows.
- Screen shows **only `LINKED`** accounts as cards (up to 5 linked in product rules).
- Duplicate numbers merged in UI by normalized 9-digit key.

---

## Top-up on the same screen

| Action | Flow |
|--------|------|
| **Done** (no card selected) | `SelcomPesaTopupController.submitSelfTopUp` — install check, short code, open Selcom Pesa |
| **Done** (one linked card selected) | `submitSelectedLinkedAccountTopUp` — SP mobile from selection, polling dialog, **no** SP app open |
| **Use another number** | Separate `SelcomPesaTopupController` tag + own phone/amount fields → `submitOtherTopUp` |

Screen amount field and other-number sheet **do not share** `TextEditingController`s (avoids dispose/focus crashes).

---

## Related code

| File | Role |
|------|------|
| `lib/features/payment/presentation/screens/selcom_pesa_to_wallet_screen.dart` | Unified screen |
| `lib/features/payment/presentation/bindings/selcom_pesa_to_wallet_binding.dart` | Screen + top-up controller |
| `lib/features/profile/presentation/controllers/payment_methods_controller.dart` | Linked list load/refresh, link request, selection, balance, unlink |
| `lib/features/profile/presentation/widgets/selcom_pesa_flow_bottom_sheet.dart` | Phone input for link |
| `lib/features/payment/presentation/widgets/selcom_pesa_another_number_bottom_sheet.dart` | Other-number top-up |
| `lib/features/profile/data/datasources/selcom_pesa_link_remote_data_source.dart` | API calls |
| `lib/features/profile/data/models/selcom_pesa_link_models.dart` | Response models / entity mapping |
| `lib/features/profile/domain/entities/selcom_pesa_linked_account_entity.dart` | Domain entity |
| `lib/core/routes/app_routes.dart` | `selcomPesaToWallet` route |
| `lib/features/payment/presentation/widgets/add_money_to_wallet_bottom_sheet.dart` | Wallet entry |
| `lib/features/profile/presentation/screens/payment_methods_screen.dart` | Payment Methods entry |

---

## TODO (backend / product)

- Unlink account API (when product adds remove-linked-account action)
