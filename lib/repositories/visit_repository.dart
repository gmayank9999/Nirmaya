import 'dart:convert';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/visit_model.dart';

class VisitRepository {
  final _client = ApiClient();

  Future<({List<VisitModel> visits, int total})> list({
    required String treatmentId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'treatmentId': treatmentId,
      'page': '$page',
      'limit': '$limit',
      if (dateFrom != null) 'dateFrom': dateFrom,
      if (dateTo != null) 'dateTo': dateTo,
    };
    final res = await _client.get(ApiEndpoints.visits, params: params);
    final data = res['data'] as List<dynamic>;
    final pagination = res['pagination'] as Map<String, dynamic>?;
    return (
      visits: data
          .map((e) => VisitModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination?['total'] as int? ?? data.length,
    );
  }

  Future<VisitModel> create(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.visits, body: body);
    return VisitModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final res = await _client.get(ApiEndpoints.visit(id));
    return res['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createWithDetails({
    required Map<String, String> fields,
    List<String> reportFilePaths = const [],
    List<String> reportNames = const [],
    List<String> prescriptionFilePaths = const [],
    List<String> prescriptionNames = const [],
  }) async {
    final payloadFields = <String, String>{
      ...fields,
      if (reportNames.isNotEmpty) 'reportNames': jsonEncode(reportNames),
      if (prescriptionNames.isNotEmpty)
        'prescriptionNames': jsonEncode(prescriptionNames),
    };
    final res = await _client.multipartPostFiles(
      ApiEndpoints.visitsWithDetails,
      fields: payloadFields,
      files: {
        if (reportFilePaths.isNotEmpty) 'reportFiles': reportFilePaths,
        if (prescriptionFilePaths.isNotEmpty)
          'prescriptionFiles': prescriptionFilePaths,
      },
    );
    final data = res['data'] as Map<String, dynamic>;
    
    // We import TransactionModel dynamically to avoid circular dependencies if any,
    // actually we already have the transaction details, let's just return the raw map
    // or we can import transaction_model.dart at the top. 
    // Let's import it at the top and parse.
    return data;
  }

  Future<VisitModel> update(String id, Map<String, dynamic> body) async {
    final res = await _client.patch(ApiEndpoints.visit(id), body: body);
    return VisitModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.visit(id));
  }
}
