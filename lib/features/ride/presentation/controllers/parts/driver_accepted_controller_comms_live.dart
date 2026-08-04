part of '../driver_accepted_controller.dart';

/// Rider-driver comms and Live Activity: call, chat, dialer, lock-screen sync.
class DriverAcceptedCommsLiveHelper {
  DriverAcceptedCommsLiveHelper(this.c);

  /// Parent [DriverAcceptedController] — shared ride state and lifecycle.
  final DriverAcceptedController c;

  /// Places an in-app voice call to the assigned driver using the Agora
  /// calling package. Falls back to the system phone dialer when the package
  /// flow isn't available (no Agora App ID, ride id missing, etc.).
  Future<void> callDriver() async {
    final id = c.rideId;
    if (id.isEmpty) {
      return;
    }
    RideDriverCallOptionsSheet.show(
      rideId: id,
      peerDisplayName: c.driverName.value,
      driverPhone: c.driverPhone.value,
      peerAvatarUrl: c.driverAvatarUrl.value.trim().isEmpty
          ? null
          : c.driverAvatarUrl.value,
    );
  }

  /// Opens the OS phone app with [phone] (`tel:`). [errorDialogTitle] uses API `label` for emergency rows.
  Future<void> _launchSystemPhoneDialer({
    required String phone,
    required String errorDialogTitle,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) {
      AppDialogs.showErrorDialog(
        title: errorDialogTitle,
        message: AppStrings.phoneNumberUnavailable.tr,
      );
      return;
    }
    final uri = Uri(scheme: 'tel', path: cleanPhone);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(uri);
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.e(
        'Error launching dialer',
        tag: 'DriverAcceptedController',
        error: e,
      );
      AppDialogs.showErrorDialog(
        title: errorDialogTitle,
        message: AppStrings.errorOpeningPhoneDialer.tr,
      );
    }
  }

  /// Opens in-ride chat and clears the unread badge.
  void onChatTap() {
    c.unreadCount.value = 0;
    Get.toNamed(
      AppRoutes.rideMessage,
      arguments: {
        'rideId': c.rideId,
        'driverName': c.driverName.value,
        'driverPhone': c.driverPhone.value,
        'driverSubtitle': c.plateDisplayFormatted.value,
        'riderName': 'Rider', // Default placeholder
        'initialStatus': c.mapHelper._mapBottomSheetToRideStatus(
          c.rideBottomSheetState.value,
        ).name,
      },
    );
  }

  /// Starts or updates Live Activity from a status-update payload.
  Future<void> _syncLiveActivityFromStatusPayload(
    EventRiderStatusUpdateResponse payload,
  ) async {
    try {
      final status = (payload.status ?? '').toString().trim().toUpperCase();
      if (status.isEmpty) return;

      // Terminal: tear down Lock Screen / Dynamic Island immediately.
      if (status.contains('CANCELLED') || status.contains('NO_DRIVER_FOUND')) {
        await LiveActivityManager().endActivity(c.rideId);
        return;
      }

      // Hybrid Live Activity updates (iOS):
      // - Local ActivityKit update here so the widget tracks app status without
      //   waiting for backend → APNs latency.
      // - APNs push-token updates remain for when the app is backgrounded/killed.
      // startActivity(..., updateIfExists: true) creates or updates ContentState.
      final r = c.ride.value;
      final driver = payload.driverSnapshot;
      final vehicle = payload.vehicleSnapshot;
      final plateFromPayload = (driver?.vehicleRegistrationNumber ?? '').trim();
      final rawPlate = plateFromPayload.isNotEmpty
          ? plateFromPayload
          : (r != null ? _rawPlateStringFromRide(r) : '');
      final liveDriverName =
          (driver?.name ?? r?.driverSnapshot?.name ?? '').trim();
      final vehicleName =
          '${vehicle?.displayName ?? vehicle?.vehicleName ?? vehicle?.vehicleType ?? r?.vehicleSnapshot?.vehicleType ?? ''} ${driver?.vehicleModel ?? r?.vehicleSnapshot?.vehicleModel ?? ''}'
              .trim();
      final avatarUrl =
          (driver?.avatarUrl ?? r?.driverSnapshot?.avatarUrl ?? '').trim();
      final etaFromPayload = (payload.etaSeconds ?? 0).toDouble();
      final etaSeconds = etaFromPayload > 0
          ? etaFromPayload
          : c.currentEtaSeconds.value;

      final normalizedForLive = normalizeRideStatusString(payload.status);
      await LiveActivityManager().startActivity(
        orderId: c.rideId,
        status: status,
        driverName: liveDriverName.isNotEmpty ? liveDriverName : 'Driver Assigned',
        vehicleName: vehicleName,
        driverAvatarUrl: avatarUrl,
        plateNumber: TanzaniaLicensePlateFormatter.formatDisplay(rawPlate),
        isCompleted:
            normalizedForLive == 'ride_completed' ||
            normalizedForLive == 'completed',
        etaSeconds: etaSeconds,
        driverLatitude: driver?.lat ?? c.assignedDriverLocation.value?.latitude,
        driverLongitude: driver?.lng ?? c.assignedDriverLocation.value?.longitude,
        updateIfExists: true,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.d(
        "❌ Error in DriverAcceptedController._syncLiveActivityFromStatusPayload: $e",
        tag: 'ORDER_TRACKING',
      );
    }
  }

  /// Pushes ETA/location into Live Activity from tracking sockets (throttled).
  /// Keeps the widget ETA closer to the in-app chip without relying only on APNs.
  Future<void> _syncLiveActivityFromTrackingPayload(
    TrackingUpdateSocketResponse payload,
  ) async {
    try {
      if (!LiveActivityManager().isTracking(c.rideId)) return;

      final statusRaw = (payload.status ?? c.currentRideStatus.value)
          .toString()
          .trim();
      if (statusRaw.isEmpty) return;
      final status = statusRaw
          .replaceAllMapped(
            RegExp(r'([a-z0-9])([A-Z])'),
            (m) => '${m.group(1)}_${m.group(2)}',
          )
          .toUpperCase()
          .replaceAll(' ', '_');

      final eta = (payload.eta ?? 0).toDouble();
      final normalizedForLive = normalizeRideStatusString(statusRaw);
      await LiveActivityManager().updateActivity(
        orderId: c.rideId,
        status: status,
        etaSeconds: eta > 0 ? eta : c.currentEtaSeconds.value,
        driverLatitude: c.assignedDriverLocation.value?.latitude,
        driverLongitude: c.assignedDriverLocation.value?.longitude,
        isCompleted:
            normalizedForLive == 'ride_completed' ||
            normalizedForLive == 'completed',
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
    }
  }

  /// Prefer vehicle snapshot plate; else driver snapshot registration (same sources as UI).
  String _rawPlateStringFromRide(RideModel r) {
    final snap = r.vehicleSnapshot;
    if (snap != null) {
      final p = snap.plateNumber.trim();
      if (p.isNotEmpty) return snap.plateNumber;
    }
    final d = r.driverSnapshot;
    if (d != null) {
      return (d.vehicleRegistrationNumber ?? '').trim();
    }
    return '';
  }

  /// Starts or refreshes Live Activity from HTTP ride details / bootstrap.
  Future<void> _syncLiveActivityFromDetails(RideModel r) async {
    try {
      if (c.rideId.isEmpty) return;

      // Create or refresh Live Activity from ride details (HTTP / bootstrap).
      // Uses updateIfExists so iOS ContentState stays aligned with the app.
      final statusStr = r.status.name
          .replaceAllMapped(
            RegExp(r'([a-z0-9])([A-Z])'),
            (m) => '${m.group(1)}_${m.group(2)}',
          )
          .toUpperCase();

      final rawPlate = _rawPlateStringFromRide(r);

      await LiveActivityManager().startActivity(
        orderId: c.rideId,
        status: statusStr,
        driverName: r.driverSnapshot?.name ?? 'Driver Assigned',
        vehicleName:
            '${r.vehicleSnapshot?.vehicleType ?? ''} ${r.vehicleSnapshot?.vehicleModel ?? ''}'
                .trim(),
        driverAvatarUrl: r.driverSnapshot?.avatarUrl ?? '',
        plateNumber: TanzaniaLicensePlateFormatter.formatDisplay(rawPlate),
        isCompleted: r.status == RideStatus.rideCompleted,
        etaSeconds: c.currentEtaSeconds.value,
        driverLatitude: c.assignedDriverLocation.value?.latitude,
        driverLongitude: c.assignedDriverLocation.value?.longitude,
        updateIfExists: true,
      );
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.e(
        'Error syncing Live Activity from Details',
        tag: 'DriverAcceptedController',
        error: e,
      );
    }
  }
}
