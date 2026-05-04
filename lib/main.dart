import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/treatment_provider.dart';
import 'providers/visit_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/followup_provider.dart';
import 'providers/installment_provider.dart';
import 'providers/document_provider.dart';
import 'providers/dashboard_provider.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NirmayaApp());
}

class NirmayaApp extends StatefulWidget {
  const NirmayaApp({super.key});

  @override
  State<NirmayaApp> createState() => _NirmayaAppState();
}

class _NirmayaAppState extends State<NirmayaApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider()..checkAuth();
    _router = createRouter(_authProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => TreatmentProvider()),
        ChangeNotifierProvider(create: (_) => VisitProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => FollowupProvider()),
        ChangeNotifierProvider(create: (_) => InstallmentProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            title: 'Nirmaya',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
