import '../../../../core/network/api_service.dart';
import '../../../../core/network/urls.dart';
import '../models/share_link_model.dart';

abstract class RideShareRemoteDataSource {
  Future<ShareLinkModel> generateShareLink(String rideId);
  Future<void> revokeShareLink(String rideId);
}

class RideShareRemoteDataSourceImpl implements RideShareRemoteDataSource {
  @override
  Future<ShareLinkModel> generateShareLink(String rideId) async {
    final response = await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.shareRide(rideId),
        method: ApiMethod.post,
      ),
    );

    final data = Map<String, dynamic>.from(response.data['data'] ?? {});
    return ShareLinkModel.fromJson(data);
  }

  @override
  Future<void> revokeShareLink(String rideId) async {
    await ApiService().call(
      request: ApiRequest(
        endpoint: URLS.ride.shareRide(rideId),
        method: ApiMethod.delete,
      ),
    );
  }
}
