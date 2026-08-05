import 'package:flutter/widgets.dart';

/// App-wide [RouteObserver] for screens that need push/pop-next visibility
/// (e.g. Home refresh when returning from a pushed route).
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();
