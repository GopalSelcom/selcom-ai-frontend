import '../constants/currency_code.dart';
import '../../shared/data/countries_phone_data.dart';
import '../../shared/utils/country_region_defaults.dart';
import '../../shared/utils/currency_formatter.dart';
import 'storage_service.dart';

/// Persists selected ISO country (same catalog as `duka_direct_4_flutter` [Countries]) and drives display currency.
class AppRegionService {
  String _iso = CommonValues.countryCode;

  CountryData get selected => Countries.findByIsoCode(_iso);

  /// Always **Tanzania (TZ)** after a full app restart — do not restore last phone country.
  /// Selection still updates for the current session via [setSelectedCountry].
  Future<void> restore() async {
    _iso = CommonValues.countryCode;
    CurrencyFormatter.setRegionDisplayConfig(
      CountryRegionDefaults.currencyConfigForIso(_iso),
    );
    await StorageService().write(
      StorageKeys.selectedPhoneCountryId,
      _iso,
    );
  }

  Future<void> setSelectedCountry(CountryData country) async {
    _iso = country.code;
    CurrencyFormatter.setRegionDisplayConfig(
      CountryRegionDefaults.currencyConfigForIso(_iso),
    );
    await StorageService().write(
      StorageKeys.selectedPhoneCountryId,
      _iso,
    );
  }
}
