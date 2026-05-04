import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<DashboardProvider>().loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, ${user?.fullName.split(' ').first ?? 'there'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Nirmaya Clinic',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                SummaryCard(
                  title: 'Total Patients',
                  value: '${dashboard.total}',
                  icon: Icons.people,
                  color: AppColors.primary,
                  background: AppColors.primarySurface,
                ),
                SummaryCard(
                  title: 'Active Treatments',
                  value: '${dashboard.activeTreatments}',
                  icon: Icons.medical_services,
                  color: AppColors.info,
                  background: const Color(0xFFE3F2FD),
                ),
                SummaryCard(
                  title: "Today's Follow-Ups",
                  value: '${dashboard.todaysFollowups}',
                  icon: Icons.event,
                  color: AppColors.warning,
                  background: const Color(0xFFFFF3E0),
                ),
                SummaryCard(
                  title: "Today's Collection",
                  value:
                      AppDateUtils.formatCurrency(dashboard.todaysCollection),
                  icon: Icons.currency_rupee,
                  color: AppColors.success,
                  background: const Color(0xFFE8F5E9),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SectionHeader(
                title: 'Recent Patients', onTap: () => context.go('/patients')),
            const SizedBox(height: 10),
            if (dashboard.recentPatients.isEmpty && !dashboard.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                    child: Text('No patients yet',
                        style: TextStyle(color: AppColors.textSecondary))),
              )
            else
              ...dashboard.recentPatients.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RecentPatientTile(
                    name: p.name,
                    phone: p.phone,
                    initials: p.initials,
                    onTap: () => context.push('/patients/${p.id}'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _SectionHeader({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        if (onTap != null)
          TextButton(
            onPressed: onTap,
            child: const Text('See all'),
          ),
      ],
    );
  }
}

class _RecentPatientTile extends StatelessWidget {
  final String name;
  final String phone;
  final String initials;
  final VoidCallback onTap;

  const _RecentPatientTile({
    required this.name,
    required this.phone,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(phone,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
