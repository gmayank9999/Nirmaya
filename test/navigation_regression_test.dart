import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nirmaya_cms/screens/main/main_shell.dart';

void main() {
  testWidgets('system Back retraces main tabs and detail routes',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        ShellRoute(
          builder: (_, __, child) => MainShell(child: child),
          routes: [
            for (final path in [
              '/dashboard',
              '/patients',
              '/payments',
              '/more'
            ])
              GoRoute(
                path: path,
                builder: (context, _) => Scaffold(
                  body: TextButton(
                    onPressed: () => context.push('/detail'),
                    child: Text('Screen $path'),
                  ),
                ),
              ),
          ],
        ),
        GoRoute(
          path: '/detail',
          builder: (_, __) => const Scaffold(body: Text('Detail')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    Future<void> select(String label, int index) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          index);
    }

    await select('Patients', 1);
    await select('Patients', 1); // Reselecting must not add another screen.
    await select('Payments', 2);
    await select('Profile', 3);
    await tester.tap(find.text('Screen /more'));
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);

    for (final entry in [
      ('/more', 3),
      ('/payments', 2),
      ('/patients', 1),
      ('/dashboard', 0)
    ]) {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Screen ${entry.$1}'), findsOneWidget);
      expect(
          tester
              .widget<NavigationBar>(find.byType(NavigationBar))
              .selectedIndex,
          entry.$2);
    }
    expect(router.canPop(), isFalse);
  });
}
