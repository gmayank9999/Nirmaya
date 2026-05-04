import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/followup_model.dart';

class FollowupRepository {
  final _client = ApiClient();

  Future<({List<FollowupModel> followups, int total})> list({
    String? patientId,
    String? treatmentId,
    String? status,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (patientId != null) 'patientId': patientId,
      if (treatmentId != null) 'treatmentId': treatmentId,
      if (status != null) 'status': status,
    };
    final res = await _client.get(ApiEndpoints.followups, params: params);
    final data = res['data'] as List<dynamic>;
    final pagination = res['pagination'] as Map<String, dynamic>?;
    return (
      followups: data
          .map((e) => FollowupModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination?['total'] as int? ?? data.length,
    );
  }

  Future<FollowupModel> create(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.followups, body: body);
    return FollowupModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<FollowupModel> update(String id, Map<String, dynamic> body) async {
    final res = await _client.patch(ApiEndpoints.followup(id), body: body);
    return FollowupModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.followup(id));
  }
}
