import 'dart:async';
import 'dart:io';

import '../services/error_reporting/error_reporter.dart';

/// Shared DNS-based connectivity probe used by both API calls and the
/// connectivity monitor.
///
/// Why this exists:
/// - We previously relied on a single host (`google.com`) lookup.
/// - On some networks (offline, restricted DNS, regional blocks), that
///   lookup throws [SocketException] even when the app itself is healthy.
/// - Treating that expected condition as a reportable exception created noisy
///   error alerts and duplicated logic in multiple files.
///
/// This helper probes multiple hosts with a timeout and returns `false` for
/// expected connectivity failures. Unexpected errors are reported centrally.
const List<String> kConnectivityProbeHosts = <String>[
  'google.com',
  'one.one.one.one',
  'cloudflare.com',
];

class ConnectivityProbe {
  ConnectivityProbe._();

  static final ConnectivityProbe instance = ConnectivityProbe._();

  Future<bool> probeInternetConnection({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    for (final host in kConnectivityProbeHosts) {
      try {
        final result = await InternetAddress.lookup(host).timeout(timeout);
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } on SocketException {
        // Expected while offline or DNS is unavailable for this host.
      } on TimeoutException {
        // Expected on unstable/blocked networks; continue with next host.
      } catch (error, stackTrace) {
        ErrorReporter.instance.report(error: error, stackTrace: stackTrace);
      }
    }
    return false;
  }
}
