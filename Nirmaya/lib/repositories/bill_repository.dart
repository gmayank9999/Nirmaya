import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class BillRepository {
  final _client = ApiClient();

  Future<Map<String, dynamic>> generate({required String treatmentId}) async {
    final res = await _client.post(
      ApiEndpoints.generateBill,
      body: {'treatmentId': treatmentId},
    );
    return res['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final res = await _client.get(ApiEndpoints.bill(id));
    return res['data'] as Map<String, dynamic>;
  }
}
