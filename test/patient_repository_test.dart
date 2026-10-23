import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaya_cms/core/api/api_client.dart';
import 'package:nirmaya_cms/repositories/patient_repository.dart';

class _Client implements ApiClient {
  final List<Map<String, dynamic>> rows;
  Map<String, dynamic>? params;
  _Client(this.rows);

  @override
  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? params}) async {
    expect(path, '/patients');
    this.params = params;
    return {
      'data': rows,
      'pagination': {'total': rows.length}
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> _patient([dynamic pending]) => {
      'id': 'p',
      'clinicId': 'c',
      'name': 'Patient',
      'phone': '9876543210',
      if (pending != null) 'pendingAmount': pending,
    };

void main() {
  test(
      'repository sends payment filters with search and parses numeric amounts',
      () async {
    final client = _Client([_patient('12000.25'), _patient(6000)]);
    final result = await PatientRepository(client: client).list(
      search: 'Patient',
      hasCghs: true,
      minPending: 5000.25,
      highestPendingFirst: true,
      page: 2,
    );
    expect(client.params, {
      'page': '2',
      'limit': '20',
      'search': 'Patient',
      'hasCghs': 'true',
      'minPending': '5000.25',
      'sortBy': 'pending_desc',
    });
    expect(result.patients.map((p) => p.pendingAmount), [12000.25, 6000]);
  });

  test('an old backend cannot silently ignore payment filters', () async {
    final repository = PatientRepository(client: _Client([_patient()]));
    await expectLater(
        repository.list(minPending: 0), throwsA(isA<ApiException>()));
    await expectLater(repository.list(highestPendingFirst: true),
        throwsA(isA<ApiException>()));
    expect((await repository.list()).patients, hasLength(1));
  });

  test('rejects unfiltered and incorrectly sorted results', () async {
    await expectLater(
      PatientRepository(client: _Client([_patient(5000)]))
          .list(minPending: 5000),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      PatientRepository(client: _Client([_patient(5000), _patient(10000)]))
          .list(highestPendingFirst: true),
      throwsA(isA<ApiException>()),
    );
  });

  test('valid empty results and zero balances with sorting alone are accepted',
      () async {
    expect(
        (await PatientRepository(client: _Client([])).list(minPending: 10000))
            .total,
        0);
    expect(
        (await PatientRepository(client: _Client([_patient(0)]))
                .list(highestPendingFirst: true))
            .patients
            .single
            .pendingAmount,
        0);
  });
}
