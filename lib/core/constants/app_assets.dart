class AppAssets {
  static const String _imagePath = 'assets/images';

  // Home Screen
  static const String mapBackground = '$_imagePath/map_background.png';
  static const String icGps = '$_imagePath/ic_gps.svg';
  static const String icHomeChip = '$_imagePath/ic_home_chip.svg';
  static const String icOfficeChip = '$_imagePath/ic_office_chip.svg';
  static const String icWorkChip = '$_imagePath/ic_work_chip.svg';
  static const String icOtherChip = '$_imagePath/ic_other_chip.svg';

  // Models
  static const String boda = '$_imagePath/boda.png';
  static const String bajaj = '$_imagePath/bajaj.png';
  static const String gari = '$_imagePath/gari.png';
  static const String gariPlus = '$_imagePath/gari_plus.png';
  
  static const String imgBoda = '$_imagePath/img_boda.png';
  static const String imgBajaji = '$_imagePath/img_bajaji.png';
  static const String imgCab = '$_imagePath/img_cab.png';

  // Auth / Onboarding
  static const String onboarding1 = '$_imagePath/onboarding_1.svg';
  static const String onboarding2 = '$_imagePath/onboarding_2.svg';
  static const String onboarding3 = '$_imagePath/onboarding_3.svg';
  static const String icArrowLeft = '$_imagePath/ic_arrow_left.svg';
  static const String icArrowRight = '$_imagePath/ic_arrow_right.svg';
  static const String icTanzaniaFlag = '$_imagePath/ic_tanzania_flag.svg';
  static const String icSms = '$_imagePath/ic_sms.svg';
  static const String icVerificationSuccess = '$_imagePath/ic_verification_success.svg';
  static const String icTickCircle = '$_imagePath/ic_tick_circle.svg';

  // Branding
  static const String splashBgVector = '$_imagePath/splash_bg_vector.svg';
  static const String selcomGoLogo = '$_imagePath/selcom_go_logo.svg'; 
  
  // Profile
  static const String walletPattern = '$_imagePath/wallet_pattern.png';

  // ── Figma / location flow (`assets/images/figma/location/`)
  /// Prefer existing `ic_*` SVGs. Only reference `mcp_scr07/` when no equivalent exists in-repo.
  static const String _figmaLocation = '$_imagePath/figma/location';
  static const String _locationMcpOnly = '$_figmaLocation/mcp_scr07';

  static const String locationIcPin = '$_figmaLocation/ic_pin.svg';
  static const String locationIcArrowLeft = '$_figmaLocation/ic_arrow_left_28.svg';
  static const String locationIcArrowRight = '$_figmaLocation/ic_arrow_right_24.svg';
  static const String locationIcAdd = '$_figmaLocation/ic_add.svg';
  static const String locationIcHeartOutline = '$_figmaLocation/ic_heart_outline.svg';
  static const String locationIcHeartFilled = '$_figmaLocation/ic_heart_filled.svg';
  static const String locationIcChipHome = '$_figmaLocation/ic_chip_home.svg';
  static const String locationIcChipOffice = '$_figmaLocation/ic_chip_office.svg';
  static const String locationIcChipOther = '$_figmaLocation/ic_chip_other.svg';
  static const String locationIcChipWork = '$_figmaLocation/ic_chip_work.svg';

  /// No prior `ic_*` in repo — kept from Figma MCP export (SCR-07).
  static const String locationCardBackground = '$_locationMcpOnly/img_card_bg.svg';
  static const String locationFieldDivider = '$_locationMcpOnly/img_divider_line.svg';
  static const String locationAddPillBackground = '$_locationMcpOnly/img_add_pill_bg.svg';
  static const String locationClockDistance = '$_locationMcpOnly/img_clock_distance.svg';
}
