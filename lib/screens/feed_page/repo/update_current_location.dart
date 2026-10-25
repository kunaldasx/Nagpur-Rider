import 'package:nagpur_rider/config/api_routes.dart';
import '../../../config/api_base_helper.dart';

class UpdateCurrentLocationRepo {
  Future<Map<String, dynamic>> updateCurrentLocation({
    double? latitude,
    double? longitude,
  }) => ApiBaseHelper.post(
    url: updateCurrentLocationApi,
    useAuthToken: true,
    requestTimeout: const Duration(seconds: 15),
    body: {'latitude': latitude, 'longitude': longitude},
  );
}
