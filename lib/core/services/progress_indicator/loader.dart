import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../constants/app_loader_assets.dart';

/// Global blocking loader (Lottie + blur) for **user actions** — submit, pay, apply.
///
/// For **initial screen / list data** loading, use [AppShimmer] shimmers instead.
class Loader {
  Loader._();

  static final Loader instance = Loader._();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  static const Duration _transitionDuration = Duration(milliseconds: 250);

  void show() {
    if (_isLoading) return;

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      useRootNavigator: true,
      transitionDuration: _transitionDuration,
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, _, __) {
        return PopScope(
          canPop: false,
          child: Stack(
            children: [
              AnimatedBuilder(
                animation: anim,
                builder: (context, _) {
                  final value = anim.value;
                  return BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 6 * value,
                      sigmaY: 6 * value,
                    ),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.35 * value),
                    ),
                  );
                },
              ),
              Center(
                child: FadeTransition(
                  opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                  child: Lottie.asset(
                    AppLoaderAssets.overlayLoaderLottie,
                    fit: BoxFit.cover,
                    height: (MediaQuery.sizeOf(context).width * 0.15).sp,
                    width: (MediaQuery.sizeOf(context).width * 0.15).sp,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    _isLoading = true;
  }

  void hide() {
    if (!_isLoading) return;
    _isLoading = false;

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Waits for the loader route to finish dismissing (use before showing another overlay).
  Future<void> hideAsync() async {
    if (!_isLoading) return;
    hide();
    await Future<void>.delayed(_transitionDuration);
    await WidgetsBinding.instance.endOfFrame;
  }

  /// Shows the loader only after any prior loader route has fully closed.
  Future<void> showAsync() async {
    if (_isLoading) return;
    await hideAsync();
    show();
    await Future<void>.delayed(_transitionDuration);
    await WidgetsBinding.instance.endOfFrame;
  }

  /// Full-screen loader for the duration of [task] (Duka Direct pattern).
  static Future<T> run<T>(Future<T> Function() task) async {
    instance.show();
    try {
      return await task();
    } finally {
      instance.hide();
    }
  }

  /// Sets [flag] while running [task] behind the global loader.
  static Future<T> withFlag<T>(RxBool flag, Future<T> Function() task) async {
    flag.value = true;
    try {
      return await run(task);
    } finally {
      flag.value = false;
    }
  }
}
