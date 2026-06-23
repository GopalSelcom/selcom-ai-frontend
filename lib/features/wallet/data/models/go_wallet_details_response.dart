import '../../domain/entities/wallet_details_entity.dart';

class GoWalletDetailsResponseModel {
  GoWalletDetailsResponseModel({
    this.statusCode,
    this.message,
    this.response,
  });

  final int? statusCode;
  final String? message;
  final GoWalletDetailsData? response;

  factory GoWalletDetailsResponseModel.fromJson(Map<String, dynamic> json) {
    final payload = json['response'];
    return GoWalletDetailsResponseModel(
      statusCode: json['status_code'] as int?,
      message: json['message']?.toString(),
      response: payload is Map<String, dynamic>
          ? GoWalletDetailsData.fromJson(payload)
          : null,
    );
  }

  bool get isSuccess => statusCode == 200 && response != null;
}

class GoWalletDetailsData {
  GoWalletDetailsData({
    this.accountNo,
    this.firstName,
    this.lastName,
    this.address,
    this.city,
    this.dob,
    this.maskedCard,
    this.expiry,
    this.status,
    this.isPrepaid,
    this.limitAmount,
    this.createdOn,
  });

  final String? accountNo;
  final String? firstName;
  final String? lastName;
  final String? address;
  final String? city;
  final String? dob;
  final String? maskedCard;
  final String? expiry;
  final int? status;
  final bool? isPrepaid;
  final num? limitAmount;
  final DateTime? createdOn;

  factory GoWalletDetailsData.fromJson(Map<String, dynamic> json) {
    return GoWalletDetailsData(
      accountNo: json['account_no']?.toString(),
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      dob: json['dob']?.toString(),
      maskedCard: json['masked_card']?.toString(),
      expiry: json['expiry']?.toString(),
      status: json['status'] as int?,
      isPrepaid: json['is_prepaid'] as bool?,
      limitAmount: json['limit_amount'] as num?,
      createdOn: json['created_on'] == null
          ? null
          : DateTime.tryParse(json['created_on'].toString()),
    );
  }

  WalletDetailsEntity toEntity() {
    return WalletDetailsEntity(
      accountNo: accountNo?.trim() ?? '',
      firstName: firstName,
      lastName: lastName,
      address: address,
      city: city,
      dob: dob,
      maskedCard: maskedCard,
      expiry: expiry,
      status: status,
      isPrepaid: isPrepaid ?? true,
      limitAmount: limitAmount,
      createdOn: createdOn,
    );
  }
}
