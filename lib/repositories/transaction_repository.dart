import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final _client = ApiClient();

  Future<({List<TransactionModel> transactions, int total})> list({
    String? treatmentId,
    String? patientId,
    String? dateFrom,
    String? dateTo,
    String? paymentMode,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (treatmentId != null) 'treatmentId': treatmentId,
      if (patientId != null) 'patientId': patientId,
      if (dateFrom != null) 'dateFrom': dateFrom,
      if (dateTo != null) 'dateTo': dateTo,
      if (paymentMode != null) 'paymentMode': paymentMode,
    };
    final res = await _client.get(ApiEndpoints.transactions, params: params);
    final data = res['data'] as List<dynamic>;
    final pagination = res['pagination'] as Map<String, dynamic>?;
    return (
      transactions: data
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination?['total'] as int? ?? data.length,
    );
  }

  Future<TransactionModel> create(Map<String, dynamic> body) async {
    final res = await _client.post(ApiEndpoints.transactions, body: body);
    return TransactionModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> update(
      String id, Map<String, dynamic> body) async {
    final res = await _client.patch(ApiEndpoints.transaction(id), body: body);
    return res['data'] as Map<String, dynamic>;
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.transaction(id));
  }
}
