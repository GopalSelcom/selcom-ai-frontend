import '../../core/data/models/mid_ride_cancel_model.dart';
import '../../core/data/models/ride_model.dart';
import '../../features/ride/presentation/utils/mid_ride_driver_cancelled_flow.dart';

/// True when the ride payload includes a driver mid-ride cancellation block.
bool rideHasMidRideDriverCancel(RideModel ride) {
  return ride.midRideCancel?.isDriverMidRideCancel == true;
}

/// Live charge UI — scheduled capture window.
bool rideNeedsMidRideCancelScreen(RideModel ride) {
  final block = ride.midRideCancel;
  if (block == null) return false;
  return block.needsLiveChargeScreen;
}

/// Shows the themed mid-ride driver cancellation dialog.
Future<void> showMidRideDriverCancelledDialog({
  required String rideId,
  required MidRideCancelModel cancel,
  bool navigateHomeOnDismiss = true,
}) {
  return MidRideDriverCancelledFlow.show(
    rideId: rideId,
    cancel: cancel,
    navigateHomeOnDismiss: navigateHomeOnDismiss,
  );
}
