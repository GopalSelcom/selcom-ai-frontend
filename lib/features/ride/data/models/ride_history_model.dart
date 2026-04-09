import '../../domain/entities/ride_history_entity.dart';

class RideHistoryModel extends RideHistoryEntity {
  RideHistoryModel({
    required super.id,
    required super.startLocation,
    required super.startAddress,
    required super.endLocation,
    required super.endAddress,
    required super.dateTime,
    required super.paymentMethod,
    required super.status,
    required super.price,
    required super.vehicleType,
    required super.vehicleImage,
    required super.rideCharge,
    required super.bookingFee,
    super.rating,
  });

  factory RideHistoryModel.fromJson(Map<String, dynamic> json) {
    return RideHistoryModel(
      id: json['id'] ?? '',
      startLocation: json['startLocation'] ?? '',
      startAddress: json['startAddress'] ?? '',
      endLocation: json['endLocation'] ?? '',
      endAddress: json['endAddress'] ?? '',
      dateTime: json['dateTime'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? '',
      price: json['price'] ?? '',
      vehicleType: json['vehicleType'] ?? 'Boda',
      vehicleImage: json['vehicleImage'] ?? '',
      rideCharge: json['rideCharge'] ?? 'TZS 0.00',
      bookingFee: json['bookingFee'] ?? 'TZS 0.00',
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }
}
