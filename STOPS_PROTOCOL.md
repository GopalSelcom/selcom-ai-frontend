# Mid-Ride Stops Update Protocol

This document outlines the technical flow for editing stops during an active ride in the Selcom Go application.

## 1. The 2-Step API Flow

### Step 1: Preview (Get Fare Delta)
Before applying a change, the frontend must request a fare preview.
*   **Endpoint**: `PUT {{baseUrl}}/api/v4/go/rides/{ride_id}/stops`
*   **Body**:
    ```json
    {
      "stops": [ ... ],
      "confirm": false
    }
    ```
*   **Response**: `StopUpdatePreviewModel`
    *   Shows `old_fare`, `new_fare`, and `delta_amount`.
    *   Frontend uses this to show the "Confirm & Update" UI.

### Step 2: Apply (Commit Change)
Once the user confirms, the actual update is triggered.
*   **Endpoint**: `PUT {{baseUrl}}/api/v4/go/rides/{ride_id}/stops`
*   **Headers**: `Idempotency-Key: <unique_uuid>`
*   **Body**:
    ```json
    {
      "stops": [ ... ],
      "confirm": true
    }
    ```
*   **Response**: `StopUpdateAppliedModel`
    *   Contains `block_update_validation_id`.
    *   Contains `direction` ("up", "down", or "none").

---

## 2. Payment & Processing Flow

### Phase A: Payment Hold (If Fare Increased)
If `direction == "up"`, the frontend must authorize the additional charge.
*   **Trigger**: The frontend calls the wallet payment API using the `block_update_validation_id`.
*   **Backend**: Place a hold on the new amount.

### Phase B: Driver Sync (Recalculating Route)
After payment (or immediately if price decreased), the backend recalculates the route.
*   **Frontend State**: Show "Recalculating Route" spinner.
*   **Real-time Event**: Listen for WebSocket `ride:stops_updated`.
*   **Hardened Fallback**: If the socket is missed, the frontend polls `GET /v4/go/rides/active-ride` every 8 seconds.

---

## 3. WebSocket Events (Collection: Ride Tracking)

| Event Name | Direction | Description |
| :--- | :--- | :--- |
| `ride:stops_updated` | Backend -> App | Sent when the route is fully recalculated and synced with the driver. |
| `ride:stops_update_failed` | Backend -> App | Sent if the driver rejects or the route cannot be calculated. |
| `ride:status_update` | Backend -> App | General status update (triggers a details refresh). |

---

## 4. Recovery & Resumption Flow

To ensure the app survives crashes or restarts during an update:

1.  **Idempotency Persistence**: The `idempotency_key` is saved locally. This prevents `409 STOPS_UPDATE_IN_FLIGHT` errors if the user retries a recovered update.
2.  **State Check**: Upon app start, the app checks `pending_stops_update` in the ride details.
3.  **Resumption**:
    *   **If `pending_payment`**: The app restores the fare preview and offers the "Confirm & Update" button. Tapping it skips the `PUT /stops` call and goes straight to payment.
    *   **If `pending_da`**: The app restores the "Recalculating Route" spinner and waits for the socket/poll result.

## 5. Summary Tracking
*   **Active Update Check**: `GET {{baseUrl}}/api/v4/go/rides/active-ride`
*   **Success Indicator**: `pending_stops_update` becomes `null` and the main `stops` list is updated.
