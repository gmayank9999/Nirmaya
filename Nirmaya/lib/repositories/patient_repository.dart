import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/patient_model.dart';

class PatientRepository {
  final _client = ApiClient();

  Map<String, String> _stringFields(Map<String, dynamic> body) {
    return body.map((key, value) => MapEntry(key, value.toString()));
  }

  Map<String, List<String>> _proofFiles({
    String? idProofFilePath,
    String? cghsFilePath,
    String? echsFilePath,
  }) {
    return {
      if (idProofFilePath != null) 'idProofFile': [idProofFilePath],
      if (cghsFilePath != null) 'cghsFile': [cghsFilePath],
      if (echsFilePath != null) 'echsFile': [echsFilePath],
    };
  }

  Future<({List<PatientModel> patients, int total})> list({
    String? search,
    String? gender,
    bool? hasIdProof,
    bool? hasCghs,
    bool? hasEchs,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search != null && search.isNotEmpty) 'search': search,
      if (gender != null && gender.isNotEmpty) 'gender': gender,
      if (hasIdProof != null) 'hasIdProof': '$hasIdProof',
      if (hasCghs != null) 'hasCghs': '$hasCghs',
      if (hasEchs != null) 'hasEchs': '$hasEchs',
    };
    final res = await _client.get(ApiEndpoints.patients, params: params);
    final data = res['data'] as List<dynamic>;
    final pagination = res['pagination'] as Map<String, dynamic>?;
    return (
      patients: data
          .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: pagination?['total'] as int? ?? data.length,
    );
  }

  Future<PatientModel> getById(String id) async {
    final res = await _client.get(ApiEndpoints.patient(id));
    final data = res['data'] as Map<String, dynamic>;
    return PatientModel.fromJson(
      data['patient'] as Map<String, dynamic>? ?? data,
    );
  }

  Future<Map<String, dynamic>> getDashboardDetail(String id) async {
    final res = await _client.get(
      ApiEndpoints.dashboardPatient,
      params: {'id': id},
    );
    return res['data'] as Map<String, dynamic>;
  }

  Future<PatientModel> create(
    Map<String, dynamic> body, {
    String? idProofFilePath,
    String? cghsFilePath,
    String? echsFilePath,
  }) async {
    final files = _proofFiles(
      idProofFilePath: idProofFilePath,
      cghsFilePath: cghsFilePath,
      echsFilePath: echsFilePath,
    );
    final res = files.isEmpty
        ? await _client.post(ApiEndpoints.patients, body: body)
        : await _client.multipartPostFiles(
            ApiEndpoints.patients,
            fields: _stringFields(body),
            files: files,
          );
    return PatientModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<PatientModel> update(
    String id,
    Map<String, dynamic> body, {
    String? idProofFilePath,
    String? cghsFilePath,
    String? echsFilePath,
  }) async {
    final files = _proofFiles(
      idProofFilePath: idProofFilePath,
      cghsFilePath: cghsFilePath,
      echsFilePath: echsFilePath,
    );
    final res = files.isEmpty
        ? await _client.patch(ApiEndpoints.patient(id), body: body)
        : await _client.multipartPatchFiles(
            ApiEndpoints.patient(id),
            fields: _stringFields(body),
            files: files,
          );
    return PatientModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.delete(ApiEndpoints.patient(id));
  }
}
