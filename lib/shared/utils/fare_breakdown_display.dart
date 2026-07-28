import 'package:get/get.dart';

import '../../core/data/models/fare_stop_charge.dart';
import '../../core/localization/app_strings.dart';
import 'currency_formatter.dart';

/// Formatted row for in-app fare cards (title + currency label).
class FareBreakdownDisplayRow {
  final String title;
  final String amountLabel;

  const FareBreakdownDisplayRow({
    required this.title,
    required this.amountLabel,
  });
}

/// Unformatted component line (title + raw amount) for receipt PNG/PDF.
class FareBreakdownComponentLine {
  final String title;
  final int amount;

  const FareBreakdownComponentLine({
    required this.title,
    required this.amount,
  });
}

/// Shared itemized fare lines for mid-ride, ride details, and receipt download.
///
/// API reconciliation (additive; nothing silently folded into another field):
/// - `ride_charge` = distance + time + Σ(stop_charges) + minimum_fare_adjustment
/// - `total_amount` = base_fare + ride_charge − promo_discount (instant discount)
/// - cashback: full fare charged; `cashback_amount` refunded separately at capture
///
/// Render order: Base → Distance → Time → each stop → min-fare top-up (if > 0).
/// Promo / payment mode / total are composed by the caller.
///
/// Prefer `stop_charges` over legacy `waypoint_charge`. Do not infer stop fees
/// by diffing `waypoint_charge`. `stop_added_charge` is mid-ride incremental only.
abstract final class FareBreakdownDisplay {
  FareBreakdownDisplay._();

  /// Raw component lines (caller formats currency — receipt uses API currency).
  static List<FareBreakdownComponentLine> itemizedComponentLines({
    required int baseFare,
    required int distanceCharge,
    required int timeCharge,
    required List<FareStopCharge> stopCharges,
    required int minimumFareAdjustment,
  }) {
    final lines = <FareBreakdownComponentLine>[
      FareBreakdownComponentLine(
        title: AppStrings.baseFare.tr,
        amount: baseFare,
      ),
      FareBreakdownComponentLine(
        title: AppStrings.distanceCharge.tr,
        amount: distanceCharge,
      ),
      FareBreakdownComponentLine(
        title: AppStrings.timeCharge.tr,
        amount: timeCharge,
      ),
    ];

    // One row per stop from API `stop_charges` (all stops, not only mid-ride adds).
    for (final stop in stopCharges) {
      final title = stop.label.isNotEmpty
          ? stop.label
          : AppStrings.stopNumberLabel.trParams({
              'number': '${stop.stopNumber}',
            });
      lines.add(
        FareBreakdownComponentLine(title: title, amount: stop.amount),
      );
    }

    // Only when the minimum-fare floor actually applied.
    if (minimumFareAdjustment > 0) {
      lines.add(
        FareBreakdownComponentLine(
          title: AppStrings.minimumFareTopUp.tr,
          amount: minimumFareAdjustment,
        ),
      );
    }

    return lines;
  }

  /// Formatted rows for in-app fare cards (region display currency by default).
  static List<FareBreakdownDisplayRow> itemizedComponentRows({
    required int baseFare,
    required int distanceCharge,
    required int timeCharge,
    required List<FareStopCharge> stopCharges,
    required int minimumFareAdjustment,
    String? apiCurrency,
  }) {
    return itemizedComponentLines(
      baseFare: baseFare,
      distanceCharge: distanceCharge,
      timeCharge: timeCharge,
      stopCharges: stopCharges,
      minimumFareAdjustment: minimumFareAdjustment,
    ).map((line) {
      final label = apiCurrency == null
          ? CurrencyFormatter.format(line.amount)
          : CurrencyFormatter.formatWithApiCurrency(line.amount, apiCurrency);
      return FareBreakdownDisplayRow(title: line.title, amountLabel: label);
    }).toList(growable: false);
  }

  /// True when component fields are present so we can skip legacy Ride Charge
  /// + Booking Fee summary (e.g. seed maps from book that only have totals).
  static bool hasItemizedComponents({
    required int baseFare,
    required int distanceCharge,
    required int timeCharge,
    required List<FareStopCharge> stopCharges,
    required int minimumFareAdjustment,
  }) {
    return baseFare > 0 ||
        distanceCharge > 0 ||
        timeCharge > 0 ||
        stopCharges.isNotEmpty ||
        minimumFareAdjustment > 0;
  }
}
