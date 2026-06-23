import 'dart:convert';

ActiveRideResponseModel rideModelFromJson(String str) =>
    ActiveRideResponseModel.fromJson(json.decode(str));

String rideModelToJson(ActiveRideResponseModel data) =>
    json.encode(data.toJson());

class ActiveRideResponseModel {
  int? statusCode;
  String? message;
  Data? data;

  ActiveRideResponseModel({this.statusCode, this.message, this.data});

  factory ActiveRideResponseModel.fromJson(Map<String, dynamic> json) =>
      ActiveRideResponseModel(
        statusCode: json["status_code"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
    "status_code": statusCode,
    "message": message,
    "data": data?.toJson(),
  };
}

class Data {
  ActiveRide? ride;
  List<ActiveRideEntry>? rides;
  List<ActiveRide>? additionalRides;
  SocketRooms? socketRooms;
  int? count;
  int? activeRidesCount;
  int? additionalActiveRidesCount;

  Data({
    this.ride,
    this.rides,
    this.additionalRides,
    this.socketRooms,
    this.count,
    this.activeRidesCount,
    this.additionalActiveRidesCount,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    ride: json["ride"] == null ? null : ActiveRide.fromJson(json["ride"]),
    rides: _parseActiveRideEntries(json["rides"]),
    additionalRides: _parseActiveRideList(json["additional_rides"]),
    socketRooms: json["socket_rooms"] == null
        ? null
        : SocketRooms.fromJson(json["socket_rooms"]),
    count: (json["count"] as num?)?.toInt(),
    activeRidesCount: (json["active_rides_count"] as num?)?.toInt(),
    additionalActiveRidesCount:
        (json["additional_active_rides_count"] as num?)?.toInt(),
  );

  static List<ActiveRideEntry>? _parseActiveRideEntries(dynamic raw) {
    if (raw is! List) return null;
    final entries = <ActiveRideEntry>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final nestedRide = map['ride'];
      if (nestedRide is Map) {
        entries.add(
          ActiveRideEntry(
            rideJson: Map<String, dynamic>.from(nestedRide),
            socketRooms: map['socket_rooms'] == null
                ? null
                : SocketRooms.fromJson(
                    Map<String, dynamic>.from(map['socket_rooms'] as Map),
                  ),
          ),
        );
        continue;
      }
      entries.add(
        ActiveRideEntry(
          rideJson: map,
          socketRooms: null,
        ),
      );
    }
    return entries.isEmpty ? null : entries;
  }

  static List<ActiveRide>? _parseActiveRideList(dynamic raw) {
    if (raw is! List) return null;
    return raw
        .whereType<Map>()
        .map((e) => ActiveRide.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Map<String, dynamic> toJson() => {
    "ride": ride?.toJson(),
    "rides": rides?.map((e) => e.toJson()).toList(),
    "additional_rides": additionalRides?.map((e) => e.toJson()).toList(),
    "socket_rooms": socketRooms?.toJson(),
    "count": count,
    "active_rides_count": activeRidesCount,
    "additional_active_rides_count": additionalActiveRidesCount,
  };
}

class ActiveRideEntry {
  /// Full ride map from API — keeps `duration_minutes`, `is_booked_for_other`, etc.
  final Map<String, dynamic> rideJson;
  final SocketRooms? socketRooms;

  ActiveRideEntry({required this.rideJson, this.socketRooms});

  Map<String, dynamic> toJson() => {
    'ride': rideJson,
    if (socketRooms != null) 'socket_rooms': socketRooms!.toJson(),
  };
}

class ActiveRide {
  String? id;
  String? status;
  FareBreakdown? fareBreakdown;
  Destination? pickup;
  Destination? destination;
  int? fareEstimate;
  String? vehicleTypeId;
  String? paymentMethod;
  String? paymentStatus;
  DriverSnapshot? driverSnapshot;
  VehicleSnapshot? vehicleSnapshot;
  String? pinCode;
  String? createdAt;
  bool? isBookedForOther;
  String? passengerName;
  String? passengerPhone;

  ActiveRide({
    this.id,
    this.status,
    this.fareBreakdown,
    this.pickup,
    this.destination,
    this.fareEstimate,
    this.vehicleTypeId,
    this.paymentMethod,
    this.paymentStatus,
    this.driverSnapshot,
    this.vehicleSnapshot,
    this.pinCode,
    this.createdAt,
    this.isBookedForOther,
    this.passengerName,
    this.passengerPhone,
  });

  factory ActiveRide.fromJson(Map<String, dynamic> json) => ActiveRide(
    id: json["_id"],
    status: json["status"],
    fareBreakdown: json["fare_breakdown"] == null
        ? null
        : FareBreakdown.fromJson(json["fare_breakdown"]),
    pickup: json["pickup"] == null
        ? null
        : Destination.fromJson(json["pickup"]),
    destination: json["destination"] == null
        ? null
        : Destination.fromJson(json["destination"]),
    fareEstimate: json["fare_estimate"],
    vehicleTypeId: json["vehicle_type_id"] is Map
        ? json["vehicle_type_id"]["_id"]?.toString()
        : json["vehicle_type_id"]?.toString(),
    paymentMethod: json["payment_method"],
    paymentStatus: json["payment_status"],
    driverSnapshot: json["driver_snapshot"] == null
        ? null
        : DriverSnapshot.fromJson(json["driver_snapshot"]),
    vehicleSnapshot: json["vehicle_snapshot"] == null
        ? null
        : VehicleSnapshot.fromJson(json["vehicle_snapshot"]),
    pinCode: json["pin_code"],
    createdAt: json["created_at"],
    isBookedForOther: json["is_booked_for_other"] == true,
    passengerName: json["passenger_name"]?.toString(),
    passengerPhone: json["passenger_phone"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "_id": id,
    "status": status,
    "fare_breakdown": fareBreakdown?.toJson(),
    "pickup": pickup?.toJson(),
    "destination": destination?.toJson(),
    "fare_estimate": fareEstimate,
    "vehicle_type_id": vehicleTypeId,
    "payment_method": paymentMethod,
    "payment_status": paymentStatus,
    "driver_snapshot": driverSnapshot?.toJson(),
    "vehicle_snapshot": vehicleSnapshot?.toJson(),
    "pin_code": pinCode,
    "created_at": createdAt,
    "is_booked_for_other": isBookedForOther,
    "passenger_name": passengerName,
    "passenger_phone": passengerPhone,
  };
}

class FareBreakdown {
  int? rideCharge;
  int? bookingFee;
  int? totalAmount;

  FareBreakdown({this.rideCharge, this.bookingFee, this.totalAmount});

  factory FareBreakdown.fromJson(Map<String, dynamic> json) => FareBreakdown(
    rideCharge: (json["ride_charge"] as num?)?.toInt(),
    bookingFee: (json["booking_fee"] as num?)?.toInt(),
    totalAmount: (json["total_amount"] as num?)?.toInt(),
  );

  Map<String, dynamic> toJson() => {
    "ride_charge": rideCharge,
    "booking_fee": bookingFee,
    "total_amount": totalAmount,
  };
}

class Destination {
  Location? location;
  double? lat;
  double? lng;
  String? address;

  Destination({this.location, this.lat, this.lng, this.address});

  factory Destination.fromJson(Map<String, dynamic> json) => Destination(
    location: json["location"] == null
        ? null
        : Location.fromJson(json["location"]),
    lat: json["lat"]?.toDouble(),
    lng: json["lng"]?.toDouble(),
    address: json["address"],
  );

  Map<String, dynamic> toJson() => {
    "location": location?.toJson(),
    "lat": lat,
    "lng": lng,
    "address": address,
  };
}

class Location {
  String? type;
  List<double>? coordinates;

  Location({this.type, this.coordinates});

  factory Location.fromJson(Map<String, dynamic> json) => Location(
    type: json["type"],
    coordinates: json["coordinates"] == null
        ? []
        : List<double>.from(json["coordinates"]!.map((x) => x?.toDouble())),
  );

  Map<String, dynamic> toJson() => {
    "type": type,
    "coordinates": coordinates == null
        ? []
        : List<dynamic>.from(coordinates!.map((x) => x)),
  };
}

class DriverSnapshot {
  String? driverId;
  int? fleetId;
  String? name;
  String? phone;
  String? avatarUrl;
  String? vehicleColor;
  String? vehicleModel;
  String? vehicleRegistrationNumber;
  String? vehicleType;
  String? vehicleYear;
  String? verificationCode;
  double? rating;

  DriverSnapshot({
    this.driverId,
    this.fleetId,
    this.name,
    this.phone,
    this.avatarUrl,
    this.vehicleColor,
    this.vehicleModel,
    this.vehicleRegistrationNumber,
    this.vehicleType,
    this.vehicleYear,
    this.verificationCode,
    this.rating,
  });

  factory DriverSnapshot.fromJson(Map<String, dynamic> json) => DriverSnapshot(
    driverId: json["driver_id"],
    fleetId: json["fleet_id"],
    name: json["name"],
    phone: json["phone"],
    avatarUrl: json["avatar_url"],
    vehicleColor: json["vehicle_color"],
    vehicleModel: json["vehicle_model"],
    vehicleRegistrationNumber: json["vehicle_registration_number"],
    vehicleType: json["vehicle_type"],
    vehicleYear: json["vehicle_year"]?.toString(),
    verificationCode: json["verification_code"]?.toString(),
    rating: (json["rating"] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "driver_id": driverId,
    "fleet_id": fleetId,
    "name": name,
    "phone": phone,
    "avatar_url": avatarUrl,
    "vehicle_color": vehicleColor,
    "vehicle_model": vehicleModel,
    "vehicle_registration_number": vehicleRegistrationNumber,
    "vehicle_type": vehicleType,
    "vehicle_year": vehicleYear,
    "verification_code": verificationCode,
    "rating": rating,
  };
}

class VehicleSnapshot {
  String? vehicleType;
  String? vehicleName;
  String? displayName;

  VehicleSnapshot({this.vehicleType, this.vehicleName, this.displayName});

  factory VehicleSnapshot.fromJson(Map<String, dynamic> json) =>
      VehicleSnapshot(
        vehicleType: json["vehicle_type"],
        vehicleName: json["vehicle_name"],
        displayName: json["display_name"],
      );

  Map<String, dynamic> toJson() => {
    "vehicle_type": vehicleType,
    "vehicle_name": vehicleName,
    "display_name": displayName,
  };
}

class SocketRooms {
  String? status;
  String? track;
  String? chat;

  SocketRooms({this.status, this.track, this.chat});

  factory SocketRooms.fromJson(Map<String, dynamic> json) => SocketRooms(
    status: json["status"],
    track: json["track"],
    chat: json["chat"],
  );

  Map<String, dynamic> toJson() => {
    "status": status,
    "track": track,
    "chat": chat,
  };
}
