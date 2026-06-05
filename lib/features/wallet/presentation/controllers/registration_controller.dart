import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:selcom_identy_plugin/selcom_identy_plugin.dart';
import 'package:selcom_rides_frontend/core/constants/app_assets.dart';
import 'package:selcom_rides_frontend/shared/utils/app_dialogs.dart';

import '../../../../core/data/models/user_model.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../../../core/services/progress_indicator/loader.dart';
import '../../../../core/services/storage_service.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../domain/repositories/registration_repository.dart';
import '../models/nida_card_model.dart';
import '../models/passport_scanning_model.dart';
import '../models/registration/add_user_to_selcom_id_request.dart';
import '../models/registration/add_user_to_selcom_id_response_model.dart';
import '../models/registration/client_success_model.dart';
import '../models/registration/finger_scan_model.dart';
import '../models/registration/get_user_from_selcom_id_request.dart';
import '../models/registration/get_user_from_selcom_id_response.dart';
import '../models/registration/selcom_id_contact_support_request.dart';
import '../models/registration/selcom_id_user_data_exist_request.dart';
import '../models/registration/selcom_id_user_data_exist_response.dart';
import '../models/registration/verify_selfie_response.dart';
import '../models/registration/wallet_credit_refund_amount_model.dart';
import '../models/user_add_card_details_model.dart';
import '../screens/registration/biometric_authentication_screen.dart';
import '../screens/registration/document_confirmation_screen.dart';
import '../screens/registration/liveliness_screen.dart';
import '../screens/registration/passport_scan_confirmation_screen.dart';
import '../screens/registration/selcom_id_confirmation_screen.dart';
import '../screens/registration/verification_success_screen.dart';
import '../screens/registration/wallet_waiting_screen.dart';
import '../screens/registration/widgets/biometric_verification_inprogress.dart';
import '../utils/app_info.dart';
import '../utils/get_last_word.dart';
import '../utils/random_string.dart';
import '../utils/resolve_image_url.dart';
import 'wallet_controller.dart';
import 'package:image/image.dart' as img;
import 'package:m7_livelyness_detection/index.dart' as file;

class RegistrationController extends GetxController {
  RegistrationController._internal();

  static RegistrationController? _instance;

  factory RegistrationController() {
    _instance ??= RegistrationController._internal();
    return _instance!;
  }

  // Rx<CityConfigModel> cityConfigModel = CityConfigModel().obs;
  final RegistrationRepository registrationRepository =
  RegistrationRepository();

  WalletController? get walletController =>
      Get.isRegistered<WalletController>()
          ? Get.find<WalletController>()
          : null;

  void resetMissingFingers() {
    SelcomIdentyPlugin selcomIdentyPlugin = SelcomIdentyPlugin();

    isIndexFingerMissing.value = false;
    isMiddleFingerMissing.value = false;
    isRingFingerMissing.value = false;
    isLittleFingerMissing.value = false;
    isMissingFingerSelected.value = false;

    selcomIdentyPlugin.options.isLeftMissingFingerSelected = false;
    selcomIdentyPlugin.options.isRightMissingFingerSelected = false;
    selcomIdentyPlugin.options.rightHandMissingArray = [];
    selcomIdentyPlugin.options.leftHandMissingArray = [];
  }

  RxBool isMissingFingerSelected = false.obs;

  Timer? timerDisplay;
  RxInt totalSeconds = 30.obs;
  RxInt displaySeconds = 30.obs;

  void cancelTimerDisplay() {
    if (timerDisplay != null) {
      timerDisplay?.cancel();
      timerDisplay = null;
    }
  }

  Future<void> timerForNIDAAuth() async {
    totalSeconds = 120.obs;
    displaySeconds = 120.obs;
    timerDisplay = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (displaySeconds.value == 0) {
        cancelTimerDisplay();
      } else {
        displaySeconds.value = displaySeconds.value - 1;
      }
    });
  }

  Future<void> processIdentyResult({required dynamic result}) async {
    debugPrint("Finger scan result ==========> ${result}");
    if (result != null &&
        result != "" &&
        result != "null" &&
        result != "500" &&
        !result.toString().contains("IDENTY_ERROR")) {
      debugPrint("convertedJson ===> ${jsonEncode(result)}");
      await showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (context) {
          return BiometricVerificationInprogrees(fingerScanData: result)
              .animate()
              .fade(duration: 400.ms, curve: Curves.fastOutSlowIn)
              .scale(duration: 400.ms, curve: Curves.fastOutSlowIn);
        },
      );
    } else if (result == "500" || result == "") {
      debugPrint("result ===> ${result}");
    } else if (result == null || result == "null") {
      if (!Platform.isAndroid) {
        AppDialogs.showErrorDialog(
          message: "Biometric scan failed. Please try again.",
        );
      }
    } else if (result.toString().contains("IDENTY_ERROR")) {
      List<String> parts = result.toString().split(':');
      if (parts.length > 1) {
        // CommonLogics.showError(error: parts[1].trim());
        AppDialogs.showErrorDialog(message: parts[1].trim());
      }
    } else {
      AppDialogs.showErrorDialog(message: "Something went wrong");
      // CommonLogics.showError(
      //     error: Languages.of(Get.context!).(Labels.Something_went_wrong));
    }
  }

  List<int> getMissingFingers() {
    List<int> missingFingers = [];
    if (Platform.isAndroid) {
      if (isIndexFingerMissing.value) {
        missingFingers.add(0);
      } else {
        missingFingers.add(1);
      }
      if (isMiddleFingerMissing.value) {
        missingFingers.add(0);
      } else {
        missingFingers.add(1);
      }
      if (isRingFingerMissing.value) {
        missingFingers.add(0);
      } else {
        missingFingers.add(1);
      }
      if (isLittleFingerMissing.value) {
        missingFingers.add(0);
      } else {
        missingFingers.add(1);
      }
    } else if (Platform.isIOS) {
      if (isLeftHandSelected.value) {
        if (!isIndexFingerMissing.value) missingFingers.add(2);
        if (!isMiddleFingerMissing.value) missingFingers.add(3);
        if (!isRingFingerMissing.value) missingFingers.add(4);
        if (!isLittleFingerMissing.value) missingFingers.add(5);
      } else if (isRightHandSelected.value) {
        if (!isIndexFingerMissing.value) missingFingers.add(7);
        if (!isMiddleFingerMissing.value) missingFingers.add(8);
        if (!isRingFingerMissing.value) missingFingers.add(9);
        if (!isLittleFingerMissing.value) missingFingers.add(10);
      }
    }
    debugPrint("missingFingers ===> $missingFingers");
    return missingFingers;
  }

  //-------------------------------NIDA SELECTION SCREEN-----------------------------//

  /// it is used in [NidaSelectionScreen] to know which nida type is selected.
  RxString selectedNidaType = "".obs;

  /// used in [EnterNidaNumberScreen] to control the nida number field
  TextEditingController nidaNumberController = TextEditingController();

  void nidaControllerListener() {
    nidaNumberController.addListener(() {
      nidaNumberString.value = nidaNumberController.text;
    });
  }

  /// used to update the ui in [EnterNidaNumberScreen]
  RxString nidaNumberString = "".obs;

  /// used to store nida card image
  RxString documentImagePath = "".obs;

  /// used to store user's face image path
  RxString faceImagePath = "".obs;

  /// used to store user's device name
  RxString deviceName = "".obs;

  Rx<NidaCardModel> nidaCardDetails = NidaCardModel().obs;

  //---------------------------------NIDA CARD SCAN FLOW------------------------------//

  //---------------------------------NFC Passport scanning FLOW------------------------------//

  TextEditingController passportNumberController = TextEditingController();
  TextEditingController passportDOBController = TextEditingController();
  TextEditingController passportExpiryDateController = TextEditingController();
  Rx<PassportScanningModel> passportScanningData = PassportScanningModel().obs;
  XFile? nfcPassportImage;
  XFile? nfcSignatureImage;
  bool accountOpeningUsingPassport = false;

  String yyMMddDateParser({required String date}) {
    if (date.length == 6) {
      final year = int.parse(date.substring(0, 2));
      final month = int.parse(date.substring(2, 4));
      final day = int.parse(date.substring(4, 6));

      // Convert 2-digit year to 4-digit year
      final fullYear = year >= 50 ? 1900 + year : 2000 + year;

      final parsedDate = DateTime(fullYear, month, day);
      final formatted = DateFormat('yyyy-MM-dd').format(parsedDate);
      debugPrint("Formatted: $formatted");
      return formatted;
    } else {
      return "";
    }
  }

  Future<XFile> saveImageFile({
    required String base64Image,
    required String fileName, // without extension
  }) async {
    final sanitized = base64Image.replaceAll('\n', '').replaceAll('\r', '');
    final bytes = base64Decode(sanitized);

    // Decode image
    img.Image? decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) {
      throw Exception("Something went wrong");
    }

    // Encode as JPEG with desired quality
    final jpgBytes = img.encodeJpg(
      decodedImage,
      quality: 90,
    ); // You can adjust quality
    const extension = '.jpg';

    // Save to local file
    final dir = await file.getApplicationDocumentsDirectory();
    final imagePath = '${dir.path}/$fileName$extension';
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(jpgBytes);

    return XFile(imageFile.path, name: "$fileName$extension");
  }

  Future<void> processPassportResult({required dynamic result}) async {
    debugPrint("processPassportResult scan result ==========> $result");

    try {
      passportScanningData.value = PassportScanningModel.fromJson(result);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage:
            "RegistrationController.processPassportResult (JSON Parsing) failed",
        extraData: [
          {"inputResult": result},
        ],
      );

      AppDialogs.showErrorDialog(
        message: "Json Parsing Failed: " + e.toString(),
      );
      // CommonLogics.showError(error: "Json Parsing Failed: " + e.toString());
      // FirebaseCrashlytics.instance.log("Json Parsing Failed: " + e.toString());
      // FirebaseCrashlytics.instance.recordError(
      //   "Json Parsing Failed: " + e.toString(),
      //   stack,
      // );
    }
    // passportScanningData.value =
    //     PassportScanningModel.fromJson(nfcPassportData);

    if (passportScanningData.value.statusCode == 200) {
      debugPrint("convertedJson ===> ${jsonEncode(result)}");
      try {
        nfcPassportImage = await saveImageFile(
          base64Image: passportScanningData.value.data?.image ?? "",
          fileName: "passport",
        );
        nfcSignatureImage = await saveImageFile(
          base64Image: passportScanningData.value.data?.signatureImage ?? "",
          fileName: "signature",
        );
      } catch (e, stackTrace) {
        ErrorReporter.instance.report(
          error: e,
          stackTrace: stackTrace,
          customMessage:
              "RegistrationController.processPassportResult (Image Decode) failed",
          extraData: [],
        );

        AppDialogs.showErrorDialog(
          message: "Image Decode Failed: " + e.toString(),
        );
        // CommonLogics.showError(error: "Image Decode Failed: " + e.toString());
        // FirebaseCrashlytics.instance.log(
        //   "Image Decode Failed: " + e.toString(),
        // );
        // FirebaseCrashlytics.instance.recordError(
        //   "Image Decode Failed: " + e.toString(),
        //   stack,
        // );
      }

      /// passportScanConfirmationScreen navigation pending
      Get.to(() => PassportScanConfirmationScreen());
    } else if (passportScanningData.value.statusCode == 400) {
      AppDialogs.showErrorDialog(
        message: passportScanningData.value.msg ?? "data",
      );
    } else {
      debugPrint(
        "Passport scanning error ===> ${passportScanningData.value.msg ?? ""}",
      );
    }
  }

  TextEditingController passportFieldCityController = TextEditingController();
  TextEditingController passportFieldAddressController =
      TextEditingController();

  Future<void> uploadNFCPasportData() async {
    try {
      // showLoaderDialog(Get.context);
      Loader.instance.show();

      final userData = UserController().userData.value;

      FingerScanModel?
      response = await registrationRepository.uploadNFCPasportData(
        // userId: userData.id ?? "",
        mobileNumber: userData.user?.mobileNumber?.toString() ?? "",
        passportNumber: passportScanningData.value.data?.documentNumber ?? "",
        firstName: passportScanningData.value.data?.name ?? "",
        lastName: passportScanningData.value.data?.surname ?? "",
        dateOfBirth: yyMMddDateParser(
          date: (passportScanningData.value.data?.dob ?? "").trim(),
        ),
        expiry: yyMMddDateParser(
          date: (passportScanningData.value.data?.dateOfExpiry ?? "").trim(),
        ),
        gender: passportScanningData.value.data?.gender ?? "",
        nationality: passportScanningData.value.data?.nationality ?? "",
        placeOfBirth: passportScanningData.value.data?.placeOfBirth ?? "",
        passportImage: nfcPassportImage?.path ?? "",
        passportSignatureImage: nfcSignatureImage?.path ?? "",
        state: passportFieldCityController.text,
        residenceAddress: passportFieldAddressController.text,
      );

      Loader.instance.hide();

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        accountOpeningUsingPassport = true;
        if (nfcPassportImage != null &&
            (nfcPassportImage?.path.isNotEmpty ?? false)) {
          nidaImageFile = File(nfcPassportImage!.path);
        }

        Get.offAll(
            ()=> const FaceDetectionScreen(leadingIcon: AppAssets.home),
        );
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "RegistrationController.uploadNFCPasportData failed",
        extraData: [],
      );

      // hideLoaderDialog();
      Loader.instance.hide();
      debugPrint("Exception in uploadNFCPasportData: $e");
    }
  }

  //---------------------------------NFC Passport scanning FLOW------------------------------//

  /// used to get card data such as nida card number, first name, last name, expiry date, etc.
  Future<NidaCardModel?> getCardData({
    required List<String> cardDetails,
  }) async {
    String removeCharactersBeforeColon(String input) {
      int colonIndex = input.indexOf(": ");
      if (colonIndex != -1) {
        return input.substring(colonIndex + 2).trim(); // Add 2 to skip ": "
      } else {
        // Return the original string if ": " is not found
        return getLastWord(input.trim()).trim();
      }
    }

    NidaCardModel? model = NidaCardModel();

    if (cardDetails.isNotEmpty) {
      for (String data in cardDetails) {
        if (model.firstName == null &&
            (data.toLowerCase().contains("kwanža") ||
                data.toLowerCase().contains("jina la"))) {
          model.firstName = getLastWord(data);
        }

        if (model.lastName == null && data.toLowerCase().contains("mwisho")) {
          model.lastName = getLastWord(data);
        }

        if (model.sex == null &&
            (data.toLowerCase().contains("jinsi") ||
                data.toLowerCase().contains(": m") ||
                data.toLowerCase().contains(": f"))) {
          if (data.length < 10) {
            model.sex = getLastWord(data);
          }
        }

        if (model.nidaCardNumber == null &&
            (countHyphens(data.toLowerCase()) > 2)) {
          String cardNumber = data.replaceAll(RegExp(r'[a-zA-Z]'), '');
          if (cardNumber.replaceAll("-", "").contains(RegExp(r'^\d+$'))) {
            model.nidaCardNumber = cardNumber;
          }
        }

        if (model.expiry == null &&
            (data.toLowerCase().contains("matumizi") ||
                data.toLowerCase().contains("matumaiz") ||
                data.toLowerCase().contains("mwisho wa"))) {
          model.expiry = removeCharactersBeforeColon(data);
        }

        if (model.nation == null) {
          if (data.toLowerCase().contains("tanzania")) {
            model.nation = data;
          } else {
            model.nation = "Tanzania";
          }
        }

        if (model.dob == null && data.toLowerCase().contains("kuzaliwa")) {
          model.dob = removeCharactersBeforeColon(data);
        }
      }
    }

    if ((model.dob == null || (model.dob?.isEmpty ?? true)) &&
        model.nidaCardNumber != null) {
      List<String> parts = model.nidaCardNumber?.split('-') ?? [];
      String dateFromNidaCard = parts[0];
      model.dob = formatDateFromNidaCard(dateFromNidaCard).toUpperCase();
    }

    return model;
  }

  //---------------------------DOCUMENT CONFIMRATION SCREEN---------------------------//

  /// this variable is used to control the ui depending on the attempted count
  RxInt documentConfirmationAttemptedCount = 0.obs;

  /// used to know is document verification method is manual or automatic
  RxBool isManualDocumentVerification = false.obs;

  /// used to store the selected user type id
  RxString selectedUserTypeId = "".obs;

  //--------------------------NIDA DOCUMENT CONFIRMATION SCREEN-------------------------//

  TextEditingController nidaDocumentFirstNameController =
      TextEditingController();

  // TextEditingController nidaDocumentNationController = TextEditingController();

  TextEditingController nidaDocumentLastNameController =
      TextEditingController();

  TextEditingController nidaDocumentBithdateController =
      TextEditingController();

  TextEditingController nidaDocumentSelectedGenderController =
      TextEditingController();

  String externalId = generateRandomString(msg: "ExternalId is");

  // ClientSuccessModel clientData = ClientSuccessModel();

  // CardDetailsModel cardDetails = CardDetailsModel();

  GetUserFromSelcomIdResponseModel? selcomIdUserData;

  Future<bool> getUserFromSelcomId({
    required GetUserFromSelcomIdRequest request,
  }) async {
    // showLoaderDialog(Get.context);
    Loader.instance.show();
    final response = await RegistrationRepository.getUserFromSelcomAPI(request);

    // hideLoaderDialog();

    Loader.instance.hide();
    if (response?.response?.statusCode == 200 ||
        response?.response?.statusCode == 201) {
      selcomIdUserData = response;
      return true;
    }

    AppDialogs.showErrorDialog(message: response?.response?.message ?? "");
    // CommonLogics.showError(error: response?.response?.message ?? "");

    return false;
  }

  UserDataExistSelcomIdModel? userDataExistSelcomIdResponse;

  Future<bool> selcomIdUserDataExist() async {
    isDataGotFromSelcomId = false;
    if (UserController().accessToken.isEmpty) {
      return false;
    }

    // showLoaderDialog(Get.context);
    Loader.instance.show();

    final response = await RegistrationRepository.selcomIdUserDataExistAPI(
      SelcomIdUserDataExistRequest(
        mobileNumber:
            UserController().userData.value.user?.mobileNumber?.toString() ??
            "",
      ),
    );
    Loader.instance.hide();
    if (response?.response?.statusCode == 200 ||
        response?.response?.statusCode == 201) {
      userDataExistSelcomIdResponse = response;
      if (response?.response?.response?.nidaVerified ?? false) {
        isDataGotFromSelcomId = true;
        return true;
      } else if (response?.response?.response?.passportVerified ?? false) {
        isDataGotFromSelcomId = true;
        return true;
      } else {
        return false;
      }
    }

    return false;
  }

  AddUserToSelcomIdResponseModel? addUserToSelcomIdResponse;

  Future<bool> addUserToSelcomId({
    required AddUserToSelcomIdRequest request,
  }) async {
    final response = await RegistrationRepository.addUserToSelcomIdAPI(request);

    if (response?.response?.statusCode == 200 ||
        response?.response?.statusCode == 201) {
      addUserToSelcomIdResponse = response;
      return true;
    }

    AppDialogs.showErrorDialog(
      message: kDebugMode
          ? (response?.message ?? "")
          : "Something went wrong! Please try again later.",
    );

    // CommonLogics.showError(
    //   error: AppInfo().buildType == BuildType.TESTING
    //       ? (response?.message ?? "")
    //       : Languages
    //       .of(Get.context!)
    //       .errorTryAgainLater,
    //   errorAction: () {
    //      Get.back();;
    //   },
    // );
    return false;
  }

  bool isDataGotFromSelcomId = false;

  bool get selcomIdTesting => false;

  void onTapNidaNumber() async {
    Get.to(() => const BiometricAuthenticationScreen());
  }

  /// used to upload ocr documents
  void uploadOcrDocuments() async {
    try {
      externalId = generateRandomString(msg: "ExternalId is");
      String email = "";
      String address = "";
      String city = "";
      String firstName = "";
      String lastName = "";
      String gender = "";
      String dob = "";
      String nidaNumber = "";
      String passportNumber = "";
      final user = UserModel.fromJson(jsonDecode(await StorageService().read(StorageKeys.user)??""));

      if ( /*todo Features().selcomIdImpl*/ true) {
        if (isDataGotFromSelcomId) {
          if (verifySelfieResponse.response?.nidaNumber?.isNotEmpty ?? false) {
            nidaNumber = verifySelfieResponse.response?.nidaNumber ?? "";
            email = user?.emailId ?? "";
            address = verifySelfieResponse.response?.residentStreet ?? "";
            city = verifySelfieResponse.response?.residentRegion ?? "";
            firstName = verifySelfieResponse.response?.firstName ?? "";
            lastName = verifySelfieResponse.response?.lastName ?? "";
            gender = verifySelfieResponse.response?.gender ?? "";
            dob = DateFormat("yyyy-MM-dd").format(
              verifySelfieResponse.response?.dateOfBirth ?? DateTime.now(),
            );
          } else if (verifySelfieResponse
                  .response
                  ?.passport
                  ?.number
                  ?.isNotEmpty ??
              false) {
            passportNumber =
                verifySelfieResponse.response?.passport?.number ?? "";
            email = user?.emailId ?? "";
            address =
                verifySelfieResponse.response?.passport?.residenceAddress ?? "";
            city = verifySelfieResponse.response?.passport?.state ?? "";
            firstName =
                verifySelfieResponse.response?.passport?.firstName ?? "";
            lastName = verifySelfieResponse.response?.passport?.lastName ?? "";
            gender = verifySelfieResponse.response?.passport?.gender ?? "";
            dob = DateFormat("yyyy-MM-dd").format(
              DateTime.tryParse(
                    verifySelfieResponse.response?.passport?.dateOfBirth ?? '',
                  ) ??
                  DateTime.now(),
            );
          } else {
            if (selcomIdUserData?.response?.response?.nidaNumber?.isNotEmpty ??
                false) {
              nidaNumber =
                  selcomIdUserData?.response?.response?.nidaNumber ?? "";
              email =user?.emailId ?? "";
              address =
                  selcomIdUserData?.response?.response?.residentStreet ?? "";
              city = selcomIdUserData?.response?.response?.residentRegion ?? "";
              firstName = selcomIdUserData?.response?.response?.firstName ?? "";
              lastName = selcomIdUserData?.response?.response?.lastName ?? "";
              gender = selcomIdUserData?.response?.response?.gender ?? "";
              dob = DateFormat("yyyy-MM-dd").format(
                selcomIdUserData?.response?.response?.dateOfBirth ??
                    DateTime.now(),
              );
            } else {
              passportNumber =
                  selcomIdUserData?.response?.response?.passport?.number ?? "";
              email = user?.emailId ?? "";
              address =
                  selcomIdUserData
                      ?.response
                      ?.response
                      ?.passport
                      ?.residenceAddress ??
                  "";
              city =
                  selcomIdUserData?.response?.response?.passport?.state ?? "";
              firstName =
                  selcomIdUserData?.response?.response?.passport?.firstName ??
                  "";
              lastName =
                  selcomIdUserData?.response?.response?.passport?.lastName ??
                  "";
              gender =
                  selcomIdUserData?.response?.response?.passport?.gender ?? "";
              dob = DateFormat("yyyy-MM-dd").format(
                DateTime.tryParse(
                      selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.dateOfBirth ??
                          '',
                    ) ??
                    DateTime.now(),
              );
            }
          }
        } else {
          if (nidaNumberString.value.isNotEmpty) {
            nidaNumber = nidaNumberString.value.trim();
            email = registerAddressInfoEmailController.text;
            address = registerAddressInfoAddressController.text;
            city = registerAddressInfoCityController.text;
            firstName = nidaDocumentFirstNameController.text.trim();
            lastName = nidaDocumentLastNameController.text.trim();
            gender = nidaDocumentSelectedGenderController.text;
            dob = nidaDocumentBithdateController.text;
          } else {

            final userData = UserModel.fromJson(jsonDecode(await StorageService().read(StorageKeys.user)??""));

            passportNumber =
                passportScanningData.value.data?.documentNumber ?? "";
            firstName = passportScanningData.value.data?.name ?? "";
            lastName = passportScanningData.value.data?.surname ?? "";
            dob = yyMMddDateParser(
              date: (passportScanningData.value.data?.dob ?? "").trim(),
            );
            gender = passportScanningData.value.data?.gender ?? "";
            email = userData.emailId ?? "";
            address = passportFieldAddressController.text;
            city = passportFieldCityController.text;
          }
        }
      }

      ClientSuccessModel?
      response = await registrationRepository.uploadOcrDocumentApi(
        email: email,
        address: (address.isNotEmpty) ? address : "DAR ES SALAAM",
        city: (city.isNotEmpty) ? city : "DAR ES SALAAM",
        referralCode: registerAddressInfoReferralController.text,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        dob: dob,
        externalId: externalId,
        msisdn:
            "+255 ${user?.mobileNumber.toString()}",
      );

      if (response != null && response.response?.resultcode == "200") {
        UserAddCardDetailModel? userAddCardDetailsResponse =
            await registrationRepository.userAddCardDetail(
              userId: user?.id ?? "",
              clientId:
                  response.response?.data?.first.clientId.toString() ?? "",
              accountNumber: response.response?.data?.first.accountNo ?? "",
              address: (address.isNotEmpty) ? address : "DAR ES SALAAM",
              city: (city.isNotEmpty) ? city : "DAR ES SALAAM",
              firstName: firstName,
              lastName: lastName,
              gender: gender,
              dob: dob,
              passportNumber: passportNumber,

              // pass status 1 for registration
              status: "1",
              nidaNumber: nidaNumber.replaceAll("-", "").replaceAll(" ", ""),
            );

        if (userAddCardDetailsResponse != null &&
            userAddCardDetailsResponse.statusCode == 200) {
          // WalletController().walletData(userAddCardDetailsResponse);
          // SetCardLimitController().setCurrentLimit();
          // WalletController().checkCardExpiry();
          bool isCardCreated = await walletController.createCard(
            userDetails: userAddCardDetailsResponse,
            showSuccessDialog: false,
            showLoader: false,
          );

          if (!isCardCreated) {
            Get.back();
            ;
            return;
          }

          WalletCreditRefundAmountModel? walletCreditRefundAmountResponse =
              await registrationRepository.walletCreditUserRefundAmountAPI(
                userId: user?.id ?? "",
                clientId:
                    response.response?.data?.first.clientId.toString() ?? "",
                accountNumber: response.response?.data?.first.accountNo ?? "",
              );

          // if (walletCreditRefundAmountResponse?.statusCode == 200) {}
          Get.to(
            () => const VerificationSuccessScreen(),
          );
        } else {
          Get.back();
          AppDialogs.showErrorDialog(
            message: kDebugMode
                ? (userAddCardDetailsResponse?.message ?? "")
                : "Something went wrong! Please try again later.",
          );
        }
      } else {
        Get.back();
        ;
        AppDialogs.showErrorDialog(
          message: kDebugMode
              ? (response?.response?.message ?? "")
              : "Something went wrong! Please try again later.",
        );
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "RegistrationController.uploadOcrDocuments failed",
        extraData: [
          {"externalId": externalId},
        ],
      );

      debugPrint("exception: $e");

      Get.back();
      ;

      AppDialogs.showErrorDialog(
        message: kDebugMode
            ? e.toString()
            : "Something went wrong! Please try again later.",
      );
    }
  }

  TextEditingController registerAddressInfoAddressController =
      TextEditingController();

  TextEditingController registerAddressInfoEmailController =
      TextEditingController();

  TextEditingController registerAddressInfoCityController =
      TextEditingController();

  TextEditingController registerAddressInfoReferralController =
      TextEditingController();

  /// used to validate the address info screen textfields
  bool validateRegisterAddressInfo() {
    if (registerAddressInfoAddressController.text.isEmpty) {
      AppDialogs.showErrorDialog(
        message: "Please enter your residential address",
      );
      // showDialogWithMessage(
      //   message: Languages
      //       .of(Get.context!)
      //       .pleaseEnterYourResidentialAddress,
      //   firstButtonText: Languages
      //       .of(Get.context!)
      //       .ok,
      //   firstButtonColor: AppColors.loaderColor,
      //   firstButtonBorderRadius: 6.0.h,
      //   firstButtonHeight: 45.0.h,
      //   firstFontWeight: FontWeight.w700,
      //   firstButtonTextColor: AppColors.whiteColor,
      // );
      return false;
    }
    if (registerAddressInfoEmailController.text.isEmpty) {
      AppDialogs.showErrorDialog(message: "Please enter valid email address");
      // showDialogWithMessage(
      //   message: Languages
      //       .of(Get.context!)
      //       .pleaseEnterEmailAddress,
      //   firstButtonText: Languages
      //       .of(Get.context!)
      //       .ok,
      //   firstButtonColor: AppColors.loaderColor,
      //   firstButtonBorderRadius: 6.0.h,
      //   firstButtonHeight: 45.0.h,
      //   firstFontWeight: FontWeight.w700,
      //   firstButtonTextColor: AppColors.whiteColor,
      // );
      return false;
    }
    if (!RegExp(
      r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(registerAddressInfoEmailController.text)) {
      AppDialogs.showErrorDialog(message: "Please enter valid email address");
      // showDialogWithMessage(
      //   message: Languages
      //       .of(Get.context!)
      //       .Please_Enter_valid_Email_address,
      //   firstButtonText: Languages
      //       .of(Get.context!)
      //       .ok,
      //   firstButtonColor: AppColors.loaderColor,
      //   firstButtonBorderRadius: 6.0.h,
      //   firstButtonHeight: 45.0.h,
      //   firstFontWeight: FontWeight.w700,
      //   firstButtonTextColor: AppColors.whiteColor,
      // );
      return false;
    }
    if (registerAddressInfoCityController.text.isEmpty) {
      AppDialogs.showErrorDialog(message: "Please select city");
      // showDialogWithMessage(
      //   message: Languages
      //       .of(Get.context!)
      //       .plz_sel_city,
      //   firstButtonText: Languages
      //       .of(Get.context!)
      //       .ok,
      //   firstButtonColor: AppColors.loaderColor,
      //   firstButtonBorderRadius: 6.0.h,
      //   firstButtonHeight: 45.0.h,
      //   firstFontWeight: FontWeight.w700,
      //   firstButtonTextColor: AppColors.whiteColor,
      // );
      return false;
    }
    return true;
  }

  void registerAddressInfoSubmit() {
    if (validateRegisterAddressInfo()) {
      Get.to(() => WalletWaitingScreen());
    }
  }

  RxBool isLeftHandSelected = true.obs;
  RxBool isRightHandSelected = false.obs;
  RxBool isIndexFingerMissing = false.obs;
  RxBool isMiddleFingerMissing = false.obs;
  RxBool isRingFingerMissing = false.obs;
  RxBool isLittleFingerMissing = false.obs;
  RxBool flashStatus = false.obs;

  String get getIdentyLicense {
    if (Platform.isAndroid) {
      switch (AppInfo().package.packageName) {
        case "com.app.dukadirect":
          return "3871-com.app.dukadirect-31-03-2025";
        case "com.app.dukadirect.dev":
          return "3872-com.app.dukadirect.dev-31-03-2025";
        default:
          return "3871-com.app.dukadirect-31-03-2025";
      }
    } else {
      switch (AppInfo().package.packageName) {
        case "com.duka.direct":
          return "3873-com.duka.direct-31-03-2025.lic";
        case "com.duka.direct.dev":
          return "3874-com.duka.direct.dev-31-03-2025.lic";
        default:
          return "3873-com.duka.direct-31-03-2025.lic";
      }
    }
  }

  /// used to store document data
  Rx<FingerScanModel> uploadDocumentsModel = FingerScanModel().obs;

  /// used to upload finger scan data by calling api
  Future<void> uploadFingerScanData({
    required Map<String, dynamic> fingerScanData,
  }) async {
    // showLoaderDialog(Get.context);

    FingerScanModel? response = await registrationRepository.fingerScan(
      nidaNumber: nidaNumberString.value,
      fingerData: fingerScanData,
    );

    // hideLoaderDialog();

    if (response != null && (response.data?.isNotEmpty ?? false)) {
      uploadDocumentsModel.value = response;
      uploadDocumentsModel.refresh();
      documentConfirmationAttemptedCount = 0.obs;

      var userData = UserModel.fromJson(jsonDecode(await StorageService().read(StorageKeys.user)??""));

      for (DocumentDetail document
          in response.data?.firstOrNull?.documentDetails ??
              <DocumentDetail>[]) {
        String documentKey = document.key?.toLowerCase() ?? "";

        if (documentKey.contains("first")) {
          nidaDocumentFirstNameController.text = document.value ?? "";
          continue;
        }
        if (documentKey.contains("last")) {
          nidaDocumentLastNameController.text = document.value ?? "";
          continue;
        }
        if (documentKey.contains("gender")) {
          nidaDocumentSelectedGenderController.text = document.value ?? "";
          continue;
        }
        if (documentKey.contains("birth")) {
          nidaDocumentBithdateController.text = document.value ?? "";
          continue;
        }
        if (documentKey.contains("city")) {
          registerAddressInfoCityController.text = document.value ?? "";
          continue;
        }
        if (documentKey.contains("address")) {
          registerAddressInfoAddressController.text = document.value ?? "";
          continue;
        }
      }

      registerAddressInfoEmailController.text = userData.emailId ?? "";

      String nidaImage =
          uploadDocumentsModel.value.data?[0].profilePicture ?? "";

      final finalNidaImage = await resolveImageUrl(nidaImage);

      ImageHandler imageHandler = ImageHandler();
      nidaImageFile = await imageHandler.decodeAndSaveImage(
        base64String: finalNidaImage,
        fileName: 'decoded_image.png',
      );

      // hideLoaderDialog();

      Loader.instance.hide();
      Get.back();
      ;

      Get.to(() => DocumentConfirmationScreen());
    } else {
      Get.back();
      ;

      AppDialogs.showErrorDialog(message: response?.message ?? "");
      // CommonLogics.showError(error: response?.message ?? "");
    }
  }

  void confirmAndSubmitDocuments() async {
    // appNavigator.to(
    //   () => FaceDetectionScreen(),
    // );
    Get.offAll(() => FaceDetectionScreen(leadingIcon: AppAssets.home));
  }

  String verifyDocumentPath = "";
  File? nidaImageFile;

  int verifyDocumentSelfieCalledCount = 0;

  Future<void> createSupportTicket() async {
    // showLoaderDialog(Get.context);
    Loader.instance.show();
    final userData = UserModel.fromJson(
      jsonDecode(await StorageService().read(StorageKeys.user)??""),
    );
    final response = await RegistrationRepository.createSupportTicketAPI(
      CreateSupportTicketSelcomIdRequest(
        title: "Selfie Verification Match Failed Despite Existing Selcom ID",
        description:
            "Users encounter a “Selfie Verification Match Failed” error even when their Selcom ID exists. This issue may arise due to mismatched facial data, poor image quality, or backend verification discrepancies.",
        mobileNumber:
        userData.mobileNumber.toString() ?? "",
        selfieImage: await fileToBase64(verifyDocumentPath),
        selfieVerificationMatch:
            verifySelfieResponse.response?.selfieVerificationData?.similarity
                .toString() ??
            "0.0",
      ),
    );

    // hideLoaderDialog();
    Loader.instance.show();

    AppDialogs.showErrorDialog(
      message: response?.message ?? "",
      onConfirm: () {
        Get.offAll(() => HomeScreen(/*showNidaDialog: false*/));
      },
    );
    // CommonLogics.showError(
    //   error: response?.message ?? "",
    //   errorAction: () {
    //     appNavigator.offAll(HomeScreen(showNidaDialog: false));
    //   },
    // );
  }

  VerifySelfieResponseModel verifySelfieResponse = VerifySelfieResponseModel();

  Future<void> verifyDocumentSelfie() async {
    try {
      // showLoaderDialog(Get.context);
      Loader.instance.show();

      var data = await registrationRepository.verifySelfie(
        nidaImagePath: nidaImageFile?.path ?? "",
        selfieImagePath: verifyDocumentPath,
      );

      // hideLoaderDialog();
      Loader.instance.hide();
      data?.message = data.message?.replaceAll("docment", "document");

      if (data?.statusCode == 200) {
        verifySelfieResponse = data!;
        if ( /*todo Features().selcomIdImpl*/ true) {
          if (RegistrationController().isDataGotFromSelcomId) {
            if (data.response?.nidaNumber?.isNotEmpty ?? false) {
              Get.to(
                () => SelcomIdConfirmationScreen(
                  profilePicture: data.response?.profilePicture ?? "",
                  dateOfBirth: data.response?.dateOfBirth ?? DateTime.now(),
                  firstName: data.response?.firstName ?? "",
                  middleName: data.response?.middleName ?? "",
                  lastName: data.response?.lastName ?? "",
                  gender: data.response?.gender ?? "",
                  residentRegion: data.response?.residentRegion ?? "",
                  passportNumber: data.response?.passport?.number ?? "",
                  nationality: data.response?.passport?.nationality ?? "",
                  placeOfBirth: data.response?.passport?.placeOfBirth ?? "",
                  expirationDate: data.response?.passport?.dateOfExpiry ?? "",
                ),
              );
            } else if (data.response?.passport?.number?.isNotEmpty ?? false) {
              Get.to(
                () => SelcomIdConfirmationScreen(
                  profilePicture: data.response?.passport?.photo ?? "",
                  dateOfBirth:
                      DateTime.tryParse(
                        data.response?.passport?.dateOfBirth ?? "",
                      ) ??
                      DateTime.now(),
                  firstName: data.response?.passport?.firstName ?? "",
                  middleName: "",
                  lastName: data.response?.passport?.lastName ?? "",
                  gender: data.response?.passport?.gender ?? "",
                  residentRegion: data.response?.passport?.state ?? "",
                  residentAddress:
                      data.response?.passport?.residenceAddress ?? "",
                  passportNumber: data.response?.passport?.number ?? "",
                  nationality: data.response?.passport?.nationality ?? "",
                  placeOfBirth: data.response?.passport?.placeOfBirth ?? "",
                  expirationDate: data.response?.passport?.dateOfExpiry ?? "",
                ),
              );
            } else {
              final jsonUser = await StorageService().read(StorageKeys.user);
              final userData = UserModel.fromJson(jsonDecode(jsonUser ?? ""));
              final result = await getUserFromSelcomId(
                request: GetUserFromSelcomIdRequest(
                  mobileNumber: selcomIdTesting
                      // ? "711410410" // edward
                      ? "767004294" // grado
                      : userData.mobileNumber.toString() ?? "",
                ),
              );
              if (result) {
                if (selcomIdUserData
                        ?.response
                        ?.response
                        ?.passport
                        ?.number
                        ?.isNotEmpty ??
                    false) {
                  Get.to(
                    () => SelcomIdConfirmationScreen(
                      profilePicture:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.photo ??
                          "",
                      dateOfBirth:
                          DateTime.tryParse(
                            selcomIdUserData
                                    ?.response
                                    ?.response
                                    ?.passport
                                    ?.dateOfBirth ??
                                '',
                          ) ??
                          DateTime.now(),
                      firstName:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.firstName ??
                          "",
                      lastName:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.lastName ??
                          "",
                      gender:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.gender ??
                          "",
                      middleName: "",
                      residentRegion:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.state ??
                          "",
                      residentAddress:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.residenceAddress ??
                          "",
                      passportNumber:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.number ??
                          "",
                      nationality:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.nationality ??
                          "",
                      placeOfBirth:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.placeOfBirth ??
                          "",
                      expirationDate:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.dateOfExpiry ??
                          "",
                    ),
                  );
                } else {
                  Get.to(
                    () => SelcomIdConfirmationScreen(
                      profilePicture:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.profilePicture ??
                          "",
                      dateOfBirth:
                          selcomIdUserData?.response?.response?.dateOfBirth ??
                          DateTime.now(),
                      firstName:
                          selcomIdUserData?.response?.response?.firstName ?? "",
                      lastName:
                          selcomIdUserData?.response?.response?.lastName ?? "",
                      gender:
                          selcomIdUserData?.response?.response?.gender ?? "",
                      middleName:
                          selcomIdUserData?.response?.response?.middleName ??
                          "",
                      residentRegion:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.residentRegion ??
                          "",
                      passportNumber:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.number ??
                          "",
                      nationality:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.nationality ??
                          "",
                      placeOfBirth:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.placeOfBirth ??
                          "",
                      expirationDate:
                          selcomIdUserData
                              ?.response
                              ?.response
                              ?.passport
                              ?.dateOfExpiry ??
                          "",
                    ),
                  );
                }
              } else {
                AppDialogs.showErrorDialog(message: "Something went wrong");
              }
            }
          } else {
            Get.to(() => const WalletWaitingScreen());
          }
        }
      } else {
        int count = 3
        /*todo adminController
                .adminControlFeature
                .value
                .response
                ?.verifySelfieMaxCount ??
                2*/
        ;

        if (verifyDocumentSelfieCalledCount > count) {
          AppDialogs.showErrorDialog(
            message: data?.message ?? "",
            buttonText: "Contact Support",

            onConfirm: () {
              createSupportTicket();
            },
          );
        } else {
          AppDialogs.showErrorDialog(message: data?.message ?? "");
        }
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "RegistrationController.verifyDocumentSelfie failed",
        extraData: [
          {"selfiePath": verifyDocumentPath, "nidaPath": nidaImageFile?.path},
        ],
      );

      // hideLoaderDialog();
      Loader.instance.hide();
      debugPrint("verifyDocumentSelfie Exception: $e");
    }
  }
}
