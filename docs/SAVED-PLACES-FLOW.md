# Saved Places Flow (Frontend)

This document describes how **saved places** work in the DukaGo rider app and how the frontend maps to the v4 API.

> **Important:** There is **no separate favourites list or unfavourite API**. A saved place **is** a favourite (`is_favourite: true` from the backend). Removing a saved place **deletes** it via `DELETE go/user/saved-places/{id}`.

---

## Product rules

| Rule | Behaviour |
|------|-----------|
| Single concept | Only **saved places** — UI may still say “favourite” in labels, but data is one list |
| Add | Creates a saved place (backend sets `is_favourite: true`) |
| List | `GET go/user/saved-places` → `data.saved_places[]` |
| Remove | `DELETE go/user/saved-places/{id}` — not a separate “unfavourite” call |
| Empty list | API returns `{"status_code":200,"data":{"saved_places":[]}}` — UI must clear local state |
| Heart icon (filled) | Address exists in the in-memory `savedPlaces` list (membership), not a separate flag check |

Preset labels from the API: `home`, `office`, `work`, `other` (see `FavoriteLocationChipCatalog`).

---

## API endpoints

Base: `https://go.selcom.app/api/v4/`

### List saved places

```
GET go/user/saved-places
```

**Response (example):**

```json
{
  "status_code": 200,
  "data": {
    "saved_places": [
      {
        "location": { "type": "Point", "coordinates": [39.287976, -6.814852] },
        "is_favourite": true,
        "_id": "6a54d056f5a7d38c0363df01",
        "user_id": "6a4b5f7084fd290007222211",
        "label": "home",
        "name": "57QQ+M85",
        "address": "57QQ+M85, Dar es Salaam, Tanzania",
        "lat": -6.814852029296543,
        "lng": 39.287976399064064,
        "__v": 0,
        "createdAt": "2026-07-13T11:47:02.776Z",
        "updatedAt": "2026-07-13T11:47:02.776Z"
      }
    ]
  }
}
```

**Empty list:**

```json
{
  "status_code": 200,
  "data": { "saved_places": [] }
}
```

### Add from recent / search

```
POST go/user/saved-places/from-recent
```

**Body** (`SaveRecentAsFavoriteRequest`): `label`, `name`, `address`, `lat`, `lng`

**Response (example):**

```json
{
  "status_code": 200,
  "message": "Saved to favourites",
  "data": {
    "place": { "...same shape as list item..." }
  }
}
```

The app treats success as `status_code == 200`, then **refetches** the list (`loadSavedPlaces` / `refreshSavedPlacesAfterMutation`). It does not rely on the returned `place` object for UI state today.

### Delete saved place

```
DELETE go/user/saved-places/{id}
```

Used when the user removes a heart / saved address. There is no `PUT .../favourite` or `GET .../favourites` in the current frontend.

---

## Response models

| File | Types | Used for |
|------|--------|----------|
| `lib/core/data/models/responses/get_saved_places_response.dart` | `GetSavedPlacesResponseModel`, `SavedPlacesData`, `SavedPlace` | `GET` list |
| `lib/core/data/models/responses/create_saved_place_response.dart` | `CreateSavedPlaceResponseModel`, `CreateSavedPlaceData` | `POST from-recent` envelope |
| `lib/core/data/models/user_profile_models.dart` | `SavedPlaceModel`, `SavedPlaceGeoLocation` | `data.place` on create response |

**`SavedPlace` vs `SavedPlaceModel`:** Same API fields; list parsing uses `SavedPlace` (dates as `DateTime?`); create response uses `SavedPlaceModel` (dates as `String?`). Both read `location.coordinates` as GeoJSON `[lng, lat]`.

**`is_favourite`:** Parsed on both models for contract alignment. UI treats **list membership** as “saved/favourite”; do not implement a separate unfavourite path.

---

## Data layer

| Layer | Responsibility |
|-------|----------------|
| `ProfileRemoteDataSource` | `getSavedPlaces`, `saveRecentAsFavorite`, `deleteSavedPlace` |
| `ProfileRepository` / `ProfileUseCase` | `Either<Failure, T>` wrappers |
| `URLS.address` | `savedPlaces`, `saveRecentAsFavorite` |

---

## Controllers & screens

### Home — `HomeController`

- **`savedPlaces`** — reactive list loaded on home init (`_loadHomeData`) and via **`loadSavedPlaces()`**
- **`getSavedPlaceFor(address, placeId)`** — match by id or normalized address
- **`isPlaceFavorite(address, placeId)`** — `getSavedPlaceFor(...) != null`
- **Add** — `saveRecentAsFavorite` → `POST from-recent` → `refreshSavedPlacesAfterMutation()`
- **Remove** — `_confirmAndDeleteSavedPlace` → `DELETE` → `refreshSavedPlacesAfterMutation()`
- **Heart on recent/search** — `toggleFavoriteForRecent` / `toggleAddAddressBottomSheet*`: if already saved → delete flow; else → add sheet

Chips: `FavoriteLocationChipsRow` + `SavedPlacesOrdering` (preset order: home, office, work, other).

### Profile — `FavoriteLocationsController` + `FavoriteLocationsScreen`

- Loads **`getSavedPlaces()`** (same endpoint as home), not a favourites URL
- **`removeSavedPlace`** — confirmation dialog → `deleteSavedPlace` → `fetchSavedPlaces()` + `HomeController.loadSavedPlaces()`
- Tap row → navigate to booking with destination from saved place

Route: `AppRoutes.favoriteLocations` (screen title uses saved-locations copy).

---

## UI refresh rules

1. After **add** or **delete**, refetch from server (no optimistic list removal).
2. On **GET** success, always assign the API list, including `[]`:
   ```dart
   savedPlaces.assignAll(response?.data?.savedPlaces ?? const []);
   ```
3. Profile saved-locations screen and home chips should stay in sync after mutations on either screen.

---

## File index

```
lib/core/network/urls.dart                          # endpoint constants
lib/core/data/models/responses/get_saved_places_response.dart
lib/core/data/models/responses/create_saved_place_response.dart
lib/core/data/models/requests/save_recent_as_favorite_request.dart
lib/core/data/models/user_profile_models.dart         # SavedPlaceModel
lib/features/profile/data/datasources/profile_remote_data_source.dart
lib/features/profile/presentation/controllers/favorite_locations_controller.dart
lib/features/home/presentation/controllers/home_controller.dart
lib/shared/utils/saved_places_ordering.dart
lib/shared/utils/favorite_location_chip_catalog.dart
lib/shared/widgets/favorite_location_chips_row.dart
lib/shared/widgets/add_favorite_location_sheet.dart
```

---

## What we intentionally do **not** use

- `GET go/user/saved-places/favourites`
- `PUT go/user/saved-places/{id}/favourite` as “unfavourite”
- Separate in-app “favourites only” cache distinct from `savedPlaces`

If the backend adds endpoints later, align with this doc and `.agent/context/backend/API_CONTRACT.md` before wiring new UI.
