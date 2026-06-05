import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CustomScrollBar extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;

  const CustomScrollBar({super.key, required this.child, this.controller});

  @override
  State<CustomScrollBar> createState() => _CustomScrollBarState();
}

class _CustomScrollBarState extends State<CustomScrollBar> {
  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      thumbVisibility: true,
      thickness: 4.0,
      radius: Radius.circular(3.0),
      thumbColor: AppColors.blackColor.withValues(alpha: 0.2),
      interactive: true,
      controller: widget.controller,
      child: widget.child,
    );
  }
}
