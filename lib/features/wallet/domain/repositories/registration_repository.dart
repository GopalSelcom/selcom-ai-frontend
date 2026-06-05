import 'dart:convert';
import 'dart:io';


import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_service.dart';
import '../../../../core/network/expected_client_http_status.dart';
import '../../../../core/network/urls.dart';
import '../../../../core/services/error_reporting/error_reporter.dart';
import '../../presentation/models/registration/add_user_to_selcom_id_request.dart';
import '../../presentation/models/registration/add_user_to_selcom_id_response_model.dart';
import '../../presentation/models/registration/client_success_model.dart';
import '../../presentation/models/registration/create_card_model.dart';
import '../../presentation/models/registration/create_support_ticket_response.dart';
import '../../presentation/models/registration/finger_scan_model.dart';
import '../../presentation/models/registration/get_user_from_selcom_id_request.dart';
import '../../presentation/models/registration/get_user_from_selcom_id_response.dart';
import '../../presentation/models/registration/get_wallet_refund_amount_model.dart';
import '../../presentation/models/registration/selcom_id_contact_support_request.dart';
import '../../presentation/models/registration/selcom_id_user_data_exist_request.dart';
import '../../presentation/models/registration/selcom_id_user_data_exist_response.dart';
import '../../presentation/models/registration/verify_selfie_response.dart';
import '../../../payment/domain/models/wallet_other_payment_topup_request.dart';
import '../../../payment/presentation/models/wallet_other_payment_topup_response.dart';
import '../../presentation/models/user_add_card_details_model.dart';


class Params {
  static String id = "id";
  static String applicationJson = "application/json";
  static String latitude = "latitude";
  static String longitude = "longitude";
  static String deviceToken = "device_token";
  static String deviceType = "device_type";
  static String appUuid = "app_uuid";
  static String accessToken = "access_token";
  static String authorization = "authorization";
  static String addressId = "address_id";
  static String language = "language";
  static String isReceive = "is_receive";
  static String encryptionDisabled = "encryption_disabled";

  //bill pay
  static String utilityRef = "utilityref";
  static String utilityCode = "utilitycode";
  static String enableLookup = "enable_lookup";
  static String price = "price";
  static String productId = "product_id";
  static String utilityRefNo = "utilityRefNo";
  static String topupLabel = "topupLabel";
  static String comment = "comment";
  static String transId = "transid";
  static String orderId = "order_id";
  static String allCartId = "allCart_id";
  static String totalPrice = "total_price";
  static String promoCode = "promo_code";
  static String promoCodeFor = "promo_code_for";
  static String removePromo = "remove_promo";
  static String paymentMode = "payment_mode";
  static String paymentToken = "payment_token";
  static String sqrAmount = "sqr_amount";
  static String ussdPhoneNumber = "ussd_phone_number";
  static String cancelReason = "cancel_reason";
  static String full = "full";
  static String types = "types";
  static String currency = "currency";
  static String type = "type";
  static String sendAmount = "sendAmount";
  static String newCard = "newCard";
  static String isCheckout = "isCheckout";
  static String isProceed = "isProceed";
  static String identityId = "identityId";
  static String cardToken = "card_token";
  static String billingAddressId = "billing_address_id";
  static String email = "email";
  static String mobileNumber = "mobile_number";
  static String countryCode = "country_code";
  static String cardBin = "cardBin";
  static String fName = "fname";
  static String lName = "lname";
  static String address = "address";
  static String address1 = "address1";
  static String address2 = "address2";
  static String city = "city";
  static String state = "state";
  static String country = "country";
  static String postalCode = "postalcode";
  static String countryName = "country_name";
  static String countryId = "country_id";

  static String cardNumber = "card_number";
  static String cardType = "card_type";
  static String cardCvn = "card_cvn";
  static String cardExpiryDate = "card_expiry_date";
  static String module = "module";
  static String limit = "limit";
  static String page = "page";

  ///gas

  static String gasProviderId = "gas_provider_id";

  static const externalId = "externalId";
  static const account = "account";
  static const cardId = "card_id";
  static const pinSalt = "pinsalt";
  static const pinHash = "pinhash";
  static const token = "token";
  static const isTest = "is_test";
  static const amount = "amount";
  static const serviceType = "serviceType";
  static const paymentReference = "paymentReference";
  static const categoryCode = "categoryCode";
  static const category = "category";
  static const description = "description";
  static const clientId = "clientId";
  static const sortBy = "sortBy";
  static const sortType = "sortType";
  static const pageSize = "pageSize";
  static const pageIndex = "pageIndex";

  static const firstName = "first_name";
  static const lastName = "last_name";
  static const first_name = "first_name";
  static const last_name = "last_name";
  static const gender = "gender";
  static const referralCode = "referralCode";
  static const locationCity = "city";
  static const locationStreet = "street";
  static const locationCountry = "country";
  static const locationGpsCoordinates = "gpsCoordinates";
  static const active = "active";
  static const vendor = "vendor";
  static const msisdn = "msisdn";
  static String expiry = "expiry";
  static String dateOfBirth = "date_of_birth";
  static String dateOfExpiry = "date_of_expiry";
  static String residenceAddress = "residence_address";
  static String documentNumber = "document_number";
  static String passportNumber = "passport_number";
  static String nationality = "nationality";
  static String passportProfileImage = "passport_profile_image";
  static String signatureImage = "signature_image";
  static String placeOfBirth = "place_of_birth";
  static String dob = "dob";
  static String userId = "userId";
  static String userId_ = "user_id";
  static String requestId = "requestid";
  static String status = "status";
  static String remarks = "remarks";
  static String walletAccount = "wallet_account";
  static String walletClientId = "wallet_client_id";

  // static String USER_ID => "user_id";

  //Bima
  static String registrationNo = "registration_no";
  static String brokerId = "brokerID";
  static String branchId = "branchID";
  static String compId = "compID";
  static String companyId = "company_id";
  static String seating = "seating";
  static String coverType = "cover_type";
  static String vehicleClass = "vehicleClass";
  static String serviceMsgType = "serviceMsgType";
  static String nidaNumber = "nida_number";
  static String idNumber = "id_number";
  static String appType = "appType";
  static String lookupType = "lookupType";
  static String registrationType = "registration_type";
  static String periodTo = "period_to";
  static String periodFrom = "period_from";
  static String vatAmount = "vat_amount";
  static String commencementDate = "commencement_date";
  static String sumInsured = "sum_insured";
  static String premiumAmount = "premium_amount";
  static String insurerName = "insurerName";
  static String insuredName = "insuredName";
  static String providerId = "provider_id";
  static String identityType = "identity_type";
  static String id_type = "id_type";
  static String insurerId = "insurerId";
  static String motorData = "motorData";
  static String isActive = "isActive";

  static String idExpiry = "id_expiry";

  static String phone ="phone";
}

class RegistrationRepository {
  // Future<CityConfigModel?> cityConfig() async {
  //   try {
  //     Map<String, String> headers =
  //         await getHeaders(accessTokenRequired: true, contentTypeEnabled: true);

  //     http.Response response = await HttpService.apiService(
  //       headers: headers,
  //       endpoint: URLS.CITY_CONFIG_API,
  //       method: METHOD.post,
  //     );

  //     var data = jsonDecode(response.body);

  //     if (data != null) {
  //       return cityConfigModelFromJson(jsonEncode(data));
  //     }
  //     return null;
  //   } catch (e) {
  //     debugPrint("$e");
  //   }
  //   return null;
  // }

  Future<ClientSuccessModel?> uploadOcrDocumentApi({
    required String email,
    String? referralCode,
    String? expiry,
    required String idNumber,
    required String city,
    required String address,
    required String firstName,
    required String lastName,
    required String gender,
    required String dob,
    required String externalId,
    required String msisdn,
  }) async {
    final body = {
      Params.first_name: firstName,
      Params.last_name: lastName,
      Params.id_type:"NATIONAL_ID",
      Params.idNumber: idNumber,
      Params.idExpiry:expiry,
      Params.dob: dob,
      Params.phone: msisdn,
      Params.address1: address,
      Params.address2:city
    };
    try {
      var response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.createWallet,
          method: ApiMethod.post,
          body: body,
        ),
      );

      return ClientSuccessModel.fromJson(response.data);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "RegistrationRepository.uploadOcrDocumentApi failed",
        extraData: [body],
      );
      debugPrint("uploadOcrDocumentApi Exception: $e");
      return null;
    }
  }

  static Future<UserAddCardDetailModel?> checkWalletRegistrationAPI({
    required bool skipError,
  }) async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.walletDetails,
          method: ApiMethod.get,
          errorPresentationType: skipError
              ? ErrorPresentationType.none
              : ErrorPresentationType.dialog,
        ),
      );

      final statusCode = response.statusCode;
      if (statusCode == 200 && response.data != null) {
        final model = UserAddCardDetailModel.fromJson(response.data);
        if (model.response != null) {
          return model;
        }
        return null;
      }

      if (isExpectedClientBusinessHttpStatus(statusCode)) {
        return null;
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "RegistrationRepository.checkWalletRegistrationAPI failed",
        extraData: [{"skipError": skipError}],
      );
      debugPrint("checkWalletRegistrationAPI Exception: $e");
    }
    return null;
  }

  static Future<WalletOtherPaymentTopupResponse?> walletOtherPaymentTopupAPI({
    required WalletOtherPaymentTopupRequest request,
  }) async {
    try {
      final response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.walletOtherPaymentMethod,
          method: ApiMethod.post,
          body: request.toJson(),
          showLoader: true,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return WalletOtherPaymentTopupResponse.fromJson(response.data);
      }

      if (response.data is Map<String, dynamic>) {
        return WalletOtherPaymentTopupResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage:
            'RegistrationRepository.walletOtherPaymentTopupAPI failed',
        extraData: [request.toJson()],
      );
      debugPrint('walletOtherPaymentTopupAPI Exception: $e');
    }
    return null;
  }

  // static Future<GetWalletRefundAmountModel?> checkWalletRefundAmountAPI({
  //   required String userId,
  //   required bool skipError,
  // }) async {
  //   final body = {Params.userId_: userId};
  //   try {
  //     var response = await ApiService().call(
  //       request: ApiRequest(
  //         endpoint: URLS.wallet.getWalletRefundAmount,
  //         method: ApiMethod.post,
  //         body: body,
  //
  //         errorPresentationType: skipError
  //             ? ErrorPresentationType.none
  //             : ErrorPresentationType.dialog,
  //       ),
  //     );
  //     return GetWalletRefundAmountModel.fromJson(response.data);
  //   } catch (e, stackTrace) {
  //     ErrorReporter.instance.report(
  //       error: e,
  //       stackTrace: stackTrace,
  //       customMessage: "RegistrationRepository.checkWalletRefundAmountAPI failed",
  //       extraData: [body],
  //     );
  //     debugPrint("checkWalletRefundAmountAPI Exception: $e");
  //     return null;
  //   }
  // }

//   Future<CreateCardModel?> createCard({
//     required String city,
//     required String address,
//     required String firstName,
//     required String lastName,
//     required String gender,
//     required String dob,
//     required String msisdn,
//     required String account,
//     required String transId,
//     required String productCode,
//   }) async
//   {
//     /*
//     not been used
//
//      String formattedTimestamp = CommonLogics.getCurrentDateTime();
//     debugPrint("formattedTimestamp----> $formattedTimestamp");
//
//     // Map<String, String> headers = {};
//     Map<String, String> headers = await getHeaders(
//       accessTokenRequired: true,
//       contentTypeEnabled: true,
//     );
//
//
//     String keysSeparatedByComma = body.keys.join(',');
//
//     debugPrint("keysSeparatedByComma------> $keysSeparatedByComma");
//
//     String digest = await CommonLogics.computeSignature(
//       body,
//       keysSeparatedByComma,
//       formattedTimestamp,
//       adminController
//               .adminControlFeature
//               .value
//               .response
//               ?.walletCredentials
//               ?.vcnApiSecret ??
//           "",
//     );
//
//     debugPrint("digest-----> $digest");
//
//     // headers = {
//     //   HttpHeaders.authorizationHeader: "SELCOM $authorizationHeaderKey",
//     //   Params.Content_Type: Params.application_json,
//     //   Params.Timestamp: formattedTimestamp,
//     //   Params.Digest: digest,
//     //   "Digest-Method": "HS256",
//     //   Params.SignedFields: keysSeparatedByComma,
//     // };
// */
//
//     Map<String, dynamic> body = {
//       // Params.firstName: firstName,
//       // Params.lastName: lastName,
//       "first_name": firstName,
//       "last_name": lastName,
//       Params.gender: gender.toUpperCase(),
//       Params.dob: dob,
//       // Params.locationCity: city,
//       "city": city,
//       "address": address,
//       // Params.locationStreet: address,
//       // Params.locationCountry: "TZ",
//       "nationality": "TZ",
//       Params.vendor: "",
//       /* todo adminController
//               .adminControlFeature
//               .value
//               .response
//               ?.walletCredentials
//               ?.vcnVendor ??
//           ""*/
//       Params.msisdn: msisdn,
//       Params.account: account,
//       "product_code": productCode,
//       "transid": transId,
//       "pin": "",
//       /*todo adminController
//               .adminControlFeature
//               .value
//               .response
//               ?.walletCredentials
//               ?.vcnPin ??
//           ""*/
//     };
//
//     try {
//       var response = await ApiService().call(
//         request: ApiRequest(
//           endpoint: URLS.wallet.walletCreateCard,
//           method: ApiMethod.post,
//           body: body,
//         ),
//       );
//
//       return CreateCardModel.fromJson(response.data);
//     } catch (e, stackTrace) {
//       ErrorReporter.instance.report(
//         error: e,
//         stackTrace: stackTrace,
//         customMessage: "RegistrationRepository.createCard failed",
//         extraData: [body],
//       );
//       debugPrint("createCard Exception: $e");
//       return null;
//     }
//   }


  // Future<CardDetailsModel?> fetchVcnCardDetails({
  //   required String vcnUrl,
  // }) async
  // {
  //   // String endPoint = vcnUrl.substring(vcnUrl.lastIndexOf("/"), vcnUrl.length);
  //   try {
  //     var response = await ApiService().call(
  //       request: ApiRequest(
  //         module: Module.wallet,
  //         endpoint: "",
  //         customBaseUrl: vcnUrl,
  //         method: ApiMethod.get,
  //         version: "",
  //       ),
  //     );
  //
  //     debugPrint(
  //       "wallet/show_vcn | Original Response: $vcnUrl response: ${response.data}",
  //     );
  //
  //     return CardDetailsModel.fromJson(jsonDecode(response.data));
  //   } catch (e, stackTrace) {
  //     ErrorReporter.instance.report(
  //       error: e,
  //       stackTrace: stackTrace,
  //       customMessage: "RegistrationRepository.fetchVcnCardDetails failed",
  //       extraData: [{"vcnUrl": vcnUrl}],
  //     );
  //
  //     debugPrint("wallet/show_vcn Exception: $e",);
  //     return null;
  //   }
  // }

  static Future<AddUserToSelcomIdResponseModel?> addUserToSelcomIdAPI(
    AddUserToSelcomIdRequest request,
  ) async {
    try {
      var response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.addUserToSelcomId,
          method: ApiMethod.post,
          body: request.toJson(),
        ),
      );

      return AddUserToSelcomIdResponseModel.fromJson(response.data);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "RegistrationRepository.addUserToSelcomIdAPI failed",
        extraData: [request.toJson()],
      );

      debugPrint(
        "addUserToSelcomIdAPI Exception: $e",
      );
      return null;
    }
  }

  static Future<UserDataExistSelcomIdModel?> selcomIdUserDataExistAPI(
    SelcomIdUserDataExistRequest request,
  ) async {
    try {
      var response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.userDataExistSelcomId,
          method: ApiMethod.post,
          body: request.toJson(),
        ),
      );

      return UserDataExistSelcomIdModel.fromJson(response.data);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "RegistrationRepository.selcomIdUserDataExistAPI failed",
        extraData: [request.toJson()],
      );

      debugPrint(
        "selcomIdUserDataExistAPI Exception: $e",
      );
      return null;
    }
  }

  static Future<GetUserFromSelcomIdResponseModel?> getUserFromSelcomAPI(
    GetUserFromSelcomIdRequest request,
  ) async {
    try {
      var response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.getUserFromSelcomId,
          method: ApiMethod.post,
          body: request.toJson(),
        ),
      );

      return GetUserFromSelcomIdResponseModel.fromJson(response.data);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "RegistrationRepository.getUserFromSelcomAPI failed",
        extraData: [request.toJson()],
      );

      debugPrint(
        "getUserFromSelcomAPI Exception: $e",
      );
      return null;
    }
  }

  Future<FingerScanModel?> fingerScan({
    required String nidaNumber,
    required Map<String, dynamic> fingerData,
  }) async {
    final body = {
      // "nationality_id": nationalityId,
      // "document_id": documentId,
      "nida_number": nidaNumber.replaceAll(" ", "").replaceAll("-", ""),
      // "finger_data": jsonEncode(fingerData),
      "finger_data": fingerData,

      // "user_id": SelcomBank.userId,

      // // extra parameters
      // "device_token": await CommonLogics.getDeviceToken(),
      // "device_type": Platform.isAndroid ? "Android" : "iOS",
      // "language_code": "en",
      // "lat": "0.0",
      // "lng": "0.0",
    };

    try {
      var response = await ApiService().call(
        request: ApiRequest(

          endpoint: URLS.wallet.fingerScan,
          method: ApiMethod.post,
          body: body,
        ),
      );
      FingerScanModel model = FingerScanModel.fromJson(response.data);
      return model;
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "RegistrationRepository.fingerScan failed",
        extraData: [body],
      );
      debugPrint("fingerScan Exception: $e");
      return null;
    }
  }

  static Future<CreateSupportTicketSelcomIdResponse?> createSupportTicketAPI(
    CreateSupportTicketSelcomIdRequest request,
  ) async {
    try {
      var response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.createSupportTicketSelcomId,
          method: ApiMethod.post,
          body: request.toJson(),
        ),
      );

      return CreateSupportTicketSelcomIdResponse.fromJson(response.data);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "RegistrationRepository.createSupportTicketAPI failed",
        extraData: [request.toJson()],
      );

      debugPrint(
        "createSupportTicketAPI Exception: $e",
      );
      return null;
    }
  }

  Future<VerifySelfieResponseModel?> verifySelfie({
    required String nidaImagePath,
    required String selfieImagePath,
  }) async {
    if (true) {
      return VerifySelfieResponseModel(statusCode: 200);
    }

    try {
      var response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.verifySelfie,
          method: ApiMethod.multipart,
          multipartFiles: [
            LocalMultipartFile(name: "nida_image", path: nidaImagePath),
            LocalMultipartFile(name: "selfie_image", path: selfieImagePath),
          ],
        ),
      );

      return VerifySelfieResponseModel.fromJson(response.data);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "RegistrationRepository.verifySelfie failed",
        extraData: [{"nidaPath": nidaImagePath, "selfiePath": selfieImagePath}],
      );

      debugPrint("verifySelfie Exception: $e", );
      return null;
    }
  }

  Future<FingerScanModel?> uploadNFCPasportData({
    required String passportNumber,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String expiry,
    required String gender,
    required String nationality,
    required String placeOfBirth,
    required String passportImage,
    required String passportSignatureImage,
    // required String userId,
    required String mobileNumber,
    required String state,
    required String residenceAddress,
  }) async {
    final body = {
      Params.passportNumber: passportNumber,
      Params.first_name: firstName,
      Params.last_name: lastName,
      Params.gender: gender,
      Params.dateOfBirth: dateOfBirth,
      Params.dateOfExpiry: expiry,
      Params.placeOfBirth: placeOfBirth,
      Params.nationality: nationality,
      Params.mobileNumber: mobileNumber,
      Params.state: state,
      Params.residenceAddress: residenceAddress,
    };
    try {
      var response = await ApiService().call(
        request: ApiRequest(
          endpoint: URLS.wallet.syncPassportData,
          method: ApiMethod.multipart,
          body: body,
          multipartFiles: [
            LocalMultipartFile(
              name: Params.passportProfileImage,
              path: passportImage,
            ),
            LocalMultipartFile(
              name: Params.signatureImage,
              path: passportSignatureImage,
            ),
          ],
        ),
      );

      return FingerScanModel.fromJson(response.data);
    } catch (e, stackTrace) {
      ErrorReporter.instance.report(
        error: e,
        stackTrace: stackTrace,
        customMessage: "RegistrationRepository.uploadNFCPasportData failed",
        extraData: [body],
      );
      debugPrint("uploadNFCPasportData Exception: $e");
      return null;
    }
  }
}
