import '../../core/data/models/ride_model.dart';
import 'active_rides_parser.dart';

/// Result of `GET go/check-book-mode` when location is available.
enum CheckBookModeGate {
  /// GPS off / denied / API error — distance unknown; skip distance gate.
  unavailable,

  /// `show_book_for_other_option: false` — pickup near rider.
  pickupNearRider,

  /// `show_book_for_other_option: true` — pickup far enough to offer sheet.
  pickupFarFromRider,
}

/// Book-for-other pickup prompt — types and active-ride matrix.
///
/// Full flow diagram and API contracts: `docs/flows/book-for-other-pickup-flow.md`

/// What pickup confirm should do after policy evaluation.
enum BookForOtherPromptAction {
  /// Continue as self ride — no bottom sheet.
  selfOnly,

  /// Choice step with both "For me" and "For someone else".
  showChoiceSheet,

  /// Choice step with only "For someone else" (rider already has a self active ride).
  showOtherOnlySheet,

  /// Self and book-for-other limits are both exhausted.
  blocked,
}

class BookForOtherPromptDecision {
  const BookForOtherPromptDecision({required this.action});

  final BookForOtherPromptAction action;

  static const selfOnly = BookForOtherPromptDecision(
    action: BookForOtherPromptAction.selfOnly,
  );
}

/// Active-ride option matrix — runs when step 2 (self-ride shortcut) did not apply
/// and [CheckBookModeGate.pickupNearRider] did not block the sheet.
///
/// See `docs/flows/book-for-other-pickup-flow.md` for the full diagram.
abstract final class BookForOtherPromptPolicy {
  static BookForOtherPromptDecision evaluate({
    required int maxActiveBookForOther,
    required List<RideModel> activeRides,
  }) {
    final canBookSelf = !hasSelfActiveRide(activeRides);
    final canBookOther =
        countBookedForOtherRides(activeRides) < maxActiveBookForOther;

    if (!canBookSelf && !canBookOther) {
      return const BookForOtherPromptDecision(
        action: BookForOtherPromptAction.blocked,
      );
    }

    if (canBookSelf && canBookOther) {
      return const BookForOtherPromptDecision(
        action: BookForOtherPromptAction.showChoiceSheet,
      );
    }

    if (canBookOther) {
      return const BookForOtherPromptDecision(
        action: BookForOtherPromptAction.showOtherOnlySheet,
      );
    }

    // Only self booking is allowed — skip sheet and book for me directly.
    return BookForOtherPromptDecision.selfOnly;
  }
}
