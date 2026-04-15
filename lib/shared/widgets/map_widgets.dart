/// Map stack for the app: one place to import the embedded Google Map surface
/// and related chrome (GPS, header, address card, profile chip).
///
/// **Policy:** Feature screens must use [AppGoogleMap] — not the raw
/// `google_maps_flutter` [GoogleMap] widget. Extend [AppGoogleMap] in this
/// folder if new cross-screen parameters are needed.
///
/// ```dart
/// import 'package:selcom_rides_frontend/shared/widgets/map_widgets.dart';
/// // AppGoogleMap(...), AppMapService..., AppMapGpsButton, AppMapTopHeader, ...
/// ```
library;

export 'package:selcom_rides_frontend/core/services/app_map_service.dart';

export 'app_google_map.dart';
export 'app_map_gps_button.dart';
export 'app_map_location_summary_card.dart';
export 'app_map_profile_chip.dart';
export 'app_map_top_header.dart';
