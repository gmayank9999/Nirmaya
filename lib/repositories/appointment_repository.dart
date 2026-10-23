import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/appointment_model.dart';

class AppointmentRepository {
  final _client = ApiClient();

  Future<List<AppointmentModel>> list({
    String? doctorId,
    required String from,
    required String to,
  }) async {
    final res = await _client.get(ApiEndpoints.appointments, params: {
      'from': from,
      'to': to,
      if (doctorId != null) 'doctorId': doctorId,
    });
    return (res['data'] as List<dynamic>)
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppointmentModel> create(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.appointments, body: body);
    return AppointmentModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<AppointmentModel> update(String id, Map<String, dynamic> body) async {
    final res = await _client.patch(ApiEndpoints.appointment(id), body: body);
    return AppointmentModel.fromJson(res['data'] as Map<String, dynamic>);
  }
}
