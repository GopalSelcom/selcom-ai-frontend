import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'app_back_button.dart';

/// Material [AppBar] for card-style screens (uses [AppTheme] appBarTheme).
///
/// For the green profile-style header, use [AppProfileHeader] instead.
class AppScreenAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppScreenAppBar({
    super.key,
    required this.title,
    this.leading,
    this.showBackWhenCanPop = true,
  });

  final String title;
  final Widget? leading;
  final bool showBackWhenCanPop;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.of(context).canPop();

    return AppBar(
      automaticallyImplyLeading: false,
      leading: leading ??
          (showBackWhenCanPop && canGoBack
              ? const AppBackButton(
                  color: AppColors.textHeading,
                  alignment: Alignment.center,
                )
              : null),
      title: Text(title),
    );
  }
}
