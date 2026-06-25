import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/app_nav_spacing.dart';

/// Bottom spacer when Android uses button navigation (API 36+).
class AppSafeBottomBox extends StatefulWidget {
  const AppSafeBottomBox({super.key});

  @override
  State<AppSafeBottomBox> createState() => _AppSafeBottomBoxState();
}

class _AppSafeBottomBoxState extends State<AppSafeBottomBox> {
  static bool _initStarted = false;

  @override
  void initState() {
    super.initState();
    if (!_initStarted) {
      _initStarted = true;
      unawaited(AppNavSpacing.instance.init());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppNavSpacing.instance.needBottomSpacing,
      builder: (context, needSpacing, _) {
        return SizedBox(
          height: (Platform.isAndroid && needSpacing)
              ? MediaQuery.paddingOf(context).bottom
              : 0,
        );
      },
    );
  }
}
