class RideStopLimits {
  RideStopLimits._();

  /// Total destination points allowed in route flow.
  /// Includes final destination as one point.
  ///
  /// Example:
  /// - 3 => 2 intermediate stops + 1 final destination
  /// - 4 => 3 intermediate stops + 1 final destination
  static const int maxDestinationPoints = 3;

  /// Intermediate stops only (excludes final destination).
  static const int maxIntermediateStops = maxDestinationPoints - 1;
}
