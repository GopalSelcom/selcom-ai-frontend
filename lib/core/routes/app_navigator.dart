library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


part 'transitions.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final AppNavigator appNavigator = FlutterNavigatorImpl(navigatorKey);

abstract class AppNavigator {
  Future<T?> push<T>(
    Widget page, {
    BuildContext? context,
    AppRouteTransition? transition,
  });

  Future<T?> replace<T>(
    Widget page, {
    BuildContext? context,
    AppRouteTransition? transition,
  });

  Future<T?> clearAndPush<T>(
    Widget page, {
    BuildContext? context,
    AppRouteTransition? transition,
  });

  void pop<T>({T? result, BuildContext? context});

  bool canPop({BuildContext? context});

  Future<T?> pushUntilFirst<T>(
    Widget page, {
    BuildContext? context,
    AppRouteTransition? transition,
  });

  BuildContext? get context;
  AppPage? get current;
  AppPage? get previous;
  AppPage? get secondPrevious;
  List<AppPage> get stack;
}

class AppPage {
  final Widget child;
  final Type id;

  AppPage({required this.child, Type? id}) : id = id ?? child.runtimeType;

  @override
  String toString() => id.toString();
}

class FlutterNavigatorImpl implements AppNavigator {
  final GlobalKey<NavigatorState> navigatorKey;

  FlutterNavigatorImpl(this.navigatorKey) : _stack = [];

  final defaultTransition = BouncyCupertinoTransition();

  final List<AppPage> _stack;

  @override
  List<AppPage> get stack => _stack;

  @override
  BuildContext? get context => navigatorKey.currentContext;

  NavigatorState? _resolveNavigator(BuildContext? context) {
    return context != null ? Navigator.of(context) : navigatorKey.currentState;
  }

  AppPage _toPage(Widget child) => AppPage(child: child);

  @override
  AppPage? get current => _stack.isNotEmpty ? _stack.last : null;

  @override
  AppPage? get previous =>
      _stack.length >= 2 ? _stack[_stack.length - 2] : null;

  @override
  AppPage? get secondPrevious =>
      _stack.length >= 3 ? _stack[_stack.length - 3] : null;

  Route<T> _buildRoute<T>(AppPage page, AppRouteTransition transition) {
    return transition.build<T>(
      page.child,
      settings: RouteSettings(arguments: page),
    );
  }

  @override
  Future<T?> push<T>(
    Widget page, {
    BuildContext? context,
    AppRouteTransition? transition,
  }) {
    final nav = _resolveNavigator(context);
    if (nav == null) return Future.value(null);

    final appPage = _toPage(page);
    final route = _buildRoute<T>(appPage, transition ?? defaultTransition);

    // Add to stack immediately - this is the primary source of truth
    _stack.add(appPage);

    print('🚀 PUSHING route: ${appPage.id}');
    print(
      '📚 Stack after push: ${_stack.map((p) => p.toString()).toList()} (size: ${_stack.length})',
    );

    return nav.push(route);
  }

  @override
  Future<T?> replace<T>(
    Widget page, {
    BuildContext? context,
    AppRouteTransition? transition,
  }) {
    final nav = _resolveNavigator(context);
    if (nav == null) return Future.value(null);

    final appPage = _toPage(page);
    final route = _buildRoute<T>(appPage, transition ?? defaultTransition);

    // Replace in stack: remove current one and add new one
    if (_stack.isNotEmpty) {
      _stack.removeLast();
    }
    _stack.add(appPage);

    print('🔄 REPLACING route with: ${appPage.id}');
    print(
      '📚 Stack after replace: ${_stack.map((p) => p.toString()).toList()} (size: ${_stack.length})',
    );

    return nav.pushReplacement<T, T>(route);
  }

  @override
  bool canPop({BuildContext? context}) {
    final nav = _resolveNavigator(context);
    if (nav == null) return false;

    // Rely on BOTH navigator state and internal stack
    // return nav.canPop() && _stack.length > 1;
    return nav.canPop();
  }

  @override
  Future<T?> clearAndPush<T>(
    Widget page, {
    BuildContext? context,
    AppRouteTransition? transition,
  }) {
    final nav = _resolveNavigator(context);
    if (nav == null) return Future.value(null);

    print('🧹 CLEARING stack and pushing: ${page.runtimeType}');
    print(
      '📚 Stack before clear: ${_stack.map((p) => p.toString()).toList()} (size: ${_stack.length})',
    );

    // Clear the stack since we're removing all routes
    _stack.clear();

    final appPage = _toPage(page);
    final route = _buildRoute<T>(appPage, transition ?? defaultTransition);

    return nav.pushAndRemoveUntil(route, (_) => false);
  }

  @override
  void pop<T>({T? result, BuildContext? context}) {
    final nav = _resolveNavigator(context);
    if (nav?.canPop() != true) return;

    // Remove from stack immediately - this is the primary source of truth
    if (_stack.isNotEmpty) {
      final removed = _stack.removeLast();
      print('🔙 POPPING route: ${removed.id}');
      print(
        '📚 Stack after pop: ${_stack.map((p) => p.toString()).toList()} (size: ${_stack.length})',
      );
    }

    // Mark that this pop was initiated by us (not gesture/back button)
    AppNavigatorObserver.markPopInitiated();
    nav!.pop<T>(result);
  }

  @override
  Future<T?> pushUntilFirst<T>(
    Widget page, {
    BuildContext? context,
    AppRouteTransition? transition,
  }) async {
    final nav = _resolveNavigator(context);
    if (nav == null) return null;

    print('⏮️ PUSHING until first: ${page.runtimeType}');
    print(
      '📚 Stack before pushUntilFirst: ${_stack.map((p) => p.toString()).toList()} (size: ${_stack.length})',
    );

    // If stack is empty, do a normal push (observer will handle adding to stack)
    if (_stack.isEmpty) {
      final appPage = _toPage(page);
      final route = _buildRoute<T>(appPage, transition ?? defaultTransition);
      return nav.push<T>(route);
    }

    // Keep only first page in stack
    final firstPage = _stack.first;
    _stack.clear();
    _stack.add(firstPage);

    final appPage = _toPage(page);
    final route = _buildRoute<T>(appPage, transition ?? defaultTransition);

    return nav.pushAndRemoveUntil<T>(route, (route) => route.isFirst);
  }
}

class AppNavigatorObserver extends NavigatorObserver {
  /// Uses a getter to always access the latest stack from FlutterNavigatorImpl
  List<AppPage> get stack => (appNavigator as FlutterNavigatorImpl)._stack;

  /// Track if a pop was initiated by our code (vs gesture/back button)
  static bool _popInitiatedByUs = false;
  static void markPopInitiated() => _popInitiatedByUs = true;
  static void clearPopInitiated() => _popInitiatedByUs = false;

  @override
  void didPush(Route route, Route? previousRoute) {
    // Stack is managed in push() method - only log here for debugging
    print('🔔 Observer: didPush - ${route.settings.arguments?.runtimeType}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    // Only handle pops NOT initiated by our pop() method
    // (i.e., back button or gesture pops)
    if (!_popInitiatedByUs) {
      if (stack.isNotEmpty) {
        final removed = stack.removeLast();
        print('🔙 Observer: Back button/gesture POP - Removed: $removed');
        print(
          '📚 Stack after gesture pop: ${stack.map((p) => p.toString()).toList()} (size: ${stack.length})',
        );
      }
    } else {
      _popInitiatedByUs = false; // Reset flag
      print('🔔 Observer: didPop handled by pop() method');
    }
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    // Stack is managed in replace() method - only log here for debugging
    print(
      '🔔 Observer: didReplace - ${newRoute?.settings.arguments?.runtimeType}',
    );
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    // Handle removes that might come from pushAndRemoveUntil etc.
    print('🔔 Observer: didRemove - ${route.settings.arguments}');
  }
}
