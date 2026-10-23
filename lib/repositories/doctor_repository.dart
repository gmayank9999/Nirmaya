import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/doctor_model.dart';

class DoctorRepository {
  final _client = ApiClient();

  Future<List<DoctorModel>> list({bool includeInactive = false}) async {
    final res = await _client.get(
      ApiEndpoints.doctors,
      params: {if (includeInactive) 'includeInactive': 'true'},
    );
    return (res['data'] as List<dynamic>)
        .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DoctorModel> create(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.doctors, body: body);
    return DoctorModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<DoctorModel> update(String id, Map<String, dynamic> body) async {
    final res = await _client.patch(ApiEndpoints.doctor(id), body: body);
    return DoctorModel.fromJson(res['data'] as Map<String, dynamic>);
  }
}
