import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:nirmaya_cms/models/treatment_model.dart';
import 'package:nirmaya_cms/providers/installment_provider.dart';
import 'package:nirmaya_cms/providers/treatment_provider.dart';
import 'package:nirmaya_cms/screens/treatments/treatment_detail_screen.dart';

class _TreatmentProvider extends TreatmentProvider {
  @override
  TreatmentModel get selectedTreatment => TreatmentModel.fromJson({
        'id': 'treatment-1',
        'patientId': 'patient-1',
        'title': 'Test treatment',
        'startDate': '2026-09-01',
        'finalFee': 1000,
        'balance': 500,
      });

  @override
  Future<void> loadTreatmentDetail(String id) async {}
}

class _InstallmentProvider extends InstallmentProvider {
  @override
  Future<void> loadInstallments(
      {required String treatmentId, String? status}) async {}
}

Future<GoRouter> _pumpTreatment(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/treatment',
    routes: [
      GoRoute(
        path: '/treatment',
        builder: (_, __) =>
            const TreatmentDetailScreen(treatmentId: 'treatment-1'),
      ),
      for (final path in ['/add-visit', '/add-transaction'])
        GoRoute(
          path: path,
          builder: (_, state) {
            final extra = state.extra! as Map<String, dynamic>;
            expect(extra['treatmentId'], 'treatment-1');
            expect(extra['treatmentTitle'], 'Test treatment');
            if (path == '/add-transaction') {
              expect(extra['patientId'], 'patient-1');
            } else {
              expect(extra['remainingAmount'], 500);
            }
            return Scaffold(body: Text(path));
          },
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<TreatmentProvider>(
          create: (_) => _TreatmentProvider()),
      ChangeNotifierProvider<InstallmentProvider>(
          create: (_) => _InstallmentProvider()),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets(
      'FAB follows tab taps before animation finishes in both directions',
      (tester) async {
    final router = await _pumpTreatment(tester);
    for (final entry in [
      ('Payments', '/add-transaction'),
      ('Visits', '/add-visit')
    ]) {
      await tester.tap(find.text(entry.$1));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text(entry.$2), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('FAB follows visible swipe page before controller index settles',
      (tester) async {
    final router = await _pumpTreatment(tester);
    for (final entry in [(-1.0, '/add-transaction'), (1.0, '/add-visit')]) {
      final view = find.byType(TabBarView);
      final width = tester.getSize(view).width;
      final gesture = await tester.startGesture(tester.getCenter(view));
      await gesture.moveBy(Offset(entry.$1 * width * 0.7, 0));
      await tester.pump();
      await tester.tap(find.byType(FloatingActionButton));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text(entry.$2), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
      'Docs hides FAB immediately and returning restores correct action',
      (tester) async {
    await _pumpTreatment(tester);
    await tester.tap(find.text('Docs'));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.text('Payments'));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byTooltip('Record Payment'), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('/add-transaction'), findsOneWidget);
  });
}
