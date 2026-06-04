// import 'package:selcom_identy_plugin/scan_options.dart';

// import 'selcom_identy_plugin_platform_interface.dart';

// class SelcomIdentyPlugin {
//   IdentyOptions options = IdentyOptions();

//   Future<dynamic> enrollFinger() {
//     return SelcomIdentyPluginPlatform.instance
//         .enrollFinger(data: options.toParams());
//   }
// }

import 'package:selcom_identy_plugin/scan_options.dart';
import 'selcom_identy_plugin_platform_interface.dart';

class SelcomIdentyPlugin {
  // Private constructor
  SelcomIdentyPlugin._internal();

  // The single instance of the class
  static final SelcomIdentyPlugin _instance = SelcomIdentyPlugin._internal();

  // Factory constructor that returns the same instance every time
  factory SelcomIdentyPlugin() {
    return _instance;
  }

  // Instance variables and methods
  IdentyOptions options = IdentyOptions();

  Future<dynamic> enrollFinger() {
    return SelcomIdentyPluginPlatform.instance
        .enrollFinger(data: options.toParams());
  }
}
