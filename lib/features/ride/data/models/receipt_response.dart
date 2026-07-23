import 'dart:convert';

import '../../../../core/constants/currency_code.dart';
import '../../../../core/data/models/ride_model.dart';

/// Envelope for `GET go/rides/{id}/receipt` (from `model/model.dart`).
class ReceiptResponse {
  int? statusCode;
  ReceiptData? data;

  ReceiptResponse({this.statusCode, this.data});

  factory ReceiptResponse.fromJson(String str) =>
      ReceiptResponse.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ReceiptResponse.fromMap(Map<String, dynamic> json) => ReceiptResponse(
    statusCode: json["status_code"],
    data: json["data"] == null ? null : ReceiptData.fromMap(json["data"]),
  );

  Map<String, dynamic> toMap() => {
    "status_code": statusCode,
    "data": data?.toMap(),
  };
}

class ReceiptData {
  RideReceipt? receipt;

  ReceiptData({this.receipt});

  factory ReceiptData.fromJson(String str) =>
      ReceiptData.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ReceiptData.fromMap(Map<String, dynamic> json) => ReceiptData(
    receipt: json["receipt"] == null
        ? null
        : RideReceipt.fromMap(json["receipt"]),
  );

  Map<String, dynamic> toMap() => {"receipt": receipt?.toMap()};
}

class RideReceipt {
  String? rideId;
  String? status;
  ReceiptPickup? pickup;
  ReceiptPlace? destination;
  List<ReceiptPlace>? stops;
  bool? isMultiStop;
  double? distanceKm;
  int? durationMinutes;
  ReceiptFareBreakdown? fareBreakdown;
  String? paymentMethod;
  String? paymentStatus;
  ReceiptDriverSnapshot? driverSnapshot;
  ReceiptVehicleSnapshot? vehicleSnapshot;
  String? completedAt;

  RideReceipt({
    this.rideId,
    this.status,
    this.pickup,
    this.destination,
    this.stops,
    this.isMultiStop,
    this.distanceKm,
    this.durationMinutes,
    this.fareBreakdown,
    this.paymentMethod,
    this.paymentStatus,
    this.driverSnapshot,
    this.vehicleSnapshot,
    this.completedAt,
  });

  factory RideReceipt.fromJson(String str) =>
      RideReceipt.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RideReceipt.fromMap(Map<String, dynamic> json) => RideReceipt(
    rideId: json["ride_id"],
    status: json["status"],
    pickup: json["pickup"] == null
        ? null
        : ReceiptPickup.fromMap(json["pickup"]),
    destination: json["destination"] == null
        ? null
        : ReceiptPlace.fromMap(json["destination"]),
    stops: json["stops"] == null
        ? []
        : List<ReceiptPlace>.from(
            json["stops"]!.map((x) => ReceiptPlace.fromMap(x)),
          ),
    isMultiStop: json["is_multi_stop"],
    distanceKm: json["distance_km"]?.toDouble(),
    durationMinutes: json["duration_minutes"],
    fareBreakdown: json["fare_breakdown"] == null
        ? null
        : ReceiptFareBreakdown.fromMap(json["fare_breakdown"]),
    paymentMethod: json["payment_method"],
    paymentStatus: json["payment_status"],
    driverSnapshot: json["driver_snapshot"] == null
        ? null
        : ReceiptDriverSnapshot.fromMap(json["driver_snapshot"]),
    vehicleSnapshot: json["vehicle_snapshot"] == null
        ? null
        : ReceiptVehicleSnapshot.fromMap(json["vehicle_snapshot"]),
    completedAt: json["completed_at"],
  );

  Map<String, dynamic> toMap() => {
    "ride_id": rideId,
    "status": status,
    "pickup": pickup?.toMap(),
    "destination": destination?.toMap(),
    "stops": stops == null
        ? []
        : List<dynamic>.from(stops!.map((x) => x.toMap())),
    "is_multi_stop": isMultiStop,
    "distance_km": distanceKm,
    "duration_minutes": durationMinutes,
    "fare_breakdown": fareBreakdown?.toMap(),
    "payment_method": paymentMethod,
    "payment_status": paymentStatus,
    "driver_snapshot": driverSnapshot?.toMap(),
    "vehicle_snapshot": vehicleSnapshot?.toMap(),
    "completed_at": completedAt,
  };
}

class ReceiptPlace {
  ReceiptLocation? location;
  int? index;
  String? status;
  String? subtaskId;
  String? arrivedAt;
  String? completedAt;
  double? lat;
  double? lng;
  String? address;

  ReceiptPlace({
    this.location,
    this.index,
    this.status,
    this.subtaskId,
    this.arrivedAt,
    this.completedAt,
    this.lat,
    this.lng,
    this.address,
  });

  factory ReceiptPlace.fromJson(String str) =>
      ReceiptPlace.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ReceiptPlace.fromMap(Map<String, dynamic> json) => ReceiptPlace(
    location: json["location"] == null
        ? null
        : ReceiptLocation.fromMap(json["location"]),
    index: json["index"],
    status: json["status"],
    subtaskId: json["subtask_id"],
    arrivedAt: json["arrived_at"]?.toString(),
    completedAt: json["completed_at"]?.toString(),
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    address: json["address"],
  );

  Map<String, dynamic> toMap() => {
    "location": location?.toMap(),
    "index": index,
    "status": status,
    "subtask_id": subtaskId,
    "arrived_at": arrivedAt,
    "completed_at": completedAt,
    "lat": lat,
    "lng": lng,
    "address": address,
  };
}

class ReceiptLocation {
  String? type;
  List<double>? coordinates;

  ReceiptLocation({this.type, this.coordinates});

  factory ReceiptLocation.fromJson(String str) =>
      ReceiptLocation.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ReceiptLocation.fromMap(Map<String, dynamic> json) => ReceiptLocation(
    type: json["type"],
    coordinates: json["coordinates"] == null
        ? []
        : List<double>.from(
            json["coordinates"]!.map((x) => x?.toDouble()),
          ),
  );

  Map<String, dynamic> toMap() => {
    "type": type,
    "coordinates": coordinates == null
        ? []
        : List<dynamic>.from(coordinates!.map((x) => x)),
  };
}

class ReceiptPickup {
  ReceiptLocation? location;
  double? lat;
  double? lng;
  String? address;

  ReceiptPickup({this.location, this.lat, this.lng, this.address});

  factory ReceiptPickup.fromJson(String str) =>
      ReceiptPickup.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ReceiptPickup.fromMap(Map<String, dynamic> json) => ReceiptPickup(
    location: json["location"] == null
        ? null
        : ReceiptLocation.fromMap(json["location"]),
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    address: json["address"],
  );

  Map<String, dynamic> toMap() => {
    "location": location?.toMap(),
    "lat": lat,
    "lng": lng,
    "address": address,
  };
}

class ReceiptDriverSnapshot {
  String? driverId;
  int? fleetId;
  String? name;
  String? accountNo;
  String? phone;
  String? email;
  String? licenseNumber;
  String? licenseCategory;
  String? avatarUrl;
  String? vehicleColor;
  String? vehicleModel;
  String? vehicleRegistrationNumber;
  String? vehicleChassisNumber;
  String? vehicleType;
  String? vehicleYear;
  int? rating;

  ReceiptDriverSnapshot({
    this.driverId,
    this.fleetId,
    this.name,
    this.accountNo,
    this.phone,
    this.email,
    this.licenseNumber,
    this.licenseCategory,
    this.avatarUrl,
    this.vehicleColor,
    this.vehicleModel,
    this.vehicleRegistrationNumber,
    this.vehicleChassisNumber,
    this.vehicleType,
    this.vehicleYear,
    this.rating,
  });

  factory ReceiptDriverSnapshot.fromJson(String str) =>
      ReceiptDriverSnapshot.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ReceiptDriverSnapshot.fromMap(Map<String, dynamic> json) =>
      ReceiptDriverSnapshot(
        driverId: json["driver_id"],
        fleetId: json["fleet_id"],
        name: json["name"],
        accountNo: json["account_no"],
        phone: json["phone"],
        email: json["email"],
        licenseNumber: json["license_number"]?.toString(),
        licenseCategory: json["license_category"]?.toString(),
        avatarUrl: json["avatar_url"],
        vehicleColor: json["vehicle_color"],
        vehicleModel: json["vehicle_model"],
        vehicleRegistrationNumber: json["vehicle_registration_number"],
        vehicleChassisNumber: json["vehicle_chassis_number"]?.toString(),
        vehicleType: json["vehicle_type"],
        vehicleYear: json["vehicle_year"],
        rating: json["rating"],
      );

  Map<String, dynamic> toMap() => {
    "driver_id": driverId,
    "fleet_id": fleetId,
    "name": name,
    "account_no": accountNo,
    "phone": phone,
    "email": email,
    "license_number": licenseNumber,
    "license_category": licenseCategory,
    "avatar_url": avatarUrl,
    "vehicle_color": vehicleColor,
    "vehicle_model": vehicleModel,
    "vehicle_registration_number": vehicleRegistrationNumber,
    "vehicle_chassis_number": vehicleChassisNumber,
    "vehicle_type": vehicleType,
    "vehicle_year": vehicleYear,
    "rating": rating,
  };
}

class ReceiptFareBreakdown {
  int? baseFare;
  int? distanceCharge;
  int? timeCharge;
  String? promoCode;
  int? promoDiscount;
  bool? promoAutoApplied;
  int? totalFare;
  int? bookingFee;
  int? totalAmount;
  String? currency;

  ReceiptFareBreakdown({
    this.baseFare,
    this.distanceCharge,
    this.timeCharge,
    this.promoCode,
    this.promoDiscount,
    this.promoAutoApplied,
    this.totalFare,
    this.bookingFee,
    this.totalAmount,
    this.currency,
  });

  factory ReceiptFareBreakdown.fromJson(String str) =>
      ReceiptFareBreakdown.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ReceiptFareBreakdown.fromMap(Map<String, dynamic> json) =>
      ReceiptFareBreakdown(
        baseFare: json["base_fare"],
        distanceCharge: json["distance_charge"],
        timeCharge: json["time_charge"],
        promoCode: json["promo_code"]?.toString(),
        promoDiscount: json["promo_discount"],
        promoAutoApplied: json["promo_auto_applied"],
        totalFare: json["total_fare"],
        bookingFee: json["booking_fee"],
        totalAmount: json["total_amount"],
        currency: json["currency"],
      );

  Map<String, dynamic> toMap() => {
    "base_fare": baseFare,
    "distance_charge": distanceCharge,
    "time_charge": timeCharge,
    "promo_code": promoCode,
    "promo_discount": promoDiscount,
    "promo_auto_applied": promoAutoApplied,
    "total_fare": totalFare,
    "booking_fee": bookingFee,
    "total_amount": totalAmount,
    "currency": currency,
  };
}

class ReceiptVehicleSnapshot {
  String? vehicleType;
  String? vehicleName;
  String? displayName;

  ReceiptVehicleSnapshot({
    this.vehicleType,
    this.vehicleName,
    this.displayName,
  });

  factory ReceiptVehicleSnapshot.fromJson(String str) =>
      ReceiptVehicleSnapshot.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ReceiptVehicleSnapshot.fromMap(Map<String, dynamic> json) =>
      ReceiptVehicleSnapshot(
        vehicleType: json["vehicle_type"],
        vehicleName: json["vehicle_name"],
        displayName: json["display_name"],
      );

  Map<String, dynamic> toMap() => {
    "vehicle_type": vehicleType,
    "vehicle_name": vehicleName,
    "display_name": displayName,
  };
}

/// Flattened receipt for PDF / image / UI (mapped from [RideReceipt]).
class ReceiptModel {
  final String rideId;
  final String transactionId;
  final int baseFare;
  final int distanceCharge;
  final int timeCharge;
  final int total;
  final int discount;
  final int tax;
  final String currency;
  final String paymentMethod;
  final String? completedAt;
  final String? promoCode;
  final int promoDiscountAmount;
  final String? driverName;
  final String? vehicleModel;
  final String? vehicleColor;
  final String? vehicleRegistration;
  final String? vehicleType;
  final double distanceKm;
  final int durationMinutes;
  final String pickupAddress;
  final String destinationAddress;
  final bool isMultiStop;
  final List<RideStopModel> stops;
  final int totalFare;
  final int bookingFee;
  final int totalAmount;

  ReceiptModel({
    required this.rideId,
    this.transactionId = '',
    required this.baseFare,
    required this.distanceCharge,
    required this.timeCharge,
    required this.total,
    this.discount = 0,
    this.tax = 0,
    required this.currency,
    required this.paymentMethod,
    this.completedAt,
    this.promoCode,
    this.promoDiscountAmount = 0,
    this.driverName,
    this.vehicleModel,
    this.vehicleColor,
    this.vehicleRegistration,
    this.vehicleType,
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.pickupAddress = '',
    this.destinationAddress = '',
    this.isMultiStop = false,
    this.stops = const [],
    this.totalFare = 0,
    this.bookingFee = 0,
    this.totalAmount = 0,
  });

  ReceiptModel copyWith({String? transactionId}) {
    return ReceiptModel(
      rideId: rideId,
      transactionId: transactionId ?? this.transactionId,
      baseFare: baseFare,
      distanceCharge: distanceCharge,
      timeCharge: timeCharge,
      total: total,
      discount: discount,
      tax: tax,
      currency: currency,
      paymentMethod: paymentMethod,
      completedAt: completedAt,
      promoCode: promoCode,
      promoDiscountAmount: promoDiscountAmount,
      driverName: driverName,
      vehicleModel: vehicleModel,
      vehicleColor: vehicleColor,
      vehicleRegistration: vehicleRegistration,
      vehicleType: vehicleType,
      distanceKm: distanceKm,
      durationMinutes: durationMinutes,
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      isMultiStop: isMultiStop,
      stops: stops,
      totalFare: totalFare,
      bookingFee: bookingFee,
      totalAmount: totalAmount,
    );
  }

  factory ReceiptModel.fromRideReceipt(RideReceipt receipt) {
    final fare = receipt.fareBreakdown;
    final driver = receipt.driverSnapshot;
    final vehicle = receipt.vehicleSnapshot;
    final baseFare = fare?.baseFare ?? 0;
    final distanceCharge = fare?.distanceCharge ?? 0;
    final timeCharge = fare?.timeCharge ?? 0;
    final totalFare = fare?.totalFare ?? (baseFare + distanceCharge + timeCharge);
    final bookingFee = fare?.bookingFee ?? 0;
    final totalAmount = fare?.totalAmount ?? (totalFare + bookingFee);
    final promoCode = fare?.promoCode?.trim();

    final stops = (receipt.stops ?? const <ReceiptPlace>[])
        .map(
          (s) => RideStopModel(
            index: s.index ?? 0,
            address: s.address ?? '',
            lat: s.lat ?? 0,
            lng: s.lng ?? 0,
            status: s.status ?? 'pending',
          ),
        )
        .toList();

    return ReceiptModel(
      rideId: receipt.rideId ?? '',
      baseFare: baseFare,
      distanceCharge: distanceCharge,
      timeCharge: timeCharge,
      total: totalAmount,
      currency: fare?.currency ?? CurrencyCode.tzs,
      promoCode: (promoCode == null || promoCode.isEmpty || promoCode == 'null')
          ? null
          : promoCode,
      promoDiscountAmount: fare?.promoDiscount ?? 0,
      paymentMethod: receipt.paymentMethod ?? '',
      completedAt: receipt.completedAt,
      driverName: driver?.name,
      vehicleModel: driver?.vehicleModel,
      vehicleColor: driver?.vehicleColor,
      vehicleRegistration: driver?.vehicleRegistrationNumber,
      vehicleType:
          driver?.vehicleType ?? vehicle?.displayName ?? vehicle?.vehicleType,
      distanceKm: receipt.distanceKm ?? 0,
      durationMinutes: receipt.durationMinutes ?? 0,
      pickupAddress: receipt.pickup?.address ?? '',
      destinationAddress: receipt.destination?.address ?? '',
      isMultiStop: receipt.isMultiStop ?? false,
      stops: stops,
      totalFare: totalFare,
      bookingFee: bookingFee,
      totalAmount: totalAmount,
    );
  }

  factory ReceiptModel.empty({required String rideId}) => ReceiptModel(
    rideId: rideId,
    baseFare: 0,
    distanceCharge: 0,
    timeCharge: 0,
    total: 0,
    currency: CurrencyCode.tzs,
    paymentMethod: '',
  );
}
