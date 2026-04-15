import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:selcom_rides_frontend/core/data/models/responses/nearbyRiders/response/driver_location_socker_response.dart';
import 'package:selcom_rides_frontend/core/data/models/responses/nearbyRiders/response/rider_status_update_response.dart';
import 'package:selcom_rides_frontend/core/data/models/responses/nearbyRiders/response/tracking_update_socket_response.dart';
import 'package:selcom_rides_frontend/core/data/models/responses/payment_status_response/payment_status_response.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../data/models/responses/nearbyRiders/response/near_by_rider_response.dart';
import 'storage_service.dart';

class NearbyDriverPoint {
  final String fleetId;
  final double lat;
  final double lng;
  final String? vehicleType;
  final double? distanceKm;

  const NearbyDriverPoint({
    required this.fleetId,
    required this.lat,
    required this.lng,
    this.vehicleType,
    this.distanceKm,
  });
}

///
/// App-wide Socket.IO service.
///
/// Covers events from socket collection:
/// - Pre-booking nearby drivers (`go:nearby_drivers*`)
/// - Ride tracking (`join_ride_room`, `ride:status_update`, `ride:driver_location`)
/// - Payment status (`join_payment_room`, `payment:status_update`)
class AppSocketService {
  static const String defaultBaseUrl = 'http://82.112.227.6:5010';

  // ---------------- EVENTS ----------------

  // Nearby drivers
  static const String evtNearbyDrivers = 'go:nearby_drivers';
  static const String evtNearbyDriversResult = 'go:nearby_drivers:result';
  static const String evtNearbyDriversError = 'go:nearby_drivers:error';

  // Ride
  static const String evtJoinRideRoom = 'join_ride_room';
  static const String evtRideStatusUpdate = 'ride:status_update';
  static const String evtRideDriverLocation = 'ride:driver_location';
  static const String trackingDriverLocation = 'ride:tracking_update';

  // Payment
  static const String evtJoinPaymentRoom = 'join_payment_room';
  static const String evtPaymentStatusUpdate = 'payment:status_update';

  // 💬 Chat
  static const String evtSendMessage = 'chat:send_message';
  static const String evtReceiveMessage = 'ride:new_message';

  io.Socket? _socket;
  final _driversController = StreamController<List<Driver>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  final _rideStatusController =
      StreamController<EventRiderStatusUpdateResponse>.broadcast();
  final _rideDriverLocationController =
      StreamController<DriverLocationSocketResponse>.broadcast();
  final _paymentStatusController =
      StreamController<PaymentStatusUpdateResponse>.broadcast();
  final _trackingUpdateStatusController =
  StreamController<TrackingUpdateSocketResponse?>.broadcast();

  // 💬 Chat controller
  final _chatController = StreamController<Map<String, dynamic>>.broadcast();

  AppSocketService({this.baseUrl = defaultBaseUrl});

  final String baseUrl;

  Stream<List<Driver>> get nearbyDriversStream => _driversController.stream;
  Stream<String> get errorStream => _errorController.stream;

  Stream<bool> get connectionStream => _connectionController.stream;

  Stream<EventRiderStatusUpdateResponse> get rideStatusStream =>
      _rideStatusController.stream;

  Stream<TrackingUpdateSocketResponse?> get trackingUpdateStatusStream =>
      _trackingUpdateStatusController.stream;


  Stream<DriverLocationSocketResponse> get rideDriverLocationStream =>
      _rideDriverLocationController.stream;
  Stream<PaymentStatusUpdateResponse> get paymentStatusStream =>
      _paymentStatusController.stream;

  // 💬 Chat stream
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;

  bool get isConnected => _socket?.connected == true;

  // ---------------- CONNECT ----------------

  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final storage = StorageService();
    final token =
        (await storage.read(StorageKeys.accessToken)) ??
        (await storage.read(StorageKeys.authorizationToken)) ??
        '';

    _socket?.dispose();

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(800)
          .setTimeout(12000)
          .setQuery({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );
    debugPrint("SOCKET URL ----->  $baseUrl");

    if (kDebugMode) {
      _socket?.onAny((event, data) {
        debugPrint("socket => event: $event");
      });
    }
    _socket!.onConnect((data) {
      debugPrint("Socket connected");
      debugPrint("Connected socketId: ${_socket?.id}");

      _connectionController.add(true);
    });
    _socket!.onDisconnect((data) {
      debugPrint("Socket disconnected: $data");
      _connectionController.add(false);
    });
    _socket!.onConnectError((err) {
      debugPrint("onConnectError init function: $err");
      _connectionController.add(false);
      _errorController.add(err?.toString() ?? 'Socket connection error');
    });
    _socket!.onError((err) {
      _errorController.add(err?.toString() ?? 'Socket error');
    });

    // ---------------- LISTENERS ----------------

    _socket!.on(evtNearbyDriversResult, (payload) {
      final drivers = ridersResponseSocketFromJson(jsonEncode(payload));
      _driversController.add(drivers.drivers ?? []);
    });
    _socket!.on(evtNearbyDriversError, (payload) {
      _errorController.add(_parseError(payload));
    });
    _socket!.on(evtRideStatusUpdate, (payload) {
      print("this is the evtRideStatusUpdate----->$payload");
      final data = eventRiderStatusUpdateResponseFromJson(jsonEncode(payload));

      if (data != null) _rideStatusController.add(data);
    });
    _socket!.on(trackingDriverLocation, (payload){
      print("this is the call back ---driver_location:->${jsonEncode(payload)}");
      final data = trackingUpdateSocketResponseFromJson(jsonEncode(payload));
      if(data != null){
        _trackingUpdateStatusController.add(trackingUpdateSocketResponseFromJson(jsonEncode(payload)));
      }

    });
    _socket!.on(evtRideDriverLocation, (payload) {
      print("this is the evtRideDriverLocation---->${jsonEncode(payload)}");
      final data = driverLocationSocketResponseFromJson(jsonEncode(payload));
      _rideDriverLocationController.add(data);
    });
    _socket!.on(evtPaymentStatusUpdate, (payload) {
      final data = PaymentStatusUpdateResponse.fromJson(
        payload as Map<String, dynamic>,
      );
      _paymentStatusController.add(data);
    });

    // 💬 CHAT LISTENER
    _socket!.on(evtReceiveMessage, (payload) {
      print("this is payLoad --->evtReceiveMessage---->$payload");
      final data = _asMap(payload);
      if (data != null) _chatController.add(data);
    });

    _socket!.connect();
  }

  // ---------------- EMIT METHODS ----------------

  void requestNearbyDrivers({
    required double lat,
    required double lng,
    String? vehicleType,
    int radiusKm = 3,
  }) {
    if (_socket?.connected != true) {
      _errorController.add('Socket not connected');
      return;
    }
    final body = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
    };
    if (kDebugMode) {
      debugPrint('requested nearby drivers with configured radius');
    }
    if (vehicleType != null && vehicleType.trim().isNotEmpty) {
      body['vehicle_type'] = vehicleType;
    }
    _socket!.emit(evtNearbyDrivers, body);
  }

  void joinRideRoom({required String rideId}) {
    if (_socket?.connected != true) {
      _errorController.add('Socket not connected');
      return;
    }
    _socket!.emit(evtJoinRideRoom, {'ride_id': rideId});
  }

  void joinPaymentRoom({required String validationId}) {
    if (_socket?.connected != true) {
      _errorController.add('Socket not connected');
      return;
    }
    try {
      _socket!.emit(evtJoinPaymentRoom, {'validation_id': validationId});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('joinPaymentRoom failed');
      }
    }
  }

  // 💬 SEND MESSAGE
  void sendMessage({required String rideId, required String message}) {
    if (!isConnected) {
      _errorController.add('Socket not connected');
      return;
    }

    _socket!.emit(evtSendMessage, {'ride_id': rideId, 'message': message});
  }

  void emitEvent(String event, [dynamic payload]) {
    if (_socket?.connected != true) {
      _errorController.add('Socket not connected');
      return;
    }
    _socket!.emit(event, payload);
  }

  // ---------------- DISCONNECT ----------------

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _driversController.close();
    _errorController.close();
    _connectionController.close();
    _rideStatusController.close();
    _trackingUpdateStatusController.close();
    _rideDriverLocationController.close();
    _paymentStatusController.close();
    _chatController.close();
  }

  // ---------------- HELPERS ----------------

  String _parseError(dynamic payload) {
    if (payload is Map) {
      final message = payload['message']?.toString();
      final code = payload['code']?.toString();
      if (message != null && message.isNotEmpty) return message;
      if (code != null && code.isNotEmpty) return code;
    }
    return 'Nearby driver request failed';
  }

  Map<String, dynamic>? _asMap(dynamic payload) {
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return null;
  }
}
