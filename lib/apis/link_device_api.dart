import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/res/endpoints.dart';

class LinkDeviceRepository {
  Future<Map<String, dynamic>> saveSecretKey(String secretKey) async {
    try {
      final res = await ApiService().getData(
          path: Endpoints.saveSecretKey,
          queryParameters: {'secret_key': secretKey});
      return res;
    } catch (_) {
      return {};
    }
  }
}
