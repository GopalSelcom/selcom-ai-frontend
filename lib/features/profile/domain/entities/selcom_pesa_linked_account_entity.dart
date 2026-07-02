import '../../../../shared/utils/selcom_pesa_phone_utils.dart';

enum SelcomPesaLinkStatus {
  pending,
  linked,
  rejected,
  unlinked,
  unknown;

  static SelcomPesaLinkStatus fromApi(String? raw) {
    switch (raw?.trim().toUpperCase()) {
      case 'PENDING':
        return SelcomPesaLinkStatus.pending;
      case 'LINKED':
        return SelcomPesaLinkStatus.linked;
      case 'REJECTED':
        return SelcomPesaLinkStatus.rejected;
      case 'UNLINKED':
        return SelcomPesaLinkStatus.unlinked;
      default:
        return SelcomPesaLinkStatus.unknown;
    }
  }
}

class SelcomPesaLinkedAccountEntity {
  const SelcomPesaLinkedAccountEntity({
    this.id = '',
    required this.status,
    required this.countryCode,
    required this.mobileNumber,
  });

  final String id;
  final SelcomPesaLinkStatus status;
  final String countryCode;
  final String mobileNumber;

  bool get isLinked => status == SelcomPesaLinkStatus.linked;

  String get normalizedMobileDigits => canonicalTzMobileDigits(mobileNumber);
}
