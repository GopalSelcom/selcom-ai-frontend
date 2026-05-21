import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        surface: AppColors.pageBackground,
        onSurface: AppColors.textHeading,
        error: AppColors.error,
        secondary: AppColors.info,
      ),
      scaffoldBackgroundColor: AppColors.pageBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.homeTitle.copyWith(
          color: AppColors.textHeading,
          height: 34 / 20,
          letterSpacing: -0.4,
        ),
        iconTheme: const IconThemeData(color: AppColors.textHeading),
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.bgDarkSurface,
        onSurface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.pageBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.homeTitle.copyWith(
          color: AppColors.textHeading,
          height: 34 / 20,
          letterSpacing: -0.4,
        ),
        iconTheme: const IconThemeData(color: AppColors.textHeading),
      ),
      useMaterial3: true,
    );
  }
}

class BouncingScrollBehavior extends MaterialScrollBehavior {
  const BouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

