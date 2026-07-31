part of '../home_controller.dart';

/// Draggable home bottom sheet: measure content, snaps, min/max/initial size.
extension HomeSheetMethods on HomeController {
  void invalidateHomeSheetMeasurement() {
    measuredSheetContentHeightPx.value = null;
    measuredSheetLayoutHeightPx.value = null;
  }

  void reportHomeSheetContentHeight({
    required double contentHeightPx,
    required double layoutHeightPx,
  }) {
    // Shimmer layout must not drive sheet size; real content measures after load.
    if (isLoadingHomeData.value) return;
    if (contentHeightPx <= 0 || layoutHeightPx <= 0) return;
    final previous = measuredSheetContentHeightPx.value;
    if (previous != null && (previous - contentHeightPx).abs() < 1) return;

    final isFirstMeasure = previous == null;
    measuredSheetContentHeightPx.value = contentHeightPx;
    measuredSheetLayoutHeightPx.value = layoutHeightPx;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      syncHomeSheetToDefault(animated: !isFirstMeasure);
    });
  }

  void updateHomeSheetSize(double size) {
    final previousSize = sheetSize.value;
    if ((size - previousSize).abs() < 0.0001) return;
    sheetSize.value = size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nudgeCameraForSheetDelta(previousSize, size);
    });
  }

  void _onHomeSheetChanged() {
    if (_isClosed) return;
    if (!homeSheetController.isAttached) return;
    final size = homeSheetController.size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isClosed) return;
      if (!homeSheetController.isAttached) return;
      // Avoid map/sheet relayout fighting with modal sheets (e.g. add favourite).
      if (Get.isDialogOpen ?? false) return;
      updateHomeSheetSize(size);
    });
  }

  bool get hasRecentLocationsForSheet =>
      !isLoadingHomeData.value && recentDestinations.isNotEmpty;

  /// Smallest drag height: handle + search + chips only (recents/vehicles collapse).
  double get homeSheetMinSize {
    final fraction = _homeSheetCollapsedPeekHeight() / _homeSheetScreenHeight;
    final max = homeSheetMaxChildSize;
    if (max <= HomeController.homeSheetCollapsedPeekMin + 0.02) {
      return (max - 0.02).clamp(0.15, max);
    }
    return fraction.clamp(HomeController.homeSheetCollapsedPeekMin, max - 0.02);
  }

  double get _sheetLayoutScreenHeight =>
      measuredSheetLayoutHeightPx.value ?? _homeSheetScreenHeight;

  /// Uncapped content height as a fraction of the screen (measured when available).
  double get homeSheetRawContentFraction {
    final measured = measuredSheetContentHeightPx.value;
    if (measured != null) {
      return measured / _sheetLayoutScreenHeight;
    }
    return _homeSheetContentHeight(
          includeRecent: isLoadingHomeData.value
              ? shouldShowRecentSection
              : hasRecentLocationsForSheet,
        ) /
        _homeSheetScreenHeight;
  }

  bool get homeSheetHasMeasuredContent =>
      measuredSheetContentHeightPx.value != null;

  /// True when content exceeds 90% — inner list scrolls; sheet max stays at 90%.
  bool get homeSheetNeedsInnerScroll =>
      homeSheetRawContentFraction > HomeController.homeSheetMaxSize + 0.01;

  /// Natural content height including optional recent block (capped at 90%).
  double get homeSheetContentSizeFraction {
    return homeSheetRawContentFraction.clamp(
      HomeController.homeSheetCollapsedPeekMin,
      HomeController.homeSheetMaxSize,
    );
  }

  /// Max drag: content height when it fits; otherwise 90% with inner scroll.
  double get homeSheetMaxChildSize {
    if (homeSheetNeedsInnerScroll) return HomeController.homeSheetMaxSize;
    return homeSheetContentSizeFraction;
  }

  /// Keeps sheet draggable up/down; inner list scrolls only when content overflows.
  ScrollPhysics get homeSheetScrollPhysics =>
      const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics());

  /// True when recents need at least the 70% default (enough measured content).
  bool get homeSheetShouldUseExpandedDefault =>
      hasRecentLocationsForSheet &&
      homeSheetHasMeasuredContent &&
      homeSheetContentSizeFraction >= HomeController.homeSheetWithRecentDefaultSize - 0.02;

  /// Resting height: content-sized when small; 70% only after measure proves it fits.
  double get homeSheetInitialSize {
    final content = homeSheetContentSizeFraction;
    final clamped = content.clamp(homeSheetMinSize, homeSheetMaxChildSize);

    if (!hasRecentLocationsForSheet) return clamped;

    if (!homeSheetHasMeasuredContent) return clamped;

    if (!homeSheetShouldUseExpandedDefault) return clamped;

    return HomeController.homeSheetWithRecentDefaultSize.clamp(
      homeSheetMinSize,
      homeSheetMaxChildSize,
    );
  }

  List<double> get homeSheetSnapSizes {
    final max = homeSheetMaxChildSize;
    final snaps = <double>[homeSheetMinSize];
    if (homeSheetShouldUseExpandedDefault) {
      final expandedSnap = HomeController.homeSheetWithRecentDefaultSize.clamp(
        homeSheetMinSize,
        max,
      );
      if (expandedSnap > snaps.last + 0.05) {
        snaps.add(expandedSnap);
      }
    }
    if (max > snaps.last + 0.05) {
      snaps.add(max);
    }
    return _dedupeAscendingSnapSizes(snaps);
  }

  bool get homeSheetShouldSnap => homeSheetSnapSizes.length > 1;

  void syncHomeSheetToDefault({bool animated = false}) {
    if (_isClosed) return;
    final max = homeSheetMaxChildSize;
    var target = homeSheetInitialSize;
    if (homeSheetController.isAttached) {
      final current = homeSheetController.size;
      if (current > max) {
        target = max;
      }
    }
    sheetSize.value = target;
    if (!homeSheetController.isAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isClosed) return;
        syncHomeSheetToDefault(animated: animated);
      });
      return;
    }
    if (animated) {
      homeSheetController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      homeSheetController.jumpTo(target);
    }
  }

  double get _homeSheetScreenHeight => 1.sh > 0 ? 1.sh : 812;

  double _homeSheetCollapsedPeekHeight() {
    return 80.h + 68.h + 12.h + 16.h;
  }

  double get _estimatedBottomPadding {
    final context = Get.context;
    if (context == null) return 16.h;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    return bottomPadding > 0
        ? (GetPlatform.isIOS ? 0.0 : 8.h) + bottomPadding
        : 16.h;
  }

  double _homeSheetContentHeight({required bool includeRecent}) {
    double contentHeight = 78.h;
    contentHeight += 64.h;

    if (includeRecent && shouldShowRecentSection) {
      contentHeight += 28.h;
      final count = isLoadingHomeData.value
          ? 3
          : recentDestinationsPreview.length;
      contentHeight += count * 64.h;
      if (count > 1) {
        contentHeight += (count - 1) * 25.h;
      }
    }

    if (shouldShowVehicleSection) {
      contentHeight += 12.h;
      contentHeight += 28.h;
      contentHeight += 72.h;
    }

    contentHeight += _estimatedBottomPadding;
    return contentHeight;
  }

  List<double> _dedupeAscendingSnapSizes(List<double> sizes) {
    final sorted = sizes.toList()..sort();
    final out = <double>[];
    for (final size in sorted) {
      final clamped = size.clamp(homeSheetMinSize, homeSheetMaxChildSize);
      if (out.isEmpty || clamped > out.last + 0.05) {
        out.add(clamped);
      }
    }
    return out;
  }
}
