import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/patient_model.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/main/main_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/patients/patients_list_screen.dart';
import '../screens/patients/patient_detail_screen.dart';
import '../screens/patients/add_patient_screen.dart';
import '../screens/treatments/treatment_detail_screen.dart';
import '../screens/treatments/add_treatment_screen.dart';
import '../screens/visits/add_visit_screen.dart';
import '../screens/visits/visit_detail_screen.dart';
import '../screens/transactions/payments_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/followups/add_followup_screen.dart';
import '../screens/installments/add_installment_screen.dart';
import 'route_observer.dart';

final _rootNavKey = GlobalKey<NavigatorState>();
final _shellNavKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavKey,
    observers: [routeObserver],
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: (context, state) {
      final status = authProvider.status;
      final location = state.uri.toString();

      if (status == AuthStatus.unknown) {
        return location == '/splash' ? null : '/splash';
      }
      if (status == AuthStatus.unauthenticated) {
        return location == '/login' ? null : '/login';
      }
      if (status == AuthStatus.authenticated) {
        if (location == '/splash' || location == '/login') {
          return '/dashboard';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/patients',
            builder: (_, __) => const PatientsListScreen(),
          ),
          GoRoute(
            path: '/payments',
            builder: (_, __) => const PaymentsScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (_, state) => const MoreScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/patients/:id',
        builder: (_, state) => PatientDetailScreen(
          patientId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/treatments/:id',
        builder: (_, state) => TreatmentDetailScreen(
          treatmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/visits/:id',
        builder: (_, state) => VisitDetailScreen(
          visitId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/add-patient',
        builder: (_, state) => AddPatientScreen(
          editPatient:
              state.extra is PatientModel ? state.extra as PatientModel : null,
        ),
      ),
      GoRoute(
        path: '/add-treatment',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddTreatmentScreen(
            patientId: extra?['patientId'] as String? ?? '',
            patientName: extra?['patientName'] as String? ?? '',
            editTreatment: extra?['editTreatment'],
          );
        },
      ),
      GoRoute(
        path: '/add-visit',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AddVisitScreen(
            treatmentId: extra['treatmentId'] as String,
            treatmentTitle: extra['treatmentTitle'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/add-transaction',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AddTransactionScreen(
            treatmentId: extra['treatmentId'] as String,
            patientId: extra['patientId'] as String,
            treatmentTitle: extra['treatmentTitle'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/add-followup',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AddFollowupScreen(
            patientId: extra['patientId'] as String,
            treatmentId: extra['treatmentId'] as String,
            patientName: extra['patientName'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/add-installment',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return AddInstallmentScreen(
            treatmentId: extra['treatmentId'] as String,
            treatmentTitle: extra['treatmentTitle'] as String? ?? '',
          );
        },
      ),
    ],
  );
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A2C5B), Color(0xFF4A1F40)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user?.role == 'admin' ? 'Admin' : 'Receptionist',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.logout, color: Color(0xFFEF5350)),
            title: const Text(
              'Logout',
              style: TextStyle(
                  color: Color(0xFFEF5350), fontWeight: FontWeight.w600),
            ),
            tileColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout',
                          style: TextStyle(color: Color(0xFFEF5350))),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                if (!context.mounted) return;
                await context.read<AuthProvider>().logout();
              }
            },
          ),
        ],
      ),
    );
  }
}
