import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../shared/utils/app_dialogs.dart';
import '../localization/app_strings.dart';
import 'error_reporting/error_reporter.dart';

void devPrint(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

class LocationService extends GetxController {
  static LocationService? _instance;

  LocationService._internal();

  static LocationService get instance {
    _instance ??= LocationService._internal();
    return _instance!;
  }

  bool isDialogOpen = false;

  void checkServiceContinuously() async {
    try {
      _isLocationServiceEnabled.value = await checkLocationService();
      getLocationContinuously();

      Geolocator.getServiceStatusStream().listen((event) {
        developer.log("[location-service] location service: $event");
        if (event == ServiceStatus.disabled) {
          _isLocationServiceEnabled.value = false;
        } else {
          _isLocationServiceEnabled.value = true;
          getLocationContinuously();
        }
      });
    } catch (e, s) {
      developer.log("[location-service] checkServiceContinuously Exception: $e");
      ErrorReporter.instance.report(
        error: e,
        stackTrace: s,
        customMessage: "Exception in checkServiceContinuously",
        extraData: [
          {"isLocationServiceEnabled": _isLocationServiceEnabled.value}
        ],
      );
    }
  }

  final RxBool _isLocationServiceEnabled = false.obs;

  RxBool get isLocationServiceEnabled => _isLocationServiceEnabled;

  bool _isLocationListeningStarted = false;

  bool get isLocationListeningStarted => _isLocationListeningStarted;

  bool _isLocationFirstTimeFetchSuccessfully = false;

  bool get isLocationFirstTimeFetchSuccessfully =>
      _isLocationFirstTimeFetchSuccessfully;

  Future<void> forceLocationService() async {
    var res = await ensureLocationAccess();

    if (!res) {
      await forceLocationService();
      await Future.delayed(const Duration(seconds: 2));
    } else {
      // Completed successfully
    }
  }

  void getLocationContinuously() async {
    try {
      if (isLocationServiceEnabled.value) {
        if (!isLocationFirstTimeFetchSuccessfully) {
          Position? pos = await getCurrentPosition();
          if (pos != null) {
            _position.value = pos;
            _isLocationFirstTimeFetchSuccessfully = true;
          }
        }
        if (!_isLocationListeningStarted) {
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
            ),
          ).listen((position) {
            _isLocationListeningStarted = true;
            _position.value = position;
            _position.refresh();
            developer.log("[location-service] latitude: ${position.latitude}");
            developer.log("[location-service] longitude: ${position.longitude}");
          });
        }
      }
    } catch (e, s) {
      developer.log("[location-service] getLocationContinuously Exception: $e");
      ErrorReporter.instance.report(
        error: e,
        stackTrace: s,
        customMessage: "Exception in getLocationContinuously",
        extraData: [
          {
            "isLocationServiceEnabled": isLocationServiceEnabled.value,
            "isLocationFirstTimeFetchSuccessfully": isLocationFirstTimeFetchSuccessfully,
            "isLocationListeningStarted": isLocationListeningStarted,
          }
        ],
      );
    }
  }

  final Rx<Position> _position = Position(
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
    longitude: 0.0,
    latitude: 0.0,
    timestamp: DateTime.now(),
    accuracy: 0.0,
    altitude: 0.0,
    heading: 0.0,
    speed: 0.0,
    speedAccuracy: 0.0,
  ).obs;

  Rx<Position> get position => _position;

  set setPosition(Position value) {
    _position.value = value;
  }

  Future<bool> checkPermission({
    LocationPermission? permission,
    bool precise = false,
    bool force = false,
    dynamic module,
  }) async {
    try {
      permission ??= await Geolocator.checkPermission();

      // Case: Always or WhileInUse is granted
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        if (precise) {
          LocationAccuracyStatus accuracyStatus =
              await Geolocator.getLocationAccuracy();

          if (accuracyStatus == LocationAccuracyStatus.precise) {
            return true;
          } else {
            if (force) {
              await LocationUtils.giveLocationPermissionDialog(
                precise: precise,
                msg: AppStrings.locationPermissionDeniedOpenSettings.tr,
              );
            }
            return false;
          }
        } else {
          return true;
        }
      }

      // Case: DeniedForever
      if (permission == LocationPermission.deniedForever) {
        if (force) {
          await LocationUtils.giveLocationPermissionDialog(
            precise: precise,
            msg: AppStrings.locationPermissionDeniedOpenSettings.tr,
          );
        }
        return false;
      }

      // Case: Denied
      if (permission == LocationPermission.denied) {
        return false;
      }

      return false;
    } catch (e, s) {
      devPrint("checkPermission Exception: $e");
      ErrorReporter.instance.report(
        error: e,
        stackTrace: s,
        customMessage: "Exception in checkPermission (LocationService)",
        extraData: [
          {"precise": precise},
          {"force": force}
        ],
      );
      return false;
    }
  }

  Future<bool> requestPermission({
    bool force = false,
    bool precise = false,
  }) async {
    try {
      bool permissionStatus = await checkPermission(
        force: false,
        precise: precise,
      );

      if (!permissionStatus) {
        LocationPermission permission = await Geolocator.requestPermission();
        return await checkPermission(
          permission: permission,
          force: force,
          precise: precise,
        );
      } else {
        return true;
      }
    } catch (e, s) {
      devPrint("requestPermission Exception: $e");
      ErrorReporter.instance.report(
        error: e,
        stackTrace: s,
        customMessage: "Exception in requestPermission (LocationService)",
        extraData: [
          {"precise": precise},
          {"force": force}
        ],
      );
      return false;
    }
  }

  Future<bool> checkLocationService({
    bool force = true,
  }) async {
    try {
      var req = await requestPermission(force: true, precise: true);

      if (req == false) {
        return req;
      }

      bool serviceStatus = await Geolocator.isLocationServiceEnabled();

      if (serviceStatus) {
        return true;
      } else {
        if (force) {
          await LocationUtils.enableLocationServicenDialog();
        }
        return false;
      }
    } catch (e, s) {
      devPrint("checkLocationService Exception: $e");
      ErrorReporter.instance.report(
        error: e,
        stackTrace: s,
        customMessage: "Exception in checkLocationService (LocationService)",
        extraData: [
          {"force": force}
        ],
      );
      return false;
    }
  }

  Future<bool> enableLocationService({
    bool force = false,
  }) async {
    try {
      bool serviceStatus = await checkLocationService(
        force: false,
      );

      if (!serviceStatus) {
        try {
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              timeLimit: Duration(seconds: 5),
              accuracy: LocationAccuracy.reduced,
            ),
          );
        } catch (e) {
          devPrint("Geolocator.getCurrentPosition Exception: $e");
        }
        return await checkLocationService(
          force: force,
        );
      } else {
        return true;
      }
    } catch (e, s) {
      devPrint("enableLocationService Exception: $e");
      ErrorReporter.instance.report(
        error: e,
        stackTrace: s,
        customMessage: "Exception in enableLocationService (LocationService)",
        extraData: [
          {"force": force}
        ],
      );
      return false;
    }
  }

  Future<Position?> getCurrentPosition({
    bool force = false,
    bool precise = false,
  }) async {
    try {
      if (force) {
        bool permissionStatus = await requestPermission(
          force: force,
          precise: precise,
        );
        if (permissionStatus) {
          bool serviceStatus = await enableLocationService(
            force: force,
          );
          if (serviceStatus) {
            try {
              return await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  timeLimit: Duration(seconds: 5),
                  accuracy: LocationAccuracy.bestForNavigation,
                ),
              );
            } catch (e) {
              devPrint("Geolocator.getCurrentPosition Exception: $e");
              return await Geolocator.getLastKnownPosition();
            }
          }
        }
      } else {
        bool permissionStatus = await checkPermission(
          force: force,
          precise: precise,
        );
        if (permissionStatus) {
          bool serviceStatus = await checkLocationService(
            force: force,
          );
          if (serviceStatus) {
            try {
              return await Geolocator.getCurrentPosition(
                locationSettings: const LocationSettings(
                  timeLimit: Duration(seconds: 5),
                  accuracy: LocationAccuracy.bestForNavigation,
                ),
              );
            } catch (e) {
              devPrint("Geolocator.getCurrentPosition Exception: $e");
              return await Geolocator.getLastKnownPosition();
            }
          }
        }
      }
      return null;
    } catch (e, s) {
      devPrint("getCurrentPosition Exception: $e");
      ErrorReporter.instance.report(
        error: e,
        stackTrace: s,
        customMessage: "Exception in getCurrentPosition (LocationService)",
        extraData: [
          {"precise": precise},
          {"force": force}
        ],
      );
      return null;
    }
  }

  static bool _isRequesting = false;
  static Completer<bool>? _pendingRequest;

  static Future<bool> ensureLocationAccess() async {
    if (_isRequesting) {
      devPrint("⏳ Location request already running, waiting for result...");
      return _pendingRequest!.future;
    }

    _isRequesting = true;
    _pendingRequest = Completer<bool>();

    try {
      if (Platform.isIOS) {
        bool isServiceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!isServiceEnabled) {
          await handlePermanentlyDenied(
            forLocationService: true,
            msg: "",
            customMsg:
                "Location Services are turned off on your device.\n\nGo to Settings → Privacy & Security → Location Services and turn it on.",
          );
          _pendingRequest!.complete(false);
          return false;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await handlePermanentlyDenied(
          forLocationPermission: true,
          msg: "",
          customMsg: Platform.isIOS
              ? "Location permission is permanently denied.\n\nGo to Settings → Privacy & Security → Location Services → Selcom and select 'While Using the App'."
              : AppStrings.locationPermissionDeniedOpenSettings.tr,
        );
        _pendingRequest!.complete(false);
        return false;
      }

      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
        _pendingRequest!.complete(false);
        return false;
      }

      if (Platform.isIOS) {
        LocationAccuracyStatus accuracyStatus =
            await Geolocator.getLocationAccuracy();
        if (accuracyStatus != LocationAccuracyStatus.precise) {
          await handlePermanentlyDenied(
            forLocationPermission: true,
            msg: "",
            customMsg:
                "Precise location is required.\n\nGo to Settings → Privacy & Security → Location Services → Selcom and enable 'Precise Location'.",
          );
          _pendingRequest!.complete(false);
          return false;
        }
      } else {
        LocationAccuracyStatus accuracyStatus =
            await Geolocator.getLocationAccuracy();
        if (accuracyStatus != LocationAccuracyStatus.precise) {
          await handlePermanentlyDenied(
            forLocationPermission: true,
            msg: "",
            customMsg:
                "Precise location is required for navigation accuracy.",
          );
          _pendingRequest!.complete(false);
          return false;
        }
      }

      if (Platform.isAndroid) {
        bool isLocationEnabled = await Geolocator.isLocationServiceEnabled();
        if (!isLocationEnabled) {
          try {
            await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.reduced,
              ),
            );
          } catch (e) {
            devPrint("Geolocator.getCurrentPosition Exception: $e");
          }
          isLocationEnabled = await Geolocator.isLocationServiceEnabled();
          if (!isLocationEnabled) {
            await handlePermanentlyDenied(
              forLocationService: true,
              msg: "",
              customMsg: "Please enable your location services to get your current location.",
            );
            _pendingRequest!.complete(false);
            return false;
          }
        }
      }

      _pendingRequest!.complete(true);
      return true;
    } catch (e, s) {
      devPrint("Error ensuring location access: $e");
      ErrorReporter.instance.report(
        error: e,
        stackTrace: s,
        customMessage: "Error ensuring location access (LocationService)",
        extraData: [
          {"isRequesting": _isRequesting}
        ],
      );
      _pendingRequest!.complete(false);
      return false;
    } finally {
      _isRequesting = false;
    }
  }

  static Future<void> handlePermanentlyDenied({
    bool forLocationPermission = false,
    bool forLocationService = false,
    String msg = "",
    String customMsg = "",
  }) async {
    if (forLocationPermission) {
      await LocationUtils.giveLocationPermissionDialog(
        msg: customMsg,
      );
    } else if (forLocationService) {
      await LocationUtils.enableLocationServicenDialog();
    }
  }

  Future<Map<String, String>> getCurrentLocationAsStrings() async {
    try {
      if (_position.value.latitude != 0.0 && _position.value.longitude != 0.0) {
        return {
          'latitude': _position.value.latitude.toString(),
          'longitude': _position.value.longitude.toString(),
        };
      }

      Position? position = await getCurrentPosition(force: false);

      if (position != null && position.latitude != 0.0 && position.longitude != 0.0) {
        return {
          'latitude': position.latitude.toString(),
          'longitude': position.longitude.toString(),
        };
      }

      devPrint("[location-service] Unable to get current location, returning 0.0");
      return {
        'latitude': '0.0',
        'longitude': '0.0',
      };
    } catch (e, s) {
      devPrint("[location-service] getCurrentLocationAsStrings Exception: $e");
      ErrorReporter.instance.report(
        error: e,
        stackTrace: s,
        customMessage: "Exception in getCurrentLocationAsStrings",
        extraData: [
          {
            "latitude": _position.value.latitude,
            "longitude": _position.value.longitude,
          }
        ],
      );
      return {
        'latitude': '0.0',
        'longitude': '0.0',
      };
    }
  }
}

class LocationUtils {
  static Future<void> giveLocationPermissionDialog({
    dynamic module,
    bool precise = false,
    String msg = "",
  }) async {
    if (!LocationService.instance.isDialogOpen) {
      LocationService.instance.isDialogOpen = true;

      final title = AppStrings.locationAccessRequired.tr;
      final message = msg.isNotEmpty
          ? msg
          : (precise
              ? "Precise location is required to request a ride. Please enable it in Settings."
              : AppStrings.locationPermissionDeniedOpenSettings.tr);

      await AppDialogs.showPermissionDialog(
        title: title,
        message: message,
        onOpenSettings: () async {
          await Geolocator.openAppSettings();
        },
        icon: Icons.location_off_outlined,
        secondaryIcon: Icons.location_on_outlined,
      );

      LocationService.instance.isDialogOpen = false;
    }
  }

  static Future<void> enableLocationServicenDialog() async {
    if (!LocationService.instance.isDialogOpen) {
      LocationService.instance.isDialogOpen = true;

      final Completer<void> completer = Completer<void>();

      AppDialogs.showConfirmationDialog(
        title: AppStrings.enableLocationService.tr,
        message: "Please enable your location service to get your current location.",
        confirmText: "Open Settings",
        cancelText: "Cancel",
        onConfirm: () async {
          await Geolocator.openLocationSettings();
          if (!completer.isCompleted) completer.complete();
        },
        onCancel: () {
          if (!completer.isCompleted) completer.complete();
        },
      );

      await completer.future;
      LocationService.instance.isDialogOpen = false;
    }
  }
}
