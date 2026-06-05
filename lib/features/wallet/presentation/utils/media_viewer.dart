import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:selcom_rides_frontend/shared/utils/app_dialogs.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/services/error_reporting/models/error_constants.dart';
import '../../../../core/theme/app_colors.dart';

// --- ENUM TO DEFINE MEDIA TYPE ---
enum MediaType { image, svg, video }

// --- 1. SHIMMER PLACEHOLDER WIDGET ---
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.greyE4E4E4,
      highlightColor: AppColors.white.withValues(alpha: 0.5),
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// --- 2. THE CORE MEDIA VIEWER WIDGET (Modified) ---
class MediaViewer extends StatefulWidget {
  final String path;
  final List<String>? images;
  final bool enableGalleryPopup;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;
  final Color? color;
  final Widget? errorWidget;

  // Error caching to avoid spamming the same error multiple times
  static final Set<String> _reportedErrors = {};

  const MediaViewer._({
    super.key,
    required this.path,
    this.images,
    this.enableGalleryPopup = false,
    this.width,
    this.height,
    this.color,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.radius = 0.0,
  });

  factory MediaViewer({
    Key? key,
    required String path,
    double? width,
    double? height,
    Color? color,
    Widget? errorWidget,
    BoxFit fit = BoxFit.cover,
    double radius = 0.0,
  }) {
    return MediaViewer._(
      key: key,
      path: path,
      images: null,
      enableGalleryPopup: false,
      width: width,
      height: height,
      color: color,
      errorWidget: errorWidget,
      fit: fit,
      radius: radius,
    );
  }

  factory MediaViewer.gallery({
    Key? key,
    required List<String> images,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double radius = 0.0,
    Color? color,
    Widget? errorWidget,
    bool enableGalleryPopup = true,
  }) {
    final rasterImages = images
        .where((img) => !img.toLowerCase().endsWith('.svg'))
        .toList();

    return MediaViewer._(
      key: key,
      path: rasterImages.isNotEmpty ? rasterImages.first : "",
      images: rasterImages,
      enableGalleryPopup: enableGalleryPopup,
      width: width,
      height: height,
      fit: fit,
      radius: radius,
      color: color,
      errorWidget: errorWidget,
    );
  }

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  // Helper function to determine if the path is an asset (not starting with http/https)
  bool _isAssetPath() {
    return !widget.path.startsWith('http://') &&
        !widget.path.startsWith('https://');
  }

  // Helper function to determine the media type based on the file extension
  MediaType _detectMediaType() {
    final lowerCasePath = widget.path.toLowerCase();

    // 1. Explicit Video Check
    if (lowerCasePath.endsWith('.mp4') ||
        lowerCasePath.endsWith('.mov') ||
        lowerCasePath.endsWith('.avi') ||
        lowerCasePath.endsWith('.mkv') ||
        lowerCasePath.contains('.mp4?')) {
      return MediaType.video;
    }

    // 2. Explicit SVG Check
    if (lowerCasePath.endsWith('.svg') || lowerCasePath.contains('.svg?')) {
      return MediaType.svg;
    }

    // 3. Fallback for Ads (some don't have extensions or have weird ones like .php)
    // If the URL contains "ads" and we can't be sure, we default to image
    // but we can add more robust detection if needed.

    return MediaType.image;
  }

  // Helper method to display a regular static image (network or asset)
  Widget _buildImageWidget() {
    if (_isAssetPath()) {
      return Image.asset(
        widget.path,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _buildError(),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: widget.path,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) => LayoutBuilder(
          builder: (context, constraints) {
            return ShimmerPlaceholder(
              width: widget.width ?? constraints.maxWidth,
              height: widget.height ?? constraints.maxHeight,
              radius: widget.radius > 0.0 ? widget.radius : 8.0,
            );
          },
        ),
        fadeInDuration: const Duration(milliseconds: 300),
        errorWidget: (context, url, error) {
          if (!MediaViewer._reportedErrors.contains(url)) {
            MediaViewer._reportedErrors.add(url);

            final errorStr = error.toString();
            // Suppress noisy transient network errors
            if (errorStr.contains(
              "Connection closed before full header was received",
            )) {
              debugPrint('⚠️ Image Network Fluke [$url]: $error');
              return _buildError();
            }

            debugPrint('❌ Image Loading Error [$url]: $error');
            ErrorReporter.instance.report(
              error: error,
              errorKey: ErrorKeys.imageError,
              extraData: [
                {'url': url},
              ],
            );
          }
          return _buildError();
        },
      );
    }
  }

  // Helper method to display an SVG image (network or asset)
  Widget _buildSvg() {
    final placeholder = LayoutBuilder(
      builder: (context, constraints) {
        final placeholderWidth =
            widget.width ??
            (constraints.maxWidth.isFinite ? constraints.maxWidth : 0.0);
        final placeholderHeight =
            widget.height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : 0.0);

        if (placeholderWidth == 0 && placeholderHeight == 0) {
          return const SizedBox.shrink();
        }

        return ShimmerPlaceholder(
          width: placeholderWidth,
          height: placeholderHeight,
          radius: widget.radius > 0.0 ? widget.radius : 8.0,
        );
      },
    );

    if (_isAssetPath()) {
      return SvgPicture.asset(
        widget.path,
        width: widget.width,
        height: widget.height,
        colorFilter: widget.color != null
            ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
            : null,
        fit: widget.fit,
        placeholderBuilder: (context) => placeholder,
        errorBuilder: (context, error, stackTrace) {
          if (!MediaViewer._reportedErrors.contains(widget.path)) {
            MediaViewer._reportedErrors.add(widget.path);

            final errorStr = error.toString();
            if (errorStr.contains("SVG did not specify dimensions")) {
              debugPrint("⚠️ SVG Asset Dimensions Missing [${widget.path}]");
              return _buildError();
            }

            debugPrint("SVG Asset Error [${widget.path}]: $error");
            ErrorReporter.instance.report(
              error: error,
              errorKey: ErrorKeys.imageError,
              stackTrace: stackTrace,
              extraData: [
                {"path": widget.path},
              ],
            );
          }
          return _buildError();
        },
      );
    } else {
      return SvgPicture.network(
        widget.path,
        width: widget.width,
        height: widget.height,
        colorFilter: widget.color != null
            ? ColorFilter.mode(widget.color!, BlendMode.srcIn)
            : null,
        fit: widget.fit,
        placeholderBuilder: (context) => placeholder,
        errorBuilder: (context, error, stackTrace) {
          if (!MediaViewer._reportedErrors.contains(widget.path)) {
            MediaViewer._reportedErrors.add(widget.path);

            final errorStr = error.toString();
            if (errorStr.contains("SVG did not specify dimensions")) {
              debugPrint(
                "⚠️ SVG Network Dimensions Missing [${widget.path}]",
              );
              return _buildError();
            }

            debugPrint("SVG Network Error [${widget.path}]: $error");
            ErrorReporter.instance.report(
              error: error,
              errorKey: ErrorKeys.imageError,
              stackTrace: stackTrace,
              extraData: [
                {"path": widget.path},
              ],
            );
          }
          return _buildError();
        },
      );
    }
  }

  // Fallback for errors
  Widget _buildError() {
    if (widget.errorWidget != null) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: widget.errorWidget,
      );
    }

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double iconSize =
                (constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight) *
                0.5;

            if (iconSize < 10) return const SizedBox.shrink();

            return Icon(
              Icons.image_not_supported_outlined,
              size: iconSize,
              color: AppColors.greyD0D0D0,
            );
          },
        ),
      ),
    );
  }

  // Helper method to get count text for indicator
  String _getCountText() {
    if (widget.images == null || widget.images!.length <= 1) return '';
    final remaining = widget.images!.length - 1;
    if (remaining > 9) return '9+';
    return '+$remaining';
  }

  // Helper method to build image count indicator
  Widget _buildImageCountIndicator(BuildContext context) {
    final countText = _getCountText();
    if (countText.isEmpty) return const SizedBox.shrink();

    return Positioned(
      top: 6.sp,
      right: 6.sp,
      child: Container(
        height: 25.sp,
        width: 25.sp,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12.sp),
        ),
        child: Text(
          countText,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12.sp,
            // fontFamily: Fonts.plusJakartaSansBold,
          ),
        ),
      ),
    );
  }

  // Helper method to open gallery popup
  void _openGallery(BuildContext context) {
    if (widget.images == null || widget.images!.length <= 1) return;

    // Import will be added at top
    // AppDialogs.showAnimatedDialog(
    //   child: ImageGalleryPopup(
    //     images: widget.images!,
    //     initialIndex: 0,
    //     radius: widget.radius,
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.path.isEmpty || widget.path.toLowerCase() == "null") {
      return _buildError();
    }

    final detectedType = _detectMediaType();

    Widget mediaWidget;

    if (detectedType == MediaType.svg) {
      // SVG pictures are usually not clipped as the radius is cosmetic
      // and they scale differently than bitmap images.
      mediaWidget = _buildSvg();
    }  else {
      // For bitmap images (PNG, JPG, CachedNetworkImage), use ClipRRect to enforce the corner radius.
      mediaWidget = ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: _buildImageWidget(),
      );
    }

    final content = SizedBox(
      width: widget.width,
      height: widget.height,
      child: mediaWidget!,
    );

    // Wrap with gallery functionality if enabled
    if (widget.enableGalleryPopup &&
        widget.images != null &&
        widget.images!.length > 1) {
      return GestureDetector(
        onTap: () => _openGallery(context),
        child: Stack(children: [content, _buildImageCountIndicator(context)]),
      );
    }

    return content;
  }
}

