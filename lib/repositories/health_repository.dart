import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class HealthRepository {
  final _client = ApiClient();

  Future<Map<String, dynamic>> getHealth() async {
    final res = await _client.get(ApiEndpoints.health);
    return res['data'] as Map<String, dynamic>;
  }
}
