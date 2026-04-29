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
  static const String icVerificationSuccess =
      '$_imagePath/ic_verification_success.svg';
  static const String icTickCircle = '$_imagePath/ic_tick_circle.svg';

  // Branding
  static const String splashBgVector = '$_imagePath/splash_bg_vector.svg';
  static const String selcomGoLogo = '$_imagePath/selcom_go_logo.svg';
  static const String imgSuccessTick = '$_imagePath/img_success_tick.png';

  // Profile
  // static const String walletPattern = '$_imagePath/wallet_pattern.png';
  static const String icFaceScan = '$_imagePath/ic_face_scan.svg';
  static const String icAccountVerified = '$_imagePath/ic_account_verified.svg';
  static const String icWallet = '$_imagePath/ic_wallet.svg';
  static const String icCopy = '$_imagePath/ic_copy.svg';

  // ── Figma / location flow (`assets/images/figma/location/`)
  /// Prefer existing `ic_*` SVGs. Only reference `mcp_scr07/` when no equivalent exists in-repo.
  static const String _figmaLocation = '$_imagePath/location';

  static const String locationIcPickupPin = '$_figmaLocation/ic_pickup_pin.svg';
  static const String locationIcDestinationPin =
      '$_figmaLocation/ic_destination_pin.svg';
  static const String locationIcArrowLeft =
      '$_figmaLocation/ic_arrow_left_28.svg';
  static const String locationIcArrowRight =
      '$_figmaLocation/ic_arrow_right_24.svg';
  static const String locationIcAdd = '$_figmaLocation/ic_add.svg';
  static const String locationIcTime = '$_figmaLocation/ic_time.svg';
  static const String locationIcHeartOutline =
      '$_figmaLocation/ic_heart_outline.svg';
  static const String locationIcHeartFilled =
      '$_figmaLocation/ic_heart_filled.svg';

  // ── Figma / ride SCR-10 (finding driver loader, node `207:24900`)
  static const String _figmaRideScr10 = '$_imagePath/figma/ride_scr10';

  /// Replace via `./scripts/fetch_figma_loader_svg.sh` + `FIGMA_TOKEN` for pixel match to Figma.
  static const String rideFindingLoaderCar =
      '$_figmaRideScr10/ic_finding_loader_car.svg';

  // Payment
  static const String _paymentPath = '$_imagePath/payment';
  static const String icPaymentWallet = '$_paymentPath/ic_wallet.svg';
  static const String icPaymentSelcomPesa = '$_paymentPath/ic_selcom_pesa.svg';
  static const String icPaymentCard = '$_paymentPath/ic_card.svg';
  static const String icPaymentArrowUp = '$_paymentPath/ic_arrow_up.svg';
  static const String icPaymentPerson = '$_paymentPath/ic_person.svg';
  static const String icPaymentPending = '$_paymentPath/ic_payment_pending.svg';
  static const String icPaymentSuccess = '$_paymentPath/ic_payment_success.svg';
  static const String imgPaymentAddCardSuccess =
      '$_paymentPath/add_card_success.png';
  static const String imgPaymentDeleteCardConfirm =
      '$_paymentPath/delete_card_confirm.png';
}
