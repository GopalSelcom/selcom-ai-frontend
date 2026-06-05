import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../shared/utils/app_dialogs.dart';
import '../funcations/log.dart';
import '../localization/app_strings.dart';
import 'error_reporting/error_reporter.dart';

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
      await checkLocationService();

      if (!isLocationServiceStatusStreamStarted) {
        Geolocator.getServiceStatusStream().listen((event) {
          devLog("[LocationService] location service: $event");
          if (event == ServiceStatus.disabled) {
            _isLocationServiceEnabled(false);
            _isLocationListeningStarted = false;
          } else {
            _isLocationServiceEnabled(true);
            getLocationContinuously();
          }
        });
        _isLocationServiceStatusStreamStarted = true;
      }
    } catch (e, stacktrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stacktrace,
        customMessage: "LocationService.checkServiceContinuously failed",
      );

      devLog(
        "[LocationService] checkServiceContinuously Exception: $e",
        error: e,
        stackTrace: stacktrace,
      );
    }
  }

  bool _isLocationServiceStatusStreamStarted = false;

  bool get isLocationServiceStatusStreamStarted =>
      _isLocationServiceStatusStreamStarted;

  RxBool _isLocationServiceEnabled = false.obs;

  RxBool get isLocationServiceEnabled => _isLocationServiceEnabled;

  bool _isLocationListeningStarted = false;

  bool get isLocationListeningStarted => _isLocationListeningStarted;

  bool _isLocationFirstTimeFetchSuccessfully = false;

  bool get isLocationFirstTimeFetchSuccessfully =>
      _isLocationFirstTimeFetchSuccessfully;

  RxBool _isLocationPermissionEnabled = false.obs;

  RxBool get isLocationPermissionEnabled => _isLocationPermissionEnabled;

  bool get isPositionAvailable =>
      position.value.latitude != 0 || position.value.longitude != 0;

  void getLocationContinuously() async {
    try {
      if (isLocationServiceEnabled.value) {
        if (!isLocationFirstTimeFetchSuccessfully && !isPositionAvailable) {
          _isLocationFirstTimeFetchSuccessfully = true;
          if (!isLocationPermissionEnabled.value) {
            await checkPermission();
          }

          if (isLocationPermissionEnabled.value) {
            await getCurrentPosition();
          } else {
            _isLocationFirstTimeFetchSuccessfully = false;
          }
        }
        if (!isLocationListeningStarted) {
          if (!isLocationPermissionEnabled.value) {
            await checkPermission();
          }

          if (isLocationPermissionEnabled.value) {
            try {
              Geolocator.getPositionStream(
                locationSettings: LocationSettings(
                  accuracy: LocationAccuracy.medium,
                ),
              ).listen(
                (position) {
                  _position.value = position;
                  _position.refresh();
                  devLog("[LocationService] latitude: ${position.latitude}");
                  devLog("[LocationService] longitude: ${position.longitude}");
                },
                cancelOnError: true,
                onError: (error) {
                  devLog("onError Geolocator.getPositionStream: $error");
                  _isLocationListeningStarted = false;
                },
              );
            } on LocationServiceDisabledException catch (e, stacktrace) {
              ErrorReporter.instance.report(
                error: e,
                stackTrace: stacktrace,
                customMessage: "Location: getPositionStream - Service Disabled",
              );
              devLog(
                "[LocationService] Geolocator.getPositionStream Exception: $e",
                error: e,
                stackTrace: stacktrace,
              );
            }
            _isLocationListeningStarted = true;
          }
        }
      }
    } catch (e, stacktrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stacktrace,
        customMessage: "LocationService.getLocationContinuously failed",
      );

      devLog(
        "[LocationService] getLocationContinuously Exception: $e",
        error: e,
        stackTrace: stacktrace,
      );
    }
  }

  Rx<Position> _position = Position(
    altitudeAccuracy: 0.0,
    headingAccuracy: 0.0,
    longitude: 0.0,
    latitude: 0.0,
    timestamp: DateTime.now(),
    accuracy: 0,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
  ).obs;

  Rx<Position> get position => _position;

  set setPosition(Position value) {
    _position.value = value;
  }

  Future<bool> checkPermission({
    LocationPermission? permission,
    bool precise = false,
    bool dontGetLocationContinuously = false,
    bool force = false,
  }) async {
    try {
      if (permission == null) {
        permission = await Geolocator.checkPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        if (precise) {
          if (dontGetLocationContinuously) {
            _isLocationPermissionEnabled(true);
            return true;
          }
          LocationAccuracyStatus accuracyStatus =
              await Geolocator.getLocationAccuracy();

          if (accuracyStatus == LocationAccuracyStatus.precise) {
            _isLocationPermissionEnabled(true);
            getLocationContinuously();
            return true;
          } else {
            if (force) {
              await LocationUtils.giveLocationPermissionDialog(
                precise: precise,
              );
            }
            isLocationPermissionEnabled(false);
            return false;
          }
        } else {
          _isLocationPermissionEnabled(true);
          getLocationContinuously();
          return true;
        }
      } else {
        if (permission == LocationPermission.deniedForever) {
          if (force) {
            await LocationUtils.giveLocationPermissionDialog(precise: precise);
          }
        }
        isLocationPermissionEnabled(false);
        return false;
      }
    } catch (e, stacktrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stacktrace,
        customMessage: "LocationService.checkPermission failed",
      );

      devLog(
        "[LocationService] checkPermission Exception: $e",
        error: e,
        stackTrace: stacktrace,
      );
      isLocationPermissionEnabled(false);
      return false;
    }
  }

  Future<bool> requestPermission({
    bool force = false,
    bool precise = false,
    bool dontGetLocationContinuously = false,
  }) async {
    try {
      bool permissionStatus = await checkPermission(
        force: false,
        precise: precise,
        dontGetLocationContinuously: dontGetLocationContinuously,
      );

      if (!permissionStatus) {
        LocationPermission permission = await Geolocator.requestPermission();
        return await checkPermission(
          permission: permission,
          force: force,
          precise: precise,
          dontGetLocationContinuously: dontGetLocationContinuously,
        );
      } else {
        _isLocationPermissionEnabled(true);
        return true;
      }
    } catch (e, stacktrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stacktrace,
        customMessage: "LocationService.requestPermission failed",
      );

      devLog(
        "[LocationService] requestPermission Exception: $e",
        error: e,
        stackTrace: stacktrace,
      );
      isLocationPermissionEnabled(false);
      return false;
    }
  }

  Future<bool> checkLocationService({bool force = false}) async {
    try {
      bool serviceStatus = await Geolocator.isLocationServiceEnabled();

      if (serviceStatus) {
        _isLocationServiceEnabled(true);
        return true;
      } else {
        _isLocationServiceEnabled(false);
        return false;
      }
    } catch (e, stacktrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stacktrace,
        customMessage: "LocationService.checkLocationService failed",
      );

      devLog(
        "[LocationService] checkLocationService Exception: $e",
        error: e,
        stackTrace: stacktrace,
      );
      _isLocationServiceEnabled(false);
      return false;
    }
  }

  Future<bool> enableLocationService({bool force = false}) async {
    try {
      /// false put on purpose
      bool serviceStatus = await checkLocationService(force: false);

      if (!serviceStatus) {
        if (force) {
          await LocationUtils.enableLocationServicenDialog();
        }
        _isLocationServiceEnabled(false);
        return false;
      } else {
        _isLocationServiceEnabled(true);
        return true;
      }
    } catch (e, stacktrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stacktrace,
        customMessage: "LocationService.enableLocationService failed",
      );

      devLog(
        "[LocationService] enableLocationService Exception: $e",
        error: e,
        stackTrace: stacktrace,
      );
      _isLocationServiceEnabled(false);
      return false;
    }
  }

  Future<Position?> getCurrentPosition({
    bool force = false,
    bool precise = false,
    bool dontGetLocationContinuously = false,
  }) async {
    try {
      if (force) {
        bool serviceStatus = await enableLocationService(force: force);
        if (serviceStatus) {
          bool permissionStatus = await requestPermission(
            force: force,
            precise: precise,
            dontGetLocationContinuously: dontGetLocationContinuously,
          );
          if (permissionStatus) {
            try {
              devLog(
                "[LocationService] trying to get the current location from Geolocator.getCurrentPosition.",
              );
              Position pos = await Geolocator.getCurrentPosition().timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  devLog(
                    "[LocationService] getCurrentPosition (force) timed out, returning last known position.",
                  );
                  return position.value;
                },
              );
              _position.value = pos;
              devLog(
                "[LocationService] Got the position | Latitude: ${pos.latitude} | Longitude: ${pos.longitude}",
              );
              _isLocationFirstTimeFetchSuccessfully = true;
              return pos;
            } catch (e, stacktrace) {
              ErrorReporter.instance.report(
                error: e,
                stackTrace: stacktrace,
                customMessage:
                    "LocationService.getCurrentPosition: Geolocator failed",
              );

              devLog(
                "[LocationService] Geolocator.getCurrentPosition Exception: $e",
                error: e,
                stackTrace: stacktrace,
              );
              return null;
            }
          }
        }
      } else {
        bool permissionStatus = await checkPermission(
          force: force,
          precise: precise,
        );
        if (permissionStatus) {
          bool serviceStatus = await checkLocationService(force: force);
          if (serviceStatus) {
            try {
              devLog(
                "[LocationService] trying to get the current location from Geolocator.getCurrentPosition.",
              );
              Position pos = await Geolocator.getCurrentPosition().timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  devLog(
                    "[LocationService] getCurrentPosition timed out, returning last known position.",
                  );
                  return position.value;
                },
              );
              _position.value = pos;
              devLog(
                "[LocationService] Got the position | Latitude: ${pos.latitude} | Longitude: ${pos.longitude}",
              );
              _isLocationFirstTimeFetchSuccessfully = true;
              return pos;
            } catch (e, stacktrace) {
              ErrorReporter.instance.report(
                error: e,
                stackTrace: stacktrace,
                customMessage:
                    "LocationService.getCurrentPosition: Geolocator failed (passive)",
              );

              devLog(
                "[LocationService] Geolocator.getCurrentPosition Exception: $e",
                error: e,
                stackTrace: stacktrace,
              );
              return null;
            }
          }
        }
      }
      return null;
    } catch (e, stacktrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stacktrace,
        customMessage: "LocationService.getCurrentPosition failed",
      );

      devLog(
        "[LocationService] getCurrentPosition Exception: $e",
        error: e,
        stackTrace: stacktrace,
      );
      return null;
    }
  }
}

class LocationUtils {
  static Future<void> giveLocationPermissionDialog({
    bool precise = false,
  }) async {
    if (!LocationService.instance.isDialogOpen) {
      LocationService.instance.isDialogOpen = true;
      AppDialogs.showPermissionDialog(
        title: AppStrings.locationAccessRequired.tr,
        message: precise
            ? "Precise location permission is required to get your current location."
            : "Location permission is required to get your current location.",
        onOpenSettings: () {
          AppSettings.openAppSettings();
        },
        icon: Icons.location_off_outlined,
        secondaryIcon: Icons.location_on_outlined,
      );
    }
    LocationService.instance.isDialogOpen = false;
  }

  static Future<void> enableLocationServicenDialog() async {
    if (!LocationService.instance.isDialogOpen) {
      LocationService.instance.isDialogOpen = true;

      AppDialogs.showPermissionDialog(
        title: AppStrings.locationAccessRequired.tr,
        message: AppStrings.locationPermissionDeniedOpenSettings.tr,
        onOpenSettings: () {
          AppSettings.openAppSettings();
        },
        icon: Icons.location_off_outlined,
        secondaryIcon: Icons.location_on_outlined,
      );

      // await showDialog(
      //   context: Get.context!,
      //   barrierDismissible: false,
      //   builder: (context) {
      //     return WillPopScope(
      //       onWillPop: () {
      //         return Future.value(false);
      //       },
      //       child: ShowCustomDialog(
      //         title: Languages.of(context).appName,
      //         msg: Languages.of(context).locationServiceInstruction,
      //         firstTitle: Languages.of(context).openAppSettings,
      //         onFirstButtonPressed: () async {
      //           await Geolocator.openLocationSettings();
      //            appNavigator.pop();
      //         },
      //         secondTitle: Languages.of(context).cancel,
      //         onSecondButtonPressed: () {
      //            appNavigator.pop();
      //         },
      //         isButtonAlignmentVertical: true,
      //         buttonColor: module?.color,
      //       ),
      //     );
      //   },
      // );
    }
    LocationService.instance.isDialogOpen = false;
  }
}
