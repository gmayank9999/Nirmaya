import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/dashboard_patient_model.dart';
import '../models/dashboard_summary_model.dart';

class DashboardRepository {
  final _client = ApiClient();

  Future<DashboardSummaryModel> getSummary() async {
    final res = await _client.get(ApiEndpoints.dashboardSummary);
    return DashboardSummaryModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<({List<DashboardPatientModel> patients, int total})> listPatients({
    String? search,
    String? status,
    String? sortBy,
    String? sortOrder,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _client.get(
      ApiEndpoints.dashboardPatients,
      params: {
        'page': '$page',
        'limit': '$limit',
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
        if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
      },
    );
    final data = res['data'] as List<dynamic>;
    final pagination = res['pagination'] as Map<String, dynamic>?;
    return (
      patients: data
          .map((e) => DashboardPatientModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination?['total'] as int? ?? data.length,
    );
  }

  Future<Map<String, dynamic>> getPatient(String id) async {
    final res = await _client.get(
      ApiEndpoints.dashboardPatient,
      params: {'id': id},
    );
    return res['data'] as Map<String, dynamic>;
  }
}
