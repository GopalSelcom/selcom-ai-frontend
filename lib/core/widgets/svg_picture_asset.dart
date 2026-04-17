import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Loads an SVG from [assetPath] with optional [placeholderBuilder] (e.g. Material icon fallback).
/// Use paths from [AppAssets]; do not hard-code asset strings in feature screens.
class SvgPictureAsset extends StatelessWidget {
  const SvgPictureAsset(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
        this.color,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.placeholderBuilder,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final AlignmentGeometry alignment;
  final WidgetBuilder? placeholderBuilder;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      color: color,
      alignment: alignment,
      placeholderBuilder: placeholderBuilder,
    );
  }
}
