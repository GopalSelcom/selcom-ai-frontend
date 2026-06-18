import '../../core/data/models/responses/nearbyRiders/response/ride_fare_settled_response.dart';
import '../../shared/widgets/book_any_fare_settled_dialog.dart';
import 'app_dialogs.dart';
import 'currency_formatter.dart';

abstract final class BookAnyFareSettledUi {
  /// One dialog per ride (finding-driver + driver-accepted both listen to the socket).
  static final Set<String> _shownForRideIds = <String>{};

  /// Clears dedupe state (e.g. tests); normal flow shows once per ride.
  static void resetShownState() => _shownForRideIds.clear();

  static void maybeShow({
    required RideFareSettledResponse payload,
    required String rideId,
  }) {
    final normalizedRideId = rideId.trim();
    final payloadRideId = payload.rideId?.trim() ?? '';
    if (normalizedRideId.isEmpty ||
        payloadRideId.isEmpty ||
        payloadRideId != normalizedRideId) {
      return;
    }
    if (!payload.hasReleasedFunds) return;
    if (_shownForRideIds.contains(payloadRideId)) return;

    final released = payload.releasedAmount!;
    final charged = payload.chargedAmount;
    final blocked = payload.blockedAmount;
    if (charged == null && blocked == null) return;

    final currency = payload.currency;
    final blockedText = blocked == null
        ? ''
        : CurrencyFormatter.formatWithApiCurrency(blocked, currency);
    final releasedText = CurrencyFormatter.formatWithApiCurrency(
      released,
      currency,
    );
    final chargedText = charged == null
        ? ''
        : CurrencyFormatter.formatWithApiCurrency(charged, currency);

    if (blockedText.isEmpty && releasedText.isEmpty && chargedText.isEmpty) {
      return;
    }

    _shownForRideIds.add(payloadRideId);
    AppDialogs.showAnimatedDialog(
      child: BookAnyFareSettledDialog(
        blockedText: blockedText,
        releasedText: releasedText,
        chargedText: chargedText,
        vehicleName: payload.displayVehicleLabel,
        onConfirm: AppDialogs.closeActiveDialog,
      ),
    );
  }
}
