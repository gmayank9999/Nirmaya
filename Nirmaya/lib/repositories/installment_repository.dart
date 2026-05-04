import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/installment_model.dart';

class InstallmentRepository {
  final _client = ApiClient();

  Future<({List<InstallmentModel> installments, int total})> list({
    String? treatmentId,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (treatmentId != null) 'treatmentId': treatmentId,
      if (status != null) 'status': status,
    };
    final res = await _client.get(ApiEndpoints.installments, params: params);
    final data = res['data'] as List<dynamic>;
    final pagination = res['pagination'] as Map<String, dynamic>?;
    return (
      installments: data
          .map((e) => InstallmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination?['total'] as int? ?? data.length,
    );
  }

  Future<InstallmentModel> create(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.installments, body: body);
    return InstallmentModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<InstallmentModel> update(String id, Map<String, dynamic> body) async {
    final res = await _client.patch(ApiEndpoints.installment(id), body: body);
    return InstallmentModel.fromJson(res['data'] as Map<String, dynamic>);
  }
}
