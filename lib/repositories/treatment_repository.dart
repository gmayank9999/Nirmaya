import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/treatment_model.dart';

class TreatmentRepository {
  final _client = ApiClient();

  Future<({List<TreatmentModel> treatments, int total})> list({
    String? patientId,
    String? status,
    String? filter,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (patientId != null) 'patientId': patientId,
      if (status != null) 'status': status,
      if (filter != null) 'filter': filter,
    };
    final res = await _client.get(ApiEndpoints.treatments, params: params);
    final rawData = res['data'];
    final data = rawData is List
        ? rawData
        : (rawData is Map<String, dynamic>
            ? (rawData['treatments'] as List<dynamic>? ?? const [])
            : const []);
    final pagination = res['pagination'] as Map<String, dynamic>? ??
        (rawData is Map<String, dynamic>
            ? rawData['pagination'] as Map<String, dynamic>?
            : null);
    return (
      treatments: data
          .map((e) => TreatmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination?['total'] as int? ?? data.length,
    );
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final res = await _client.get(ApiEndpoints.treatment(id));
    return res['data'] as Map<String, dynamic>;
  }

  Future<TreatmentModel> create(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.treatments, body: body);
    return TreatmentModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<TreatmentModel> update(String id, Map<String, dynamic> body) async {
    final res = await _client.patch(ApiEndpoints.treatment(id), body: body);
    return TreatmentModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.treatment(id));
  }
}
