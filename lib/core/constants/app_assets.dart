class AppAssets {
  static const String _imagePath = 'assets/images';
  static const String _jsonPath = 'assets/json';

  static const String _brandingPath = '$_imagePath/branding';
  static const String _authPath = '$_imagePath/auth';
  static const String _homePath = '$_imagePath/home';
  static const String _ridePath = '$_imagePath/ride';
  static const String _profilePath = '$_imagePath/profile';
  static const String _promoPath = '$_imagePath/promo';

  // Home Screen
  static const String mapBackground = '$_ridePath/map_background.png';
  static const String icGps = '$_homePath/ic_gps.svg';
  static const String icCall = '$_ridePath/ic_call.svg';
  static const String icMessage = '$_ridePath/ic_message.svg';
  static const String icInfo = '$_ridePath/ic_info.svg';
  static const String icSend = '$_ridePath/ic_send.svg';
  static const String icDownload = '$_ridePath/ic_download.svg';
  static const String icRequest = '$_ridePath/ic_request.svg';
  static const String icSuccess = '$_ridePath/ic_success.svg';
  static const String icRatingStar = '$_ridePath/ic_rating_start.svg';
  static const String icHomeChip = '$_homePath/ic_home_chip.svg';
  static const String icOfficeChip = '$_homePath/ic_office_chip.svg';
  static const String icWorkChip = '$_homePath/ic_work_chip.svg';
  static const String icOtherChip = '$_homePath/ic_other_chip.svg';

  static const String _vehicleImagePath = '$_imagePath/vehicle';
  static const String imgBoda = '$_vehicleImagePath/img_boda.svg';
  static const String imgBajaji = '$_vehicleImagePath/img_bajaji.svg';
  static const String imgCab = '$_vehicleImagePath/img_cab.svg';

  /// Legacy alias for cab vehicle art (SVG).
  static const String gariPlus = imgCab;

  // Auth / Onboarding
  static const String icFacebook = '$_authPath/ic_facebook.svg';
  static const String icGoogle = '$_authPath/ic_google.svg';
  static const String icGoogleLogo = '$_imagePath/ic_google_logo.svg';
  static const String onboarding1 = '$_authPath/onboarding_1.svg';
  static const String onboarding2 = '$_authPath/onboarding_2.svg';
  static const String onboarding3 = '$_authPath/onboarding_3.svg';
  static const String icTanzaniaFlag = '$_authPath/ic_tanzania_flag.svg';
  static const String icError = '$_authPath/ic_error.svg';
  static const String icArrowForward = '$_authPath/ic_arrow_forward.svg';

  // Branding
  static const String splashScreenBg = '$_brandingPath/splash_screen_bg.svg';
  static const String selcomGoLogo = '$_brandingPath/selcom_go_logo.svg';
  static const String selcomGoLogoPrimaryColor =
      '$_brandingPath/selcom_go_logo_primary_color.svg';

  /// PNG variant (e.g. PDF / non-SVG pipelines).
  static const String selcomGoLogoPng = '$_imagePath/selcom_go_logo.png';
  static const String selcomGoLogoRedSvg = '$_imagePath/Selcom Go logo-red.svg';

  /// Map driver markers (top-down silhouettes; SVG → bitmap via [MapMarkerUtils]).
  static const String _mapMarkerPath = '$_imagePath/map';
  static const String mapMarkerBoda = '$_mapMarkerPath/map_marker_boda.svg';
  static const String mapMarkerCab = '$_mapMarkerPath/map_marker_cab.svg';
  static const String mapMarkerBajaji = '$_mapMarkerPath/map_marker_bajaji.svg';
  static const String icPromotions = '$_imagePath/ic_promotions.svg';
  static const String icPromoCode = '$_promoPath/ic_promo_code.svg';
  static const String icPromoCodeDisabled =
      '$_promoPath/ic_promo_code_disabled.svg';

  // Profile
  static const String icProfile = '$_profilePath/ic_profile.svg';
  static const String icProfileEdit = '$_profilePath/ic_profile_edit.svg';
  static const String icFaceScan = '$_imagePath/ic_face_scan.svg';
  static const String icAccountVerified = '$_imagePath/ic_account_verified.svg';
  static const String icWallet = '$_profilePath/ic_wallet.svg';
  static const String icCopy = '$_profilePath/ic_copy.svg';
  static const String icHeadPhone = '$_ridePath/headphone.svg';

  static const String _figmaLocation = '$_imagePath/location';

  static const String locationIcPickupPin = '$_figmaLocation/ic_pickup_pin.svg';
  static const String locationIcDestinationPin =
      '$_figmaLocation/ic_destination_pin.svg';
  static const String locationIcArrowRight =
      '$_figmaLocation/ic_arrow_right_24.svg';
  static const String locationIcAdd = '$_figmaLocation/ic_add.svg';
  static const String locationIcTime = '$_figmaLocation/ic_time.svg';
  static const String locationIcHeartOutline =
      '$_figmaLocation/ic_heart_outline.svg';
  static const String locationIcHeartFilled =
      '$_figmaLocation/ic_heart_filled.svg';

  // Payment
  static const String _paymentPath = '$_imagePath/payment';
  static const String icPaymentPerson = '$_paymentPath/ic_person.svg';
  static const String icCardReceive = '$_paymentPath/ic_card_receive.svg';
  static const String icTips = '$_paymentPath/ic_tips.svg';
  static const String imgQrCode = '$_paymentPath/img_qr_code.png';
  static const String imgQrBg = '$_paymentPath/img_qr_bg.png';
  static const String imgPaymentAddCardSuccess =
      '$_paymentPath/add_card_success.png';
  static const String imgPaymentDeleteCardConfirm =
      '$_paymentPath/delete_card_confirm.png';
  static const String icEStatement = '$_paymentPath/ic_e_statement.svg';
  static const String icShowVcn = '$_paymentPath/ic_show_vcn.svg';
  static const String imgVcnCard = '$_paymentPath/img_vcn_card.png';

  ///animations:-
  static const String carAnimation = '$_jsonPath/car_animation.json';
}
