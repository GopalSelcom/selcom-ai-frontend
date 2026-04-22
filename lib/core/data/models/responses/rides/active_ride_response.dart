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
  Ride? ride;
  SocketRooms? socketRooms;

  Data({this.ride, this.socketRooms});

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    ride: json["ride"] == null ? null : Ride.fromJson(json["ride"]),
    socketRooms: json["socket_rooms"] == null
        ? null
        : SocketRooms.fromJson(json["socket_rooms"]),
  );

  Map<String, dynamic> toJson() => {
    "ride": ride?.toJson(),
    "socket_rooms": socketRooms?.toJson(),
  };
}

class Ride {
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

  Ride({
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
  });

  factory Ride.fromJson(Map<String, dynamic> json) => Ride(
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
    vehicleTypeId: json["vehicle_type_id"],
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
    vehicleYear: json["vehicle_year"],
    verificationCode: json["verification_code"],
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
