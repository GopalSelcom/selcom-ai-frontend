import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

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

/// App-wide Socket.IO service.
///
/// Covers events from socket collection:
/// - Pre-booking nearby drivers (`go:nearby_drivers*`)
/// - Ride tracking (`join_ride_room`, `ride:status_update`, `ride:driver_location`)
/// - Payment status (`join_payment_room`, `payment:status_update`)
class AppSocketService {
  static const String defaultBaseUrl = 'http://82.112.227.6:5010';

  static const String evtNearbyDrivers = 'go:nearby_drivers';
  static const String evtNearbyDriversResult = 'go:nearby_drivers:result';
  static const String evtNearbyDriversError = 'go:nearby_drivers:error';

  static const String evtJoinRideRoom = 'join_ride_room';
  static const String evtRideStatusUpdate = 'ride:status_update';
  static const String evtRideDriverLocation = 'ride:driver_location';

  static const String evtJoinPaymentRoom = 'join_payment_room';
  static const String evtPaymentStatusUpdate = 'payment:status_update';

  io.Socket? _socket;
  final _driversController = StreamController<List<NearbyDriverPoint>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();
  final _rideStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _rideDriverLocationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _paymentStatusController =
      StreamController<Map<String, dynamic>>.broadcast();

  AppSocketService({this.baseUrl = defaultBaseUrl});

  final String baseUrl;

  Stream<List<NearbyDriverPoint>> get nearbyDriversStream => _driversController.stream;
  Stream<String> get errorStream => _errorController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get rideStatusStream => _rideStatusController.stream;
  Stream<Map<String, dynamic>> get rideDriverLocationStream =>
      _rideDriverLocationController.stream;
  Stream<Map<String, dynamic>> get paymentStatusStream =>
      _paymentStatusController.stream;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    if (_socket?.connected == true) return;



    final storage = StorageService();
    final token = (await storage.read(StorageKeys.accessToken)) ??
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
        debugPrint("socket => socketId: ${_socket?.id}");
        debugPrint("socket => event: $event");
        debugPrint("socket => data: ${json.encode(data)}");
      });
    }
    _socket!.onConnect((data) {
      debugPrint("onConnect init function: ${json.encode(data)}");
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
    _socket!.on(evtNearbyDriversResult, (payload) {
      final drivers = _parseDrivers(payload);
      _driversController.add(drivers);
    });
    _socket!.on(evtNearbyDriversError, (payload) {
      _errorController.add(_parseError(payload));
    });
    _socket!.on(evtRideStatusUpdate, (payload) {
      final data = _asMap(payload);
      if (data != null) _rideStatusController.add(data);
    });
    _socket!.on(evtRideDriverLocation, (payload) {
      final data = _asMap(payload);
      if (data != null) _rideDriverLocationController.add(data);
    });
    _socket!.on(evtPaymentStatusUpdate, (payload) {
      final data = _asMap(payload);
      if (data != null) _paymentStatusController.add(data);
    });

    _socket!.connect();
  }

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
    try{
      _socket!.emit(evtJoinPaymentRoom, {'validation_id': validationId});
    }catch(e){
      print("this is the error ----->$e");
    }
  }

  void emitEvent(String event, [dynamic payload]) {
    if (_socket?.connected != true) {
      _errorController.add('Socket not connected');
      return;
    }
    _socket!.emit(event, payload);
  }

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
    _rideDriverLocationController.close();
    _paymentStatusController.close();
  }

  List<NearbyDriverPoint> _parseDrivers(dynamic payload) {
    final list = (payload is Map && payload['drivers'] is List)
        ? payload['drivers'] as List
        : const [];
    final out = <NearbyDriverPoint>[];
    for (final item in list) {
      if (item is! Map) continue;
      final lat = (item['lat'] as num?)?.toDouble();
      final lng = (item['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      out.add(
        NearbyDriverPoint(
          fleetId: (item['fleet_id'] ?? '').toString(),
          lat: lat,
          lng: lng,
          vehicleType: item['vehicle_type']?.toString(),
          distanceKm: (item['distance_km'] as num?)?.toDouble(),
        ),
      );
    }
    return out;
  }

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
