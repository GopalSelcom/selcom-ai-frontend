import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/data/models/ride_model.dart';
import '../../../../core/theme/app_colors.dart';
import 'home_active_ride_card.dart';

/// Collapsed active-ride card that expands downward to reveal more rides.
class HomeActiveRidesPanel extends StatefulWidget {
  const HomeActiveRidesPanel({
    super.key,
    required this.isExpanded,
    required this.rides,
    required this.additionalRidesCount,
    required this.onExpand,
    required this.onCollapse,
    required this.vehicleAssetPathFor,
    required this.routeTitleFor,
    required this.remainingLabelFor,
    required this.onViewRide,
  });

  static const Duration animationDuration = Duration(milliseconds: 320);
  static const Curve animationCurve = Curves.easeOutCubic;

  final bool isExpanded;
  final List<RideModel> rides;
  final int additionalRidesCount;
  final VoidCallback onExpand;
  final VoidCallback onCollapse;
  final String Function(RideModel ride) vehicleAssetPathFor;
  final String Function(RideModel ride) routeTitleFor;
  final String Function(RideModel ride) remainingLabelFor;
  final void Function(RideModel ride) onViewRide;

  @override
  State<HomeActiveRidesPanel> createState() => _HomeActiveRidesPanelState();
}

class _HomeActiveRidesPanelState extends State<HomeActiveRidesPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _isTransitioning = false;

  RideModel? get _primaryRide =>
      widget.rides.isEmpty ? null : widget.rides.first;

  List<RideModel> get _additionalRides =>
      widget.rides.length <= 1 ? const [] : widget.rides.sublist(1);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: HomeActiveRidesPanel.animationDuration,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: HomeActiveRidesPanel.animationCurve,
      reverseCurve: Curves.easeInCubic,
    );
    if (widget.isExpanded) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant HomeActiveRidesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded) {
      _isTransitioning = true;
      _controller.forward(from: 0).whenComplete(() {
        if (mounted) _isTransitioning = false;
      });
    } else if (!widget.isExpanded && oldWidget.isExpanded) {
      _isTransitioning = true;
      _controller.reverse().whenComplete(() {
        if (mounted) _isTransitioning = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleMoreBadgeTap() {
    if (widget.isExpanded || _isTransitioning || _additionalRides.isEmpty) {
      return;
    }
    widget.onExpand();
  }

  void _handleClose() {
    if (!widget.isExpanded || _isTransitioning) return;
    widget.onCollapse();
  }

  @override
  Widget build(BuildContext context) {
    final primaryRide = _primaryRide;
    if (primaryRide == null) return const SizedBox.shrink();

    final showsMoreBadge =
        !widget.isExpanded && widget.additionalRidesCount > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeActiveRideCard(
          vehicleAssetPath: widget.vehicleAssetPathFor(primaryRide),
          routeTitle: widget.routeTitleFor(primaryRide),
          remainingLabel: widget.remainingLabelFor(primaryRide),
          additionalRidesCount:
              showsMoreBadge ? widget.additionalRidesCount : 0,
          onViewRide: () => widget.onViewRide(primaryRide),
          onMoreBadgeTap: _handleMoreBadgeTap,
        ),
        ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _expandAnimation.value,
            child: FadeTransition(
              opacity: _expandAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _additionalRides.length; i++) ...[
                    SizedBox(height: HomeActiveRidesExpandedLayout.cardGap.h),
                    HomeActiveRideCardContent(
                      vehicleAssetPath: widget.vehicleAssetPathFor(
                        _additionalRides[i],
                      ),
                      routeTitle: widget.routeTitleFor(_additionalRides[i]),
                      remainingLabel: widget.remainingLabelFor(
                        _additionalRides[i],
                      ),
                      onViewRide: () => widget.onViewRide(_additionalRides[i]),
                    ),
                  ],
                  SizedBox(height: HomeActiveRidesExpandedLayout.closeButtonGap.h),
                  _CloseButton(onPressed: _handleClose),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-screen blur behind the expanded active-rides panel.
class HomeActiveRidesBlurBarrier extends StatelessWidget {
  const HomeActiveRidesBlurBarrier({
    super.key,
    required this.isExpanded,
    required this.onClose,
  });

  final bool isExpanded;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isExpanded,
      child: AnimatedOpacity(
        duration: HomeActiveRidesPanel.animationDuration,
        curve: HomeActiveRidesPanel.animationCurve,
        opacity: isExpanded ? 1 : 0,
        child: GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: ColoredBox(
              color: AppColors.white.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

abstract final class HomeActiveRidesExpandedLayout {
  static const double cardGap = 10;
  static const double closeButtonGap = 20;
  static const double closeButtonSize = 56;
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: AppColors.white,
        elevation: 4,
        shadowColor: AppColors.black.withValues(alpha: 0.12),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: HomeActiveRidesExpandedLayout.closeButtonSize.w,
            height: HomeActiveRidesExpandedLayout.closeButtonSize.w,
            child: Icon(
              Icons.close,
              size: 24.sp,
              color: AppColors.figmaTextPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
