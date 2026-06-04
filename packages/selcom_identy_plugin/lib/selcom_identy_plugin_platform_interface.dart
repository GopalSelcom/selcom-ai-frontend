import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'selcom_identy_plugin_method_channel.dart';

abstract class SelcomIdentyPluginPlatform extends PlatformInterface {
  /// Constructs a SelcomIdentyPluginPlatform.
  SelcomIdentyPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static SelcomIdentyPluginPlatform _instance =
      MethodChannelSelcomIdentyPlugin();

  /// The default instance of [SelcomIdentyPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelSelcomIdentyPlugin].
  static SelcomIdentyPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SelcomIdentyPluginPlatform] when
  /// they register themselves.
  static set instance(SelcomIdentyPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<dynamic> enrollFinger({required Map<String, dynamic> data}) async {
    throw UnimplementedError('enrollFinger() has not been implemented.');
  }
}
