# Wallet Balance Visibility Flow

This document describes how the app **masks wallet and Selcom Pesa balances by default**, reveals them only when the user taps the **eye** icon, and **auto-hides** them again after a shared timeout.

## Goal

1. **Never show full balance amounts by default** on Profile, Wallet, or Selcom Pesa linked-account UI.
2. **Keep currency visible** while masking digits (e.g. `TZS ••••••`).
3. **Reveal on eye tap** — show cached amount immediately, then refresh from API.
4. **Auto-hide** after `BalanceVisibilityPolicy.autoHideAfterReveal` (30 seconds).
5. **Re-mask on screen entry** and when returning from any child route.
6. Use the **same timing policy** everywhere so future screens can reuse one constant.

## Screens covered

| Screen | Widget / area | Controller | Balance API |
|--------|----------------|------------|-------------|
| **Profile** | `WalletSummaryCard` | `ProfileController` | `go_wallet/go_card_balance` (via `GetWalletSummaryUseCase`) |
| **Wallet** | `WalletInfoCard` | `WalletController` | `go_wallet/go_card_balance` |
| **Selcom Pesa → Wallet** | Linked account row | `PaymentMethodsController` | `go/selcom_pesa/main_balance` |

## Main files

### Shared policy & formatting

- `lib/shared/utils/balance_visibility_policy.dart` — **single** auto-hide duration (`autoHideAfterReveal`)
- `lib/features/wallet/presentation/utils/wallet_format_utils.dart` — `formatHiddenWalletBalance()` (`TZS ••••••`)

### Profile (Go wallet card)

- `lib/features/profile/presentation/controllers/profile_controller.dart`
  - `ProfileWalletCache` — in-memory session cache (balance, currency, wallet number, reserved)
  - `resetWalletBalanceVisibilityOnScreenEntry()`
  - `toggleWalletBalanceVisibility()`
- `lib/features/profile/presentation/widgets/wallet_summary_card.dart` — presentational card + eye UI
- `lib/features/profile/presentation/screens/profile_screen.dart` — wires card to controller

### Wallet screen

- `lib/features/wallet/presentation/controllers/wallet_controller.dart`
- `lib/features/wallet/presentation/widgets/wallet_info_card.dart`
- `lib/features/wallet/presentation/bindings/wallet_route_middleware.dart` — masks balance on route open
- `lib/features/wallet/presentation/screens/wallet_screen.dart`
- `lib/features/wallet/data/repositories/wallet_repository_impl.dart` — `getWalletPageData()` (summary + transactions)

### Selcom Pesa linked balance

- `lib/features/profile/presentation/controllers/payment_methods_controller.dart`
  - `revealLinkedAccountBalance()`
- `lib/features/payment/presentation/screens/selcom_pesa_to_wallet_screen.dart`

### API models

- `lib/features/wallet/data/models/go_card_balance_response.dart` — `go_wallet/go_card_balance`
- `lib/features/profile/domain/entities/selcom_pesa_balance_entity.dart` — `go/selcom_pesa/main_balance`

## Default display (hidden)

When `isBalanceVisible == false`:

| Field | Profile / Wallet | Selcom Pesa linked row |
|-------|------------------|-------------------------|
| Main balance | `TZS ••••••` via `formatHiddenWalletBalance()` | `formatHiddenWalletBalance(defaultCurrency)` |
| Reserved (Wallet only) | `Reserved: TZS ••••••` | N/A |
| Eye icon | `Iconsax.eye` | `Iconsax.eye` |

Currency code comes from API/cache when available; otherwise `CurrencyFormatter.displaySymbol`.

## High-level flow

```text
Screen opened
  -> resetWalletBalanceVisibilityOnScreenEntry()  (amount masked)
  -> UI shows currency + ••••••

User taps eye
  -> isBalanceVisible = true
  -> show cached amount immediately
  -> start BalanceVisibilityPolicy.autoHideAfterReveal timer
  -> fetch balance from API (Cupertino spinner in eye slot)

API success
  -> update cached amount
  -> UI shows full formatted balance

Timer fires OR user taps eye-slash OR user leaves & returns
  -> isBalanceVisible = false
  -> UI shows currency + •••••• again
```

## Detailed behaviour

### 1. Profile screen

**On `ProfileController.onInit`:**

- Calls `resetWalletBalanceVisibilityOnScreenEntry()` — always masked on entry.
- Restores wallet fields from `ProfileWalletCache` when already loaded (no extra API on revisit).

**Eye tap (`toggleWalletBalanceVisibility`):**

- **Hide:** local only, no API.
- **Show:** sets visible, schedules auto-hide timer, calls `fetchWalletBalance(initialLoad: false)` for silent refresh.
- While refreshing: `isRefreshingWalletBalance` — amount text stays, **black `CupertinoActivityIndicator`** replaces eye icon.

**Leaving Profile to a child screen:**

- All `open*` navigation methods use `_navigateAndResetWalletBalanceOnReturn()` so balance is masked when the user comes back.

### 2. Wallet screen

**On wallet route open (`WalletRouteMiddleware`):**

- `resetWalletBalanceVisibilityOnScreenEntry()`
- `loadWallet()` — reuses `ProfileWalletCache` when profile already fetched balance; otherwise calls `getWalletPageData()`.

**Eye tap (`toggleBalanceVisibility`):**

- Same pattern as profile: reveal cached → timer → `_refreshWalletBalance()` from `go_card_balance`.
- **Reserved line** uses `formattedReservedBalanceLabel` — masked/unmasked together with main balance.

**Child route (e.g. transaction history):**

- `openTransactionHistory()` resets visibility when user pops back.

### 3. Selcom Pesa linked account balance

**Eye tap (`revealLinkedAccountBalance`):**

- Toggles `isAmountVisible`.
- On show: POST `main_balance`, display formatted balance, schedule `BalanceVisibilityPolicy.autoHideAfterReveal`.
- Loading: black `CupertinoActivityIndicator` in eye slot.

Per-account state is stored in `_linkedBalanceVisible` keyed by account id.

## Shared auto-hide policy

```dart
// lib/shared/utils/balance_visibility_policy.dart
BalanceVisibilityPolicy.autoHideAfterReveal       // Duration(seconds: 30)
BalanceVisibilityPolicy.hiddenBalancePlaceholder  // '••••••'
```

Masked Go wallet labels use `formatHiddenWalletBalance(currencyCode)` which prefixes currency to `hiddenBalancePlaceholder`.

Used by:

- `ProfileController._scheduleWalletBalanceHide()`
- `WalletController._scheduleWalletBalanceHide()`
- `PaymentMethodsController._scheduleLinkedBalanceHide()`

**To change timeout app-wide:** edit only `balance_visibility_policy.dart`.

## Session cache (`ProfileWalletCache`)

Defined in `profile_controller.dart`. Shared between Profile and Wallet controllers.

| Field | Purpose |
|-------|---------|
| `isLoaded` | Profile has fetched wallet at least once this session |
| `balance`, `currency`, `walletNumber`, `reserved` | Last known values for silent eye refresh |
| `isBalanceVisible` | Sync flag; reset to `false` on screen entry |

Cleared on logout via `ProfileWalletCache.clear()` / `WalletSession.teardownOnLogout()`.

## API contracts

### `GET go_wallet/go_card_balance`

Model: `GoCardBalanceResponseModel` → `GoCardBalanceData` → `data[]` line items.

Example:

```json
{
  "status_code": 200,
  "message": "Balance fetched",
  "response": {
    "result": "SUCCESS",
    "resultcode": "000",
    "pan": "84100000268",
    "name": "Selcom Go - USER",
    "data": [{
      "currency": "TZS",
      "balance": 1371,
      "reserved": 597,
      "available": 774,
      "status": "ACTIVE"
    }]
  }
}
```

Wallet UI uses **available** as spendable balance and **reserved** for the reserved line.

### `POST go/selcom_pesa/main_balance`

Model: `SpMainBalanceResponse` → `SpAccountData.balance`.

Example:

```json
{
  "status_code": 200,
  "message": "User balance fetched successfully.",
  "data": { "balance": 81964.85 }
}
```

## UI rules (presentational widgets)

- **Controllers** own: visibility state, timers, API calls, navigation reset.
- **Widgets** (`WalletSummaryCard`, `WalletInfoCard`) only bind `isBalanceVisible`, `isRefreshingBalance`, and formatted strings.
- **Do not** embed raw `GoogleMap`-style business rules in widgets; follow `ui-controller-logic.mdc`.

## Adding a new hide/show balance surface

1. Import `BalanceVisibilityPolicy` for the auto-hide timer.
2. Use `formatHiddenWalletBalance()` with `BalanceVisibilityPolicy.hiddenBalancePlaceholder` for masked Go wallet display (or a feature-specific placeholder for non-wallet APIs).
3. Call `resetWalletBalanceVisibilityOnScreenEntry()` (or equivalent) when the screen opens and when child routes pop.
4. Use **black `CupertinoActivityIndicator`** in the eye slot during API refresh (not `CircularProgressIndicator`).
5. Do **not** add another `Duration(seconds: 30)` — use the shared policy.

## Related flows

- Selcom Pesa link / top-up: `docs/flows/selcom-pesa-link-flow.md`
- Wallet refresh after top-up: `lib/features/wallet/presentation/utils/wallet_refresh.dart`
