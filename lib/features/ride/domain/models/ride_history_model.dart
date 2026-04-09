class RideHistoryModel {
  final String id;
  final String startLocation;
  final String startAddress;
  final String endLocation;
  final String endAddress;
  final String dateTime;
  final String paymentMethod;
  final String status;
  final String price;
  final String vehicleType;
  final String vehicleImage;
  final String rideCharge;
  final String bookingFee;
  final double? rating;

  RideHistoryModel({
    required this.id,
    required this.startLocation,
    required this.startAddress,
    required this.endLocation,
    required this.endAddress,
    required this.dateTime,
    required this.paymentMethod,
    required this.status,
    required this.price,
    this.vehicleType = 'Boda',
    this.vehicleImage = '',
    this.rideCharge = 'TZS 0.00',
    this.bookingFee = 'TZS 0.00',
    this.rating,
  });
}
