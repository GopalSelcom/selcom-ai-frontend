import 'dart:convert';

GeocodeResponse geocodeResponseFromJson(String str) => GeocodeResponse.fromJson(json.decode(str));

class GeocodeResponse {
    final List<GeocodeResult>? results;
    final String? status;

    GeocodeResponse({
        this.results,
        this.status,
    });

    factory GeocodeResponse.fromJson(Map<String, dynamic> json) => GeocodeResponse(
        results: json["results"] == null ? [] : List<GeocodeResult>.from(json["results"]!.map((x) => GeocodeResult.fromJson(x))),
        status: json["status"],
    );
}

class GeocodeResult {
    final List<GeocodeAddressComponent>? addressComponents;
    final String? formattedAddress;
    final GeocodeGeometry? geometry;
    final List<GeocodeNavigationPoint>? navigationPoints;
    final String? placeId;
    final GeocodePlusCode? plusCode;
    final List<String>? types;

    GeocodeResult({
        this.addressComponents,
        this.formattedAddress,
        this.geometry,
        this.navigationPoints,
        this.placeId,
        this.plusCode,
        this.types,
    });

    factory GeocodeResult.fromJson(Map<String, dynamic> json) => GeocodeResult(
        addressComponents: json["address_components"] == null ? [] : List<GeocodeAddressComponent>.from(json["address_components"]!.map((x) => GeocodeAddressComponent.fromJson(x))),
        formattedAddress: json["formatted_address"],
        geometry: json["geometry"] == null ? null : GeocodeGeometry.fromJson(json["geometry"]),
        navigationPoints: json["navigation_points"] == null ? [] : List<GeocodeNavigationPoint>.from(json["navigation_points"]!.map((x) => GeocodeNavigationPoint.fromJson(x))),
        placeId: json["place_id"],
        plusCode: json["plus_code"] == null ? null : GeocodePlusCode.fromJson(json["plus_code"]),
        types: json["types"] == null ? [] : List<String>.from(json["types"]!.map((x) => x)),
    );
}

class GeocodeAddressComponent {
    final String? longName;
    final String? shortName;
    final List<String>? types;

    GeocodeAddressComponent({
        this.longName,
        this.shortName,
        this.types,
    });

    factory GeocodeAddressComponent.fromJson(Map<String, dynamic> json) => GeocodeAddressComponent(
        longName: json["long_name"],
        shortName: json["short_name"],
        types: json["types"] == null ? [] : List<String>.from(json["types"]!.map((x) => x)),
    );
}

class GeocodeGeometry {
    final GeocodeLocation? location;
    final String? locationType;
    final GeocodeViewport? viewport;

    GeocodeGeometry({
        this.location,
        this.locationType,
        this.viewport,
    });

    factory GeocodeGeometry.fromJson(Map<String, dynamic> json) => GeocodeGeometry(
        location: json["location"] == null ? null : GeocodeLocation.fromJson(json["location"]),
        locationType: json["location_type"],
        viewport: json["viewport"] == null ? null : GeocodeViewport.fromJson(json["viewport"]),
    );
}

class GeocodeLocation {
    final double? lat;
    final double? lng;

    GeocodeLocation({
        this.lat,
        this.lng,
    });

    factory GeocodeLocation.fromJson(Map<String, dynamic> json) => GeocodeLocation(
        lat: json["lat"]?.toDouble(),
        lng: json["lng"]?.toDouble(),
    );
}

class GeocodeViewport {
    final GeocodeLocation? northeast;
    final GeocodeLocation? southwest;

    GeocodeViewport({
        this.northeast,
        this.southwest,
    });

    factory GeocodeViewport.fromJson(Map<String, dynamic> json) => GeocodeViewport(
        northeast: json["northeast"] == null ? null : GeocodeLocation.fromJson(json["northeast"]),
        southwest: json["southwest"] == null ? null : GeocodeLocation.fromJson(json["southwest"]),
    );
}

class GeocodeNavigationPoint {
    final GeocodeNavLocation? location;
    final List<String>? restrictedTravelModes;

    GeocodeNavigationPoint({
        this.location,
        this.restrictedTravelModes,
    });

    factory GeocodeNavigationPoint.fromJson(Map<String, dynamic> json) => GeocodeNavigationPoint(
        location: json["location"] == null ? null : GeocodeNavLocation.fromJson(json["location"]),
        restrictedTravelModes: json["restricted_travel_modes"] == null ? [] : List<String>.from(json["restricted_travel_modes"]!.map((x) => x)),
    );
}

class GeocodeNavLocation {
    final double? latitude;
    final double? longitude;

    GeocodeNavLocation({
        this.latitude,
        this.longitude,
    });

    factory GeocodeNavLocation.fromJson(Map<String, dynamic> json) => GeocodeNavLocation(
        latitude: json["latitude"]?.toDouble(),
        longitude: json["longitude"]?.toDouble(),
    );
}

class GeocodePlusCode {
    final String? compoundCode;
    final String? globalCode;

    GeocodePlusCode({
        this.compoundCode,
        this.globalCode,
    });

    factory GeocodePlusCode.fromJson(Map<String, dynamic> json) => GeocodePlusCode(
        compoundCode: json["compound_code"],
        globalCode: json["global_code"],
    );
}
