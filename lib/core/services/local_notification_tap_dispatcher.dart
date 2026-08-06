import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Forwards local-notification taps to [NotificationService].
///
/// [AndroidOrderTrackingManager] also calls
/// [FlutterLocalNotificationsPlugin.initialize], which replaces the platform
/// tap callback. Both initializers must register this dispatcher so product
/// notification taps (e.g. type 503 → wallet) keep working.
typedef LocalNotificationTapHandler = void Function(NotificationResponse response);

abstract final class LocalNotificationTapDispatcher {
  static LocalNotificationTapHandler? _handler;

  static void register(LocalNotificationTapHandler handler) {
    _handler = handler;
  }

  static void dispatch(NotificationResponse response) {
    _handler?.call(response);
  }
}
