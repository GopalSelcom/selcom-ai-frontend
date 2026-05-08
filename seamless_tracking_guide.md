# Technical Guide: Seamless Rider Tracking (Customer App)

To achieve the "Uber-like" smooth marker movement in your two customer apps, you need to implement **Marker Interpolation** and **Real-time Rotation**.

Since the Agent App is now sending high-density data (every 5 meters), the Customer App's job is to "bridge the gap" between those points.

---

## 1. Listen to the Real-time Event
The Customer App must listen to the socket event emitted by the backend (which was triggered by the Agent App).

**Event Name:** `rider:getRiderCurrentLocation` (or your equivalent listener)

```dart
socket.on('rider:getRiderCurrentLocation', (data) {
  double lat = data['latitude'];
  double lng = data['longitude'];
  double heading = data['heading'];
  
  // Update your map marker here
  updateRiderMarker(LatLng(lat, lng), heading);
});
```

---

## 2. Marker Interpolation (The "Smooth Slide")
**The Problem**: If you just call `setState()` with new coordinates, the marker will "jump."
**The Solution**: Use an animation controller to slide the marker from its old position to the new one over 500ms–1000ms.

### Flutter / Google Maps Implementation:
The following algorithm uses an `AnimationController` to smoothly "slide" the marker from the old coordinate to the new one over 1 second.

```dart
// 1. Define your variables in the State class
Marker? riderMarker;
LatLng? lastPosition;
double lastRotation = 0.0;

// 2. The Full Algorithm
void updateRiderMarker(LatLng newPosition, double newHeading) {
  // If this is the first update, just place the marker
  if (lastPosition == null) {
    setState(() {
      lastPosition = newPosition;
      lastRotation = newHeading;
      _updateMarker(newPosition, newHeading);
    });
    return;
  }

  // Create an Animation Controller for the transition
  final controller = AnimationController(
    duration: const Duration(milliseconds: 1000), // Match your update frequency
    vsync: this,
  );

  // Interpolate between the old and new LatLng
  final latTween = Tween<double>(begin: lastPosition!.latitude, end: newPosition.latitude);
  final lngTween = Tween<double>(begin: lastPosition!.longitude, end: newPosition.longitude);
  final rotationTween = Tween<double>(begin: lastRotation, end: newHeading);

  controller.addListener(() {
    final currentLat = latTween.evaluate(controller);
    final currentLng = lngTween.evaluate(controller);
    final currentRotation = rotationTween.evaluate(controller);

    setState(() {
      _updateMarker(LatLng(currentLat, currentLng), currentRotation);
    });
  });

  // Start the animation and cleanup when done
  controller.forward().then((_) {
    lastPosition = newPosition;
    lastRotation = newHeading;
    controller.dispose();
  });
}

// 3. Helper to update the Marker object
void _updateMarker(LatLng position, double rotation) {
  riderMarker = Marker(
    markerId: const MarkerId("rider_1"),
    position: position,
    rotation: rotation,
    icon: BitmapDescriptor.fromAssetImage(...), // Your car/bike icon
    anchor: const Offset(0.5, 0.5), // Center the icon so it rotates correctly
  );
}
```

---

## 3. Directional Rotation (Bearing)
Use the `heading` field sent by the Agent App to rotate the vehicle icon. This ensures the car "drives" forward rather than sliding sideways.

*   **Tip**: If the `heading` value is `0.0` (which can happen if the rider is stationary), keep the **previous** rotation value to prevent the icon from suddenly snapping to "North."

---

## 4. Map-Matching (Snap to Road)
To prevent the marker from appearing inside buildings:
1.  **Backend Side**: Take the raw lat/lng from the Agent App.
2.  **API Call**: Send it to the **Google Maps Roads API** (`snapToRoads` endpoint).
3.  **Forward to Customer**: Send the "snapped" coordinates to the Customer App instead of the raw ones.

---

## 5. Summary Checklist for "Uber-like" Feel

| Feature | Technical Requirement |
| :--- | :--- |
| **No Jitter** | Animate marker movement over ~500ms (Interpolation). |
| **Real-time** | Use WebSockets (Socket.io) instead of HTTP polling. |
| **Correct Heading** | Use the `heading` field to rotate the icon (`marker.rotation`). |
| **Road Alignment** | (Optional) Use Google Roads API to snap points to the street. |
| **Predictive Movement** | If no update is received for 5s, keep moving the marker forward slightly based on its last speed. |

---

## Technical Architecture Flow
`Agent App (5m Stream)` → `Socket Server` → `Customer App (Listener)` → `Smooth Animation (Interpolation)`
