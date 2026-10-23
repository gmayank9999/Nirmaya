import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:nirmaya_cms/models/patient_model.dart';
import 'package:nirmaya_cms/providers/patient_provider.dart';
import 'package:nirmaya_cms/repositories/patient_repository.dart';
import 'package:nirmaya_cms/screens/patients/patients_list_screen.dart';
import 'package:nirmaya_cms/widgets/patient_card.dart';

typedef _Result = ({List<PatientModel> patients, int total});

PatientModel _patient(String name) => PatientModel.fromJson({
      'id': name,
      'clinicId': 'clinic',
      'name': name,
      'phone': '9876543210',
    });

class _Request {
  final String? search;
  final String? gender;
  final bool? hasIdProof;
  final bool? hasCghs;
  final bool? hasEchs;
  final double? minPending;
  final bool highestPendingFirst;
  final int page;
  final result = Completer<_Result>();
  _Request(this.search, this.gender, this.hasIdProof, this.hasCghs,
      this.hasEchs, this.page, this.minPending, this.highestPendingFirst);

  void complete(String name, {int total = 1}) =>
      result.complete((patients: [_patient(name)], total: total));
}

class _Repository extends PatientRepository {
  final requests = <_Request>[];
  bool immediate = false;

  @override
  Future<_Result> list(
      {String? search,
      String? gender,
      bool? hasIdProof,
      bool? hasCghs,
      bool? hasEchs,
      double? minPending,
      bool highestPendingFirst = false,
      int page = 1,
      int limit = 20}) {
    final request = _Request(search, gender, hasIdProof, hasCghs, hasEchs, page,
        minPending, highestPendingFirst);
    requests.add(request);
    if (immediate) request.complete('Test Patient');
    return request.result.future;
  }
}

void main() {
  test('pending threshold and sorting persist across refresh and pagination',
      () async {
    final repo = _Repository();
    final provider = PatientProvider(repository: repo);
    final first = provider.loadPatients(
        search: 'Asha',
        gender: 'female',
        minPending: 5000.25,
        highestPendingFirst: true,
        filtersChanged: true);
    repo.requests.last.complete('Asha', total: 40);
    await first;
    final more = provider.loadMore();
    expect(repo.requests.last.minPending, 5000.25);
    expect(repo.requests.last.highestPendingFirst, isTrue);
    expect(repo.requests.last.page, 2);
    repo.requests.last.complete('Another Asha', total: 40);
    await more;
    final refresh = provider.loadPatients(refresh: true);
    expect(repo.requests.last.minPending, 5000.25);
    expect(repo.requests.last.highestPendingFirst, isTrue);
    expect(repo.requests.last.search, 'Asha');
    repo.requests.last.complete('Asha');
    await refresh;
    final clear = provider.loadPatients(filtersChanged: true);
    expect(repo.requests.last.minPending, isNull);
    expect(repo.requests.last.highestPendingFirst, isFalse);
    repo.requests.last.complete('Asha');
    await clear;
  });

  testWidgets('patient cards show pending amounts and settled status',
      (tester) async {
    PatientModel patient(dynamic amount) => PatientModel.fromJson({
          'id': 'p',
          'clinicId': 'c',
          'name': 'Asha',
          'phone': '9876543210',
          'pendingAmount': amount,
        });
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      PatientCard(patient: patient('12500.25')),
      PatientCard(patient: patient(0)),
      PatientCard(patient: patient(null)),
    ]))));
    expect(find.text('Pending: ₹12,500.25'), findsOneWidget);
    expect(find.text('No pending payment'), findsOneWidget);
  });
  test('new search wins when responses arrive out of order', () async {
    final repo = _Repository();
    final provider = PatientProvider(repository: repo);
    final first = provider.loadPatients(search: 'old');
    final second = provider.loadPatients(search: '  new  ');
    expect(repo.requests, hasLength(2));
    expect(repo.requests.last.search, 'new');
    repo.requests.last.complete('New');
    await second;
    repo.requests.first.complete('Old');
    await first;
    expect(provider.patients.single.name, 'New');
    expect(provider.isLoading, isFalse);
  });

  test('stale failures do not clear loading or overwrite current errors',
      () async {
    final repo = _Repository();
    final provider = PatientProvider(repository: repo);
    final first = provider.loadPatients(search: 'old');
    final second = provider.loadPatients(search: 'new');
    repo.requests.first.result.completeError(Exception('old failure'));
    await first;
    expect(provider.isLoading, isTrue);
    expect(provider.error, isNull);
    repo.requests.last.complete('New');
    await second;
    expect(provider.error, isNull);
  });

  test(
      'refresh and pagination preserve search and all filters; reset clears them',
      () async {
    final repo = _Repository()..immediate = true;
    final provider = PatientProvider(repository: repo);
    await provider.loadPatients(
        search: '9876',
        gender: 'female',
        hasIdProof: false,
        hasCghs: true,
        hasEchs: false,
        filtersChanged: true);
    await provider.loadPatients(refresh: true);
    final refresh = repo.requests.last;
    expect(refresh.search, '9876');
    expect(refresh.gender, 'female');
    expect(refresh.hasIdProof, isFalse);
    expect(refresh.hasCghs, isTrue);
    expect(refresh.hasEchs, isFalse);
    await provider.loadPatients(
        search: '', filtersChanged: true, refresh: true);
    final reset = repo.requests.last;
    expect(reset.search, '');
    expect([reset.gender, reset.hasIdProof, reset.hasCghs, reset.hasEchs],
        everyElement(isNull));
  });

  test('old pagination cannot append to new filtered results', () async {
    final repo = _Repository();
    final provider = PatientProvider(repository: repo);
    final initial = provider.loadPatients(search: 'old');
    repo.requests.last.complete('Old page 1', total: 40);
    await initial;
    final more = provider.loadMore();
    final oldPage = repo.requests.last;
    final fresh = provider.loadPatients(
        search: 'new', hasCghs: true, filtersChanged: true);
    await provider.loadMore();
    expect(repo.requests, hasLength(3));
    repo.requests.last.complete('New');
    await fresh;
    oldPage.complete('Old page 2', total: 40);
    await more;
    expect(provider.patients.map((p) => p.name), ['New']);
    expect(provider.total, 1);
    expect(provider.isLoadingMore, isFalse);
  });

  test('failed pagination retries same page with the original filters',
      () async {
    final repo = _Repository();
    final provider = PatientProvider(repository: repo);
    final initial = provider.loadPatients(
        search: '9876',
        gender: 'male',
        hasIdProof: true,
        hasCghs: false,
        hasEchs: true,
        filtersChanged: true);
    repo.requests.last.complete('First', total: 40);
    await initial;
    final more = provider.loadMore();
    repo.requests.last.result.completeError(Exception('offline'));
    await more;
    final retry = provider.loadMore();
    final request = repo.requests.last;
    expect(request.page, 2);
    expect(request.search, '9876');
    expect(request.gender, 'male');
    expect(request.hasIdProof, isTrue);
    expect(request.hasCghs, isFalse);
    expect(request.hasEchs, isTrue);
    request.complete('Second', total: 40);
    await retry;
    expect(provider.patients.map((p) => p.name), ['First', 'Second']);
    expect(provider.error, isNull);
  });

  Future<_Repository> pumpScreen(WidgetTester tester) async {
    final repo = _Repository()..immediate = true;
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => PatientProvider(repository: repo),
      child: const MaterialApp(home: PatientsListScreen()),
    ));
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('custom threshold works on a phone-sized screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = await pumpScreen(tester);
    await tester.tap(find.byTooltip('Filter Patients'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('payment-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pending above amount').last);
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const ValueKey('pending-threshold')), '-1');
    await tester.ensureVisible(find.text('Apply Filters'));
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();
    expect(repo.requests, hasLength(1));
    await tester.ensureVisible(find.byKey(const ValueKey('pending-threshold')));
    await tester.enterText(
        find.byKey(const ValueKey('pending-threshold')), '7500.25');
    await tester.ensureVisible(find.text('Apply Filters'));
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();
    expect(repo.requests.last.minPending, 7500.25);
    expect(find.text('Pending above ₹7,500.25'), findsOneWidget);
  });

  testWidgets('returning from patient details refreshes pending filter results',
      (tester) async {
    final repo = _Repository()..immediate = true;
    final router = GoRouter(initialLocation: '/patients', routes: [
      GoRoute(
          path: '/patients', builder: (_, __) => const PatientsListScreen()),
      GoRoute(
          path: '/patients/:id',
          builder: (_, __) => const Scaffold(body: Text('Patient details'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => PatientProvider(repository: repo),
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filter Patients'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('payment-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Any pending payment').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Apply Filters'));
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();
    final count = repo.requests.length;
    await tester.tap(find.text('Test Patient'));
    await tester.pumpAndSettle();
    expect(find.text('Patient details'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(repo.requests, hasLength(count + 1));
    expect(repo.requests.last.minPending, 0);
  });

  testWidgets(
      'payment filter supports presets, validation, sorting and clearing',
      (tester) async {
    final repo = await pumpScreen(tester);
    await tester.tap(find.byTooltip('Filter Patients'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('payment-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pending above amount').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Apply Filters'));
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();
    expect(
        find.text('Enter a valid amount (up to 2 decimals)'), findsOneWidget);
    expect(repo.requests, hasLength(1));
    await tester.ensureVisible(find.text('₹10,000.00'));
    await tester.tap(find.text('₹10,000.00'));
    await tester.tap(find.byType(SwitchListTile));
    await tester.ensureVisible(find.text('Apply Filters'));
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();
    expect(repo.requests.last.minPending, 10000);
    expect(repo.requests.last.highestPendingFirst, isTrue);
    expect(find.text('Pending above ₹10,000.00'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(repo.requests.last.minPending, isNull);
    expect(repo.requests.last.highestPendingFirst, isFalse);
  });

  testWidgets(
      'any pending sends zero threshold; dismissing changes does not apply them',
      (tester) async {
    final repo = await pumpScreen(tester);
    await tester.tap(find.byTooltip('Filter Patients'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('payment-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Any pending payment').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Apply Filters'));
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();
    expect(repo.requests.last.minPending, 0);
    expect(repo.requests.last.highestPendingFirst, isFalse);
    final count = repo.requests.length;
    await tester.tap(find.byTooltip('Filter Patients'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(repo.requests, hasLength(count));
    expect(find.text('Highest pending first'), findsNothing);
  });

  testWidgets('clear search cancels pending debounce and refresh keeps search',
      (tester) async {
    final repo = await pumpScreen(tester);
    await tester.enterText(find.byType(TextField), 'Old search');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    final count = repo.requests.length;
    await tester.pump(const Duration(milliseconds: 600));
    expect(repo.requests, hasLength(count));
    expect(repo.requests.last.search, '');
    await tester.enterText(find.byType(TextField), '  9876  ');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(repo.requests.last.search, '9876');
    await tester.drag(find.byType(ListView), const Offset(0, 350));
    await tester.pumpAndSettle();
    expect(repo.requests.length, greaterThan(count + 1));
    expect(repo.requests.last.search, '9876');
  });

  testWidgets('filters combine with search and Clear preserves the search',
      (tester) async {
    final repo = await pumpScreen(tester);
    await tester.enterText(find.byType(TextField), 'Patient');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filter Patients'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Female').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('No').at(0));
    await tester.tap(find.text('Yes').at(1));
    await tester.tap(find.text('No').at(2));
    await tester.ensureVisible(find.text('Apply Filters'));
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();
    final request = repo.requests.last;
    expect(request.search, 'Patient');
    expect(request.gender, 'female');
    expect(request.hasIdProof, isFalse);
    expect(request.hasCghs, isTrue);
    expect(request.hasEchs, isFalse);
    expect(find.text('4 filter(s) applied'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    final cleared = repo.requests.last;
    expect(cleared.search, 'Patient');
    expect(
        [cleared.gender, cleared.hasIdProof, cleared.hasCghs, cleared.hasEchs],
        everyElement(isNull));
  });
}
