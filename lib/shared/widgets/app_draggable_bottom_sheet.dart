import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Reusable draggable bottom sheet shell for map-style screens.
class AppDraggableBottomSheet extends StatelessWidget {
  const AppDraggableBottomSheet({
    super.key,
    required this.initialChildSize,
    required this.minChildSize,
    this.maxChildSize = 0.9,
    required this.childBuilder,
  });

  final double initialChildSize;
  final double minChildSize;
  final double maxChildSize;
  final Widget Function(ScrollController scrollController) childBuilder;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: maxChildSize,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: childBuilder(scrollController),
        );
      },
    );
  }
}
