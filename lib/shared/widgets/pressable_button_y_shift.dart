import 'package:flutter/material.dart';

/// Wraps a tappable control so **only** the whole widget shifts on Y while pressed:
/// animates toward **positive** Y (down) on pointer down, back toward **0** on release.
///
/// Does not affect child styling, ripple, or inner layout — use as an outer shell.
class PressableButtonYShift extends StatefulWidget {
  const PressableButtonYShift({
    super.key,
    required this.child,
    required this.interactionEnabled,
    this.pressDepthPx = 4,
  });

  final Widget child;
  final bool interactionEnabled;
  final double pressDepthPx;

  @override
  State<PressableButtonYShift> createState() => _PressableButtonYShiftState();
}

class _PressableButtonYShiftState extends State<PressableButtonYShift>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressDy;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 140),
    );
    _pressDy = Tween<double>(begin: 0, end: widget.pressDepthPx).animate(
      CurvedAnimation(
        parent: _pressCtrl,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _pointerDown() {
    if (widget.interactionEnabled) {
      _pressCtrl.forward();
    }
  }

  void _pointerUpOrCancel() {
    _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _pointerDown(),
      onPointerUp: (_) => _pointerUpOrCancel(),
      onPointerCancel: (_) => _pointerUpOrCancel(),
      child: AnimatedBuilder(
        animation: _pressDy,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _pressDy.value),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}
