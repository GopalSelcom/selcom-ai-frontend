import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/constants/app_loader_assets.dart';

/// Inline center loader — same as Duka Direct [GlobalLoaderWidget].
class GlobalLoaderWidget extends StatelessWidget {
  const GlobalLoaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Lottie.asset(
          AppLoaderAssets.inlineLoaderLottie,
          height: MediaQuery.sizeOf(context).height * 0.1,
        ),
      ),
    );
  }
}
