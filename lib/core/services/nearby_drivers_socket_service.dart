import 'dart:async';
import 'dart:convert';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../features/ride/data/models/mid_ride_cancel_models.dart';
import '../config/app_config.dart';
import '../utils/app_logger.dart';
import '../data/models/responses/nearbyRiders/response/driver_location_socker_response.dart';
import '../data/models/responses/nearbyRiders/response/near_by_rider_response.dart';
import '../data/models/responses/nearbyRiders/response/ride_fare_settled_response.dart';
import '../data/models/responses/nearbyRiders/response/ride_stops_update_response.dart';
import '../data/models/responses/nearbyRiders/response/rider_status_update_response.dart';
import '../data/models/responses/nearbyRiders/response/tracking_update_socket_response.dart';
import '../data/models/responses/payment_status_response/payment_status_response.dart';
import 'error_reporting/error_reporter.dart';
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
  static final AppSocketService _instance = AppSocketService._internal();

  factory AppSocketService() => _instance;

  AppSocketService._internal();

  // ---------------- EVENTS ----------------

  // Nearby drivers
  static const String evtNearbyDrivers = 'go:nearby_drivers';
  static const String evtNearbyDriversResult = 'go:nearby_drivers:result';
  static const String evtNearbyDriversError = 'go:nearby_drivers:error';

  // Ride
  static const String evtJoinRideRoom = 'join_ride_room';
  static const String evtLeaveRideRoom = 'leave_ride_room';
  static const String evtRideStatusUpdate = 'ride:status_update';
  static const String evtRideStopUpdate = 'ride:stop_update';
  static const String evtRideStopsUpdated = 'ride:stops_updated';
  static const String evtRideStopsUpdateFailed = 'ride:stops_update_failed';
  static const String evtRideDriverLocation = 'ride:driver_location';
  static const String evtRideFareSettled = 'ride:fare_settled';
  static const String evtRideDriverCancelled = 'ride:driver_cancelled';
  static const String evtRideChargeSettled = 'ride:charge_settled';
  static const String evtRideChargeDisputed = 'ride:charge_disputed';
  static const String trackingDriverLocation = 'ride:tracking_update';

  // Payment
  static const String evtJoinPaymentRoom = 'join_payment_room';
  static const String evtPaymentStatusUpdate = 'payment:status_update';

  // 💬 Chat
  static const String evtSendMessage = 'chat:send_message';
  static const String evtReceiveMessage = 'ride:new_message';

  io.Socket? _socket;
  Timer? _reconnectTimer;
  bool _manualDisconnect = false;
  bool _isConnecting = false;
  int _reconnectAttempt = 0;
  String? _joinedRideRoomId;
  static const int _maxReconnectAttempts = 12;
  final _driversController = StreamController<List<Driver>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  final _rideStatusController =
      StreamController<EventRiderStatusUpdateResponse>.broadcast();
  final _rideDriverLocationController =
      StreamController<DriverLocationSocketResponse>.broadcast();
  final _rideStopUpdateController =
      StreamController<EventRiderStatusUpdateResponse>.broadcast();
  final _rideStopsUpdatedController =
      StreamController<RideStopsUpdatedResponse>.broadcast();
  final _rideStopsUpdateFailedController =
      StreamController<RideStopsUpdateFailedResponse>.broadcast();
  final _paymentStatusController =
      StreamController<PaymentStatusUpdateResponse>.broadcast();
  final _trackingUpdateStatusController =
      StreamController<TrackingUpdateSocketResponse?>.broadcast();
  final _fareSettledController =
      StreamController<RideFareSettledResponse>.broadcast();
  final _driverCancelledController =
      StreamController<RideDriverCancelledPayload>.broadcast();
  final _chargeSettledController =
      StreamController<RideChargeSettledPayload>.broadcast();
  final _chargeDisputedController =
      StreamController<RideChargeDisputedPayload>.broadcast();

  // 💬 Chat controller
  final _chatController = StreamController<Map<String, dynamic>>.broadcast();

  String get baseUrl => AppConfig.socketBaseUrl;

  Stream<List<Driver>> get nearbyDriversStream => _driversController.stream;

  Stream<String> get errorStream => _errorController.stream;

  Stream<bool> get connectionStream => _connectionController.stream;

  Stream<EventRiderStatusUpdateResponse> get rideStatusStream =>
      _rideStatusController.stream;

  Stream<TrackingUpdateSocketResponse?> get trackingUpdateStatusStream =>
      _trackingUpdateStatusController.stream;

  Stream<RideFareSettledResponse> get rideFareSettledStream =>
      _fareSettledController.stream;

  Stream<RideDriverCancelledPayload> get rideDriverCancelledStream =>
      _driverCancelledController.stream;

  Stream<RideChargeSettledPayload> get rideChargeSettledStream =>
      _chargeSettledController.stream;

  Stream<RideChargeDisputedPayload> get rideChargeDisputedStream =>
      _chargeDisputedController.stream;

  Stream<DriverLocationSocketResponse> get rideDriverLocationStream =>
      _rideDriverLocationController.stream;

  Stream<EventRiderStatusUpdateResponse> get rideStopUpdateStream =>
      _rideStopUpdateController.stream;

  Stream<RideStopsUpdatedResponse> get rideStopsUpdatedStream =>
      _rideStopsUpdatedController.stream;

  Stream<RideStopsUpdateFailedResponse> get rideStopsUpdateFailedStream =>
      _rideStopsUpdateFailedController.stream;

  Stream<PaymentStatusUpdateResponse> get paymentStatusStream =>
      _paymentStatusController.stream;

  // 💬 Chat stream
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;

  bool get isConnected => _socket?.connected == true;

  /// Ride room currently joined via [switchRideRoom] / [joinRideRoom].
  String? get joinedRideRoomId => _joinedRideRoomId;

  // ---------------- CONNECT ----------------

  Future<void> connect() async {
    if (_socket?.connected == true || _isConnecting) return;
    _manualDisconnect = false;
    _isConnecting = true;

    final storage = StorageService();
    final token = (await storage.readAccessToken()) ?? '';

    _socket?.dispose();

    _socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .setPath('/go-socket.io')
          .setReconnectionAttempts(_maxReconnectAttempts)
          .setReconnectionDelay(1000)
          .setTimeout(12000)
          .setQuery({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );
    AppLogger.d('SOCKET URL ----->  $baseUrl', tag: 'Socket');

    if (AppLogger.enabled) {
      _socket?.onAny((event, data) {
        AppLogger.d('socket => event: $event', tag: 'Socket');
      });
    }
    _socket!.onConnect((data) {
      AppLogger.d('Socket connected', tag: 'Socket');
      AppLogger.d('Connected socketId: ${_socket?.id}', tag: 'Socket');
      _isConnecting = false;
      _reconnectAttempt = 0;
      _cancelReconnectTimer();

      _rejoinRideRoomIfNeeded();
      _connectionController.add(true);
    });
    _socket!.onDisconnect((data) {
      AppLogger.d('Socket disconnected: $data', tag: 'Socket');
      _isConnecting = false;
      _connectionController.add(false);
      _scheduleReconnect(reason: 'disconnect:$data');
    });
    _socket!.onConnectError((err) {
      AppLogger.w('onConnectError init function: $err', tag: 'Socket');
      _isConnecting = false;
      _connectionController.add(false);
      _errorController.add(err?.toString() ?? 'Socket connection error');
      _scheduleReconnect(reason: 'connect_error:$err');
    });
    _socket!.onError((err) {
      _errorController.add(err?.toString() ?? 'Socket error');
      _scheduleReconnect(reason: 'socket_error:$err');
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
      AppLogger.d('evtRideStatusUpdate -> $payload', tag: 'Socket');
      final data = eventRiderStatusUpdateResponseFromJson(jsonEncode(payload));

      if (data != null) _rideStatusController.add(data);
    });
    _socket!.on(evtRideStopUpdate, (payload) {
      AppLogger.d('evtRideStopUpdate -> $payload', tag: 'Socket');
      final data = eventRiderStatusUpdateResponseFromJson(jsonEncode(payload));
      if (data != null) _rideStopUpdateController.add(data);
    });
    _socket!.on(evtRideStopsUpdated, (payload) {
      AppLogger.d('evtRideStopsUpdated -> $payload', tag: 'Socket');
      final data = RideStopsUpdatedResponse.fromJson(
        payload as Map<String, dynamic>,
      );
      _rideStopsUpdatedController.add(data);
    });
    _socket!.on(evtRideStopsUpdateFailed, (payload) {
      AppLogger.d('evtRideStopsUpdateFailed -> $payload', tag: 'Socket');
      final data = RideStopsUpdateFailedResponse.fromJson(
        payload as Map<String, dynamic>,
      );
      _rideStopsUpdateFailedController.add(data);
    });
    _socket!.on(trackingDriverLocation, (payload) {
      AppLogger.d(
        'trackingDriverLocation -> ${jsonEncode(payload)}',
        tag: 'Socket',
      );
      final data = trackingUpdateSocketResponseFromJson(jsonEncode(payload));
      if (data != null) {
        _trackingUpdateStatusController.add(data);
      }
    });
    _socket!.on(evtRideDriverLocation, (payload) {
      AppLogger.d(
        'evtRideDriverLocation -> ${jsonEncode(payload)}',
        tag: 'Socket',
      );
      final data = driverLocationSocketResponseFromJson(jsonEncode(payload));
      _rideDriverLocationController.add(data);
    });
    _socket!.on(evtRideFareSettled, (payload) {
      if (payload is! Map) return;
      final data = RideFareSettledResponse.fromJson(
        Map<String, dynamic>.from(payload),
      );
      _fareSettledController.add(data);
    });
    _socket!.on(evtRideDriverCancelled, (payload) {
      if (payload is! Map) return;
      _driverCancelledController.add(
        RideDriverCancelledPayload.fromJson(Map<String, dynamic>.from(payload)),
      );
    });
    _socket!.on(evtRideChargeSettled, (payload) {
      if (payload is! Map) return;
      _chargeSettledController.add(
        RideChargeSettledPayload.fromJson(Map<String, dynamic>.from(payload)),
      );
    });
    _socket!.on(evtRideChargeDisputed, (payload) {
      if (payload is! Map) return;
      _chargeDisputedController.add(
        RideChargeDisputedPayload.fromJson(Map<String, dynamic>.from(payload)),
      );
    });
    _socket!.on(evtPaymentStatusUpdate, (payload) {
      final data = PaymentStatusUpdateResponse.fromJson(
        payload as Map<String, dynamic>,
      );
      _paymentStatusController.add(data);
    });

    // 💬 CHAT LISTENER
    _socket!.on(evtReceiveMessage, (payload) {
      AppLogger.d('evtReceiveMessage -> $payload', tag: 'Socket');
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
    AppLogger.d(
      'requested nearby drivers with configured radius',
      tag: 'Socket',
    );
    if (vehicleType != null && vehicleType.trim().isNotEmpty) {
      body['vehicle_type'] = vehicleType;
    }
    _socket!.emit(evtNearbyDrivers, body);
  }

  /// Joins [rideId]'s room, leaving any previously joined ride room first.
  void switchRideRoom({required String rideId}) {
    final id = rideId.trim();
    if (id.isEmpty) return;

    if (_joinedRideRoomId != null &&
        _joinedRideRoomId != id &&
        _joinedRideRoomId!.isNotEmpty) {
      _emitLeaveRideRoom(_joinedRideRoomId!);
    }

    _joinedRideRoomId = id;
    _emitJoinRideRoom(id);
  }

  /// Leaves [rideId]'s socket room (no-op when socket is disconnected).
  void leaveRideRoom({required String rideId}) {
    final id = rideId.trim();
    if (id.isEmpty) return;
    _emitLeaveRideRoom(id);
    if (_joinedRideRoomId == id) {
      _joinedRideRoomId = null;
    }
  }

  /// Leaves whichever ride room is currently tracked, if any.
  void leaveJoinedRideRoom() {
    final id = _joinedRideRoomId;
    if (id == null || id.isEmpty) return;
    leaveRideRoom(rideId: id);
  }

  void joinRideRoom({required String rideId}) => switchRideRoom(rideId: rideId);

  void _emitJoinRideRoom(String rideId) {
    if (_socket?.connected != true) return;
    _socket!.emit(evtJoinRideRoom, {'ride_id': rideId});
  }

  void _emitLeaveRideRoom(String rideId) {
    if (_socket?.connected != true) return;
    _socket!.emit(evtLeaveRideRoom, {'ride_id': rideId});
  }

  void _rejoinRideRoomIfNeeded() {
    final id = _joinedRideRoomId?.trim();
    if (id == null || id.isEmpty) return;
    _emitJoinRideRoom(id);
  }

  void joinPaymentRoom({required String validationId}) {
    if (_socket?.connected != true) {
      _errorController.add('Socket not connected');
      return;
    }
    try {
      _socket!.emit(evtJoinPaymentRoom, {'validation_id': validationId});
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(error: e, stackTrace: stackTrace);
      AppLogger.e('joinPaymentRoom failed', tag: 'Socket', error: e);
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
    _manualDisconnect = true;
    _isConnecting = false;
    _cancelReconnectTimer();
    leaveJoinedRideRoom();
    _socket?.disconnect();
  }

  void dispose() {
    // For a singleton, we might not want to close streams until the app dies,
    // but we can provide a method to clear things if needed.
    _manualDisconnect = true;
    _isConnecting = false;
    _cancelReconnectTimer();
    // _socket?.dispose();
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

  void _scheduleReconnect({required String reason}) {
    if (_manualDisconnect || _socket?.connected == true) return;
    if (_reconnectAttempt >= _maxReconnectAttempts) {
      _errorController.add(
        'Socket reconnect failed after $_maxReconnectAttempts attempts.',
      );
      return;
    }
    if (_reconnectTimer?.isActive == true) return;

    final delaySeconds = (1 << _reconnectAttempt).clamp(1, 20);
    _reconnectAttempt += 1;
    AppLogger.d(
      'Socket reconnect scheduled in ${delaySeconds}s '
      '(attempt $_reconnectAttempt/$_maxReconnectAttempts, reason=$reason)',
      tag: 'Socket',
    );
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (_manualDisconnect || _socket?.connected == true) return;
      await connect();
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
}
