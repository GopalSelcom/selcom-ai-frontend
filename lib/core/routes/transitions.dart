part of 'app_navigator.dart';

abstract class AppRouteTransition {
  Route<T> build<T>(Widget child, {RouteSettings? settings});
}

class BouncyCupertinoTransition extends AppRouteTransition {
  @override
  Route<T> build<T>(Widget page, {RouteSettings? settings}) {
    return ForwardBouncyCupertinoRoute<T>(
      builder: (_) => page,
      settings: settings,
    );
  }
}

class SlideFromLeftTransition extends AppRouteTransition {
  @override
  Route<T> build<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final offset = Tween(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(animation);

        return SlideTransition(position: offset, child: child);
      },
    );
  }
}

class SlideFromBottomTransition extends AppRouteTransition {
  @override
  Route<T> build<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final offset = Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );

        return SlideTransition(position: offset, child: child);
      },
    );
  }
}

class FadeScaleTransitionRoute extends AppRouteTransition {
  @override
  Route<T> build<T>(Widget page, {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutSine,
        );

        return FadeTransition(
          opacity: Tween(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: const Interval(0.0, 0.8)),
          ),
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(curved),
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class MaterialTransition extends AppRouteTransition {
  @override
  Route<T> build<T>(Widget page, {RouteSettings? settings}) {
    return MaterialPageRoute<T>(builder: (_) => page, settings: settings);
  }
}

class CupertinoTransition extends AppRouteTransition {
  @override
  Route<T> build<T>(Widget page, {RouteSettings? settings}) {
    return CupertinoPageRoute<T>(builder: (_) => page, settings: settings);
  }
}
