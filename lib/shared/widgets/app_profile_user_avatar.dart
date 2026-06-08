import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/svg_picture_asset.dart';

/// Shared profile placeholder styling (home map chip + profile screen).
abstract final class AppProfileAvatarStyle {
  static const double _placeholderAspect = 27 / 33;

  static double profilePlaceholderWidthFor(double side) => side * (33 / 64);

  static double profilePlaceholderHeightFor(double side) =>
      profilePlaceholderWidthFor(side) * _placeholderAspect;

  static double profileEditIconWidthFor(double side) => side * (22 / 64);

  static double profileEditIconHeightFor(double side) =>
      profileEditIconWidthFor(side) * (27 / 24);
}

/// Square rounded avatar (GO UI / map profile chip style).
class AppProfileUserAvatar extends StatelessWidget {
  const AppProfileUserAvatar({
    super.key,
    this.size,
    this.imageUrl,
    this.imageFile,
    this.onCameraTap,
    this.showCameraBadge = false,
  });

  final double? size;
  final String? imageUrl;
  final File? imageFile;
  final VoidCallback? onCameraTap;
  final bool showCameraBadge;

  @override
  Widget build(BuildContext context) {
    final side = size ?? 64.w;
    final radius = BorderRadius.circular(16.r);

    Widget avatar = Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        border: Border.all(color: AppColors.borderDefault),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMapCard,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: radius, child: _buildImage(side)),
    );

    if (!showCameraBadge || onCameraTap == null) {
      return avatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: onCameraTap,
            child: Container(
              padding: EdgeInsets.all(6.w),
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: SvgPictureAsset(
                AppAssets.icProfileEdit,
                color: AppColors.primary,
                width: AppProfileAvatarStyle.profileEditIconWidthFor(side) / 2,
                height:
                    AppProfileAvatarStyle.profileEditIconHeightFor(side) / 2,
                placeholderBuilder: (_) => Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: AppProfileAvatarStyle.profileEditIconWidthFor(side),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(double side) {
    if (imageFile != null) {
      return Image.file(
        imageFile!,
        width: side,
        height: side,
        fit: BoxFit.cover,
      );
    }

    final url = imageUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: side,
        height: side,
        fit: BoxFit.cover,
        placeholder: (_, __) => _placeholder(side),
        errorWidget: (_, __, ___) => _placeholder(side),
      );
    }

    return _placeholder(side);
  }

  Widget _placeholder(double side) {
    return Center(
      child: SvgPictureAsset(
        AppAssets.icProfile,
        width: AppProfileAvatarStyle.profilePlaceholderWidthFor(side),
        height: AppProfileAvatarStyle.profilePlaceholderHeightFor(side),
        placeholderBuilder: (_) => Icon(
          Icons.person,
          color: AppColors.primary,
          size: AppProfileAvatarStyle.profilePlaceholderWidthFor(side),
        ),
      ),
    );
  }
}
