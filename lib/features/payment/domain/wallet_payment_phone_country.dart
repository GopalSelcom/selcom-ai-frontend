import '../../../shared/data/countries_phone_data.dart';

/// Tanzania (+255) only — Selcom Pesa and mobile-money wallet top-up numbers.
///
/// Country code is not derived from the user's profile or app region; these
/// payment rails require a Tanzanian mobile number.
abstract final class WalletPaymentPhoneCountry {
  WalletPaymentPhoneCountry._();

  static const String iso = 'TZ';
  static const String dialCodeDisplay = '+255';
  static const String dialCodeDigits = '255';

  static CountryData get country => Countries.findByIsoCode(iso);
}
