part of '../home_controller.dart';

/// Draggable home bottom sheet: measure content, snaps, min/max/initial size.
class HomeSheetHelper {
  HomeSheetHelper(this.c);

  /// Parent [HomeController] — shared home state and lifecycle.
  final HomeController c;

  /// Clears measured content so the next layout pass re-drives sheet sizing.
  void invalidateHomeSheetMeasurement() {
    c.measuredSheetContentHeightPx.value = null;
    c.measuredSheetLayoutHeightPx.value = null;
  }

  /// Records sheet content height from layout and syncs to the default snap.
  void reportHomeSheetContentHeight({
    required double contentHeightPx,
    required double layoutHeightPx,
  }) {
    // Shimmer layout must not drive sheet size; real content measures after load.
    if (c.isLoadingHomeData.value) return;
    if (contentHeightPx <= 0 || layoutHeightPx <= 0) return;
    final previous = c.measuredSheetContentHeightPx.value;
    if (previous != null && (previous - contentHeightPx).abs() < 1) return;

    final isFirstMeasure = previous == null;
    c.measuredSheetContentHeightPx.value = contentHeightPx;
    c.measuredSheetLayoutHeightPx.value = layoutHeightPx;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      syncHomeSheetToDefault(animated: !isFirstMeasure);
    });
  }

  /// Updates [sheetSize] and nudges the map camera for the drag delta.
  void updateHomeSheetSize(double size) {
    final previousSize = c.sheetSize.value;
    if ((size - previousSize).abs() < 0.0001) return;
    c.sheetSize.value = size;
    // Skip camera nudges until the map exists — otherwise we queue work that
    // collides with platform-view creation on first load.
    if (!c.isMapReady.value || c.activeRide.value != null) return;
    final suppressUntil = c._suppressSheetCameraNudgesUntil;
    if (suppressUntil != null && DateTime.now().isBefore(suppressUntil)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      c.mapHelper._nudgeCameraForSheetDelta(previousSize, size);
    });
  }

  /// Listens to [homeSheetController] and mirrors size into reactive state.
  void _onHomeSheetChanged() {
    if (c._isClosed) return;
    if (!c.homeSheetController.isAttached) return;
    final size = c.homeSheetController.size;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (c._isClosed) return;
      if (!c.homeSheetController.isAttached) return;
      // Avoid map/sheet relayout fighting with modal sheets (e.g. add favourite).
      if (Get.isDialogOpen ?? false) return;
      if (Get.isBottomSheetOpen ?? false) return;
      updateHomeSheetSize(size);
    });
  }

  /// True when recent destinations should influence sheet default height.
  bool get hasRecentLocationsForSheet =>
      !c.isLoadingHomeData.value && c.recentDestinations.isNotEmpty;

  /// Smallest drag height: handle + search + chips only (recents/vehicles collapse).
  double get homeSheetMinSize {
    final fraction = _homeSheetCollapsedPeekHeight() / _homeSheetScreenHeight;
    final max = homeSheetMaxChildSize;
    if (max <= HomeController.homeSheetCollapsedPeekMin + 0.02) {
      return (max - 0.02).clamp(0.15, max);
    }
    return fraction.clamp(HomeController.homeSheetCollapsedPeekMin, max - 0.02);
  }

  /// Screen height used for measured-content fractions.
  double get _sheetLayoutScreenHeight =>
      c.measuredSheetLayoutHeightPx.value ?? _homeSheetScreenHeight;

  /// Uncapped content height as a fraction of the screen (measured when available).
  double get homeSheetRawContentFraction {
    final measured = c.measuredSheetContentHeightPx.value;
    if (measured != null) {
      return measured / _sheetLayoutScreenHeight;
    }
    return _homeSheetContentHeight(
          includeRecent: c.isLoadingHomeData.value
              ? c.placesHelper.shouldShowRecentSection
              : hasRecentLocationsForSheet,
        ) /
        _homeSheetScreenHeight;
  }

  /// True after the sheet has reported a real content height.
  bool get homeSheetHasMeasuredContent =>
      c.measuredSheetContentHeightPx.value != null;

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
      homeSheetContentSizeFraction >=
          HomeController.homeSheetWithRecentDefaultSize - 0.02;

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

  /// Snap points for the draggable sheet (min / optional 70% / max).
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

  /// Whether snap-to points should be enabled (more than one size).
  bool get homeSheetShouldSnap => homeSheetSnapSizes.length > 1;

  /// Jumps or animates the sheet to [homeSheetInitialSize] (or max if oversize).
  void syncHomeSheetToDefault({bool animated = false}) {
    if (c._isClosed) return;
    final max = homeSheetMaxChildSize;
    var target = homeSheetInitialSize;
    if (c.homeSheetController.isAttached) {
      final current = c.homeSheetController.size;
      if (current > max) {
        target = max;
      }
    }
    c.sheetSize.value = target;
    if (!c.homeSheetController.isAttached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (c._isClosed) return;
        syncHomeSheetToDefault(animated: animated);
      });
      return;
    }
    if (animated) {
      c.homeSheetController.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      c.homeSheetController.jumpTo(target);
    }
  }

  /// Logical screen height used for sheet fraction math.
  double get _homeSheetScreenHeight => 1.sh > 0 ? 1.sh : 812;

  /// Estimated collapsed peek height (handle + search + chips).
  double _homeSheetCollapsedPeekHeight() {
    return 80.h + 68.h + 12.h + 16.h;
  }

  /// Bottom safe-area padding contribution to estimated content height.
  double get _estimatedBottomPadding {
    final context = Get.context;
    if (context == null) return 16.h;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    return bottomPadding > 0
        ? (GetPlatform.isIOS ? 0.0 : 8.h) + bottomPadding
        : 16.h;
  }

  /// Heuristic content height before the first real layout measure.
  double _homeSheetContentHeight({required bool includeRecent}) {
    double contentHeight = 78.h;
    contentHeight += 64.h;

    if (includeRecent && c.placesHelper.shouldShowRecentSection) {
      contentHeight += 28.h;
      final count = c.isLoadingHomeData.value
          ? 3
          : c.placesHelper.recentDestinationsPreview.length;
      contentHeight += count * 64.h;
      if (count > 1) {
        contentHeight += (count - 1) * 25.h;
      }
    }

    if (c.placesHelper.shouldShowVehicleSection) {
      contentHeight += 12.h;
      contentHeight += 28.h;
      contentHeight += 72.h;
    }

    contentHeight += _estimatedBottomPadding;
    return contentHeight;
  }

  /// Sorts and merges nearby snap sizes so the sheet does not jitter.
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
