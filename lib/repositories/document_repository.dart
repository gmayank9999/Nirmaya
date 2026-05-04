import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/document_model.dart';

class DocumentRepository {
  final _client = ApiClient();

  Future<({List<DocumentModel> documents, int total})> list({
    String? patientId,
    String? treatmentId,
    String? category,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (patientId != null) 'patientId': patientId,
      if (treatmentId != null) 'treatmentId': treatmentId,
      if (category != null) 'category': category,
    };
    final res = await _client.get(ApiEndpoints.documents, params: params);
    final data = res['data'] as List<dynamic>;
    final pagination = res['pagination'] as Map<String, dynamic>?;
    return (
      documents: data
          .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination?['total'] as int? ?? data.length,
    );
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.document(id));
  }

  Future<DocumentModel> upload({
    required String filePath,
    required String patientId,
    String? treatmentId,
    String? visitId,
    required String category,
  }) async {
    final res = await _client.multipartPost(
      ApiEndpoints.documentsUpload,
      fields: {
        'patientId': patientId,
        'category': category,
        if (treatmentId != null) 'treatmentId': treatmentId,
        if (visitId != null) 'visitId': visitId,
      },
      fileField: 'file',
      filePath: filePath,
    );
    return DocumentModel.fromJson(res['data'] as Map<String, dynamic>);
  }
}
