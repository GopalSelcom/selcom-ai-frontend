import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Service to fetch road-locked directions from Google Maps Directions API.
/// Used as a fallback when the backend provides insufficient route geometry.
class DirectionService {
  DirectionService._();

  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const String _apiKey = 'AIzaSyAX9RqWoCIadDeRC7N38oV5ZE43APeinWU';

  static final Dio _dio = Dio();

  /// Fetches a road route between [origin] and [destination].
  /// Returns a list of LatLng points representing the road path.
  static Future<List<LatLng>> getRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'origin': '${origin.latitude},${origin.longitude}',
          'destination': '${destination.latitude},${destination.longitude}',
          'key': _apiKey,
          'mode': 'driving',
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final points = routes[0]['overview_polyline']['points'] as String;
            return _decodePolyline(points);
          }
        }
      }
      return [origin, destination];
    } catch (e) {
      return [origin, destination];
    }
  }

  /// Decodes a Google Maps encoded polyline string.
  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return polyline;
  }
}
