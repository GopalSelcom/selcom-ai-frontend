import 'package:flutter/material.dart';

class AppColors {
  // Brand
  static const Color primary        = Color(0xFF5CB75E);  // Green — buttons, highlights
  static const Color primaryLight   = Color(0xFFE8FDE8);  // Light geen bg

  // Backgrounds
  static const Color pageBackground = Color(0xFFF8FAFC);  // Gray/Shade 7
  static const Color cardBackground = Color(0xFFFFFFFF);  // Cards, sheets, modals
  static const Color errorBackground= Color(0xFFFDECEA);  // OTP error banner
  static const Color bgMuted = Color(0xFFF5F5F5);
  static const Color bgSuccessLight = Color(0xFFE8F5E9);
  static const Color bgDarkSurface = Color(0xFF121212);
  static const Color surfaceSubtle = Color(0xFFF8F9FD);
  static const Color bgSoftCircle = Color(0xFFF1F5F9);
  static const Color bgSuccessBanner = Color(0xFFEAF9F1);
  static const Color bgPaymentRequest = Color(0x1FFF9900); // 12% of #FF9900
  static const Color bgPaymentSuccess = Color(0x1F0EAD36); // 12% of #0EAD36
  static const Color bgVerificationSurface = Color(0xFFF2F5F9);
  static const Color bgUnreadNotification = Color(0xFFF0F9FF);
  static const Color bgAvatarLightPink = Color(0xFFFFD2DE);
  static const Color bgCardDetailsSurface = Color(0xFFF1F3F7);
  static const Color bgInfoLight = Color(0xFFE0F2FE);
  static const Color bgPurpleLight = Color(0xFFEDE9FE);
  static const Color bgWarningLight = Color(0xFFFEF3C7);
  static const Color bgNeutralSoft = Color(0xFFFAFAFA);
  static const Color bgMintLight = Color(0xFFECFDF5);
  static const Color bgGreenLight = Color(0xFFDCFCE7);
  static const Color bgOrangeLight = Color(0xFFFFEDD5);

  // Text / Shades
  static const Color textHeading    = Color(0xFF132235);  // Primary heading/title text
  static const Color textBody       = Color(0xFF364B63);  // Secondary/body text
  static const Color textLight      = Color(0xFFAAAAAA);
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textMuted = Color(0xFF9E9E9E);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textError = Color(0xFFE24B4A);
  static const Color textMapHint = Color(0x8A000000);
  static const Color textMapIcon = Color(0xDE000000);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textMutedStrong = Color(0xFF656565);
  static const Color textDarkOlive = Color(0xFF131D0B);
  static const Color textDim = Color(0xFF585858);
  static const Color textVerified = Color(0xFF2E7D32);
  static const Color textBrandVisaPrimary = Color(0xFF0057A0);
  static const Color textBrandVisaSecondary = Color(0xFF00579F);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textSlateStrong = Color(0xFF0F172A);
  static const Color textSlate = Color(0xFF475569);
  static const Color textSlateSoft = Color(0xFF64748B);
  static const Color textSectionMuted = Color(0xFF77869E);
  static const Color textSafetyNotice = Color(0xFF1F2024);
  static const Color textDriverTime = Color(0xFFA1A1BC);
  static const Color textMessageHint = Color(0xFF1B1A57);
  static const Color textPaymentDialogMessage = Color(0xFF132235);

  // Semantic
  static const Color success        = Color(0xFF0EAD36);  // Green
  static const Color error          = Color(0xFFE24B4A);  // Red error
  static const Color warning        = Color(0xFFEF9F27);  // Orange/amber
  static const Color info           = Color(0xFF378ADD);  // Blue
  static const Color successBadge = Color(0xFF4CAF50);
  static const Color warningStrong = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);

  // Input
  static const Color inputBorderActive   = Color(0xFF378ADD);  // Blue on focus
  static const Color inputBorderDefault  = Color(0xFFDDDDDD);
  static const Color inputBorderError    = Color(0xFFE24B4A);

  // Dividers
  static const Color divider        = Color(0xFFEEEEEE);
  static const Color shadow         = Color(0x1A000000);  // 10% black
  static const Color borderSubtle = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFD3DDE7);
  static const Color borderInputMuted = Color(0xFF9CA3AF);
  static const Color borderWalletCard = Color(0xFFE6E9EE);
  static const Color dividerHandle = Color(0xFFD1D5DB);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color progressTrack = Color(0xFFDCE1E8);
  static const Color borderNeutral = Color(0xFFEDEDED);
  static const Color borderNeutralStrong = Color(0xFFCBD5E1);
  static const Color borderGray = Color(0xFFD9D9D9);

  // Base colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Overlay / shadow variants
  static const Color shadowSoft = Color(0x0D000000);
  static const Color overlayBlack12 = Color(0x1F000000);
  static const Color shadowStrong = Color(0x66000000);
  static const Color shadowCard = Color(0x0F000000);
  static const Color shadowMapCard = Color(0x1A000000);
  static const Color shadowProfileModal = Color(0x0D242E49);
  static const Color overlayGray43 = Color(0x6D808080);

  // Skeleton
  static const Color skeletonBase = Color(0xFFE2E8F0);
  static const Color skeletonHighlight = Color(0xFFF8FAFC);

  static const Color safetyBannerBg = Color(0xFFE8F4FC);
  static const Color onlineGreen    = Color(0xFF22C55E);
  static const Color driverBubbleBg = Color(0xFFF0F2F5);

  // Figma Sync (Node 207:24539)
  static const Color borderDefault  = Color(0xFFD3DDE7);
  static const Color figmaTextPrimary = Color(0xFF2A3143);
  static const Color figmaTextSecondary = Color(0xFF586377);
  static const Color figmaIconGreen = Color(0xFF269441);
  static const Color splashVectorTint = Color(0xFF4AA448);
  static const Color mapPickupMarkerBlue = Color(0xFF4FA3FF);
  static const Color mapDropMarkerGreen = Color(0xFF34C759);
  static const Color mapStopMarkerRed = Color(0xFFE11D48);
  static const Color ratingStarFilled = Color(0xFFFFCC00);
  static const Color ratingStarEmpty = Color(0xFFE6E9EE);
  static const Color iconInfo = Color(0xFF0284C7);
  static const Color iconPurple = Color(0xFF6D28D9);
  static const Color iconWarning = Color(0xFFD97706);
  static const Color iconSuccess = Color(0xFF16A34A);
  static const Color iconOrange = Color(0xFFEA580C);
  static const Color iconAmber = Color(0xFFB45309);
  static const Color iconMutedLight = Color(0xFFCACACA);
  static const Color iconPaymentRequest = Color(0xFFFF9900);
  static const Color iconPaymentSuccess = success;
  static const Color iconHeartOutline = Color(0xFF292D32);
  static const Color iconHeartFilled = Color(0xFFF3004C);
  static const Color promotionBlue = Color(0xFF2668D2);
  static const Color previousPickupBlue = Color(0xFF3B83ED);
  static const Color previousPickupHalo = Color(0xFFB9D0EE);
  static const Color routeBlue = Color(0xFF3073E8);
  static const Color pinRed = Color(0xFFF52D56);
  static const Color figmaInputBlue = Color(0xFF2F6FED);
  static const Color dangerDeep = Color(0xFFE31E24);
  static const Color successMint = Color(0xFF10B981);
  static const Color ratingGoldDark = Color(0xFFD9A800);
  static const Color ratingGold = Color(0xFFFFD600);

  // Backward-compat aliases (to be removed gradually)
  static const Color shade1 = textHeading;
  static const Color shade2 = textBody;
  static const Color shade5 = borderDefault;
  static const Color textDark = textHeading;
  static const Color textGrey = textBody;
  static const Color bgWalletCard = surfaceSubtle;
  static const Color successAccent = successBadge;
  static const Color warningAccent = warningStrong;
  static const Color dangerAccent = danger;
  static const Color textVisaBrand = textBrandVisaPrimary;
  static const Color textVisaBrandAlt = textBrandVisaSecondary;
  static const Color dangerStrong = dangerDeep;
}
