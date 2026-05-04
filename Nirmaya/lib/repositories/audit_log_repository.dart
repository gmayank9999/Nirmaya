import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class AuditLogRepository {
  final _client = ApiClient();

  Future<({List<Map<String, dynamic>> logs, int total})> list({
    String? entity,
    String? entityId,
    String? action,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _client.get(
      ApiEndpoints.auditLogs,
      params: {
        'page': '$page',
        'limit': '$limit',
        if (entity != null && entity.isNotEmpty) 'entity': entity,
        if (entityId != null && entityId.isNotEmpty) 'entityId': entityId,
        if (action != null && action.isNotEmpty) 'action': action,
        if (dateFrom != null && dateFrom.isNotEmpty) 'dateFrom': dateFrom,
        if (dateTo != null && dateTo.isNotEmpty) 'dateTo': dateTo,
      },
    );
    final data = res['data'] as List<dynamic>;
    final pagination = res['pagination'] as Map<String, dynamic>?;
    return (
      logs: data.cast<Map<String, dynamic>>(),
      total: pagination?['total'] as int? ?? data.length,
    );
  }
}
