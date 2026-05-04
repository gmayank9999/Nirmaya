import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../providers/patient_provider.dart';
import '../../providers/treatment_provider.dart';
import '../../providers/followup_provider.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_chip.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<PatientProvider>().loadPatient(widget.patientId);
    context.read<TreatmentProvider>().loadTreatments(
          patientId: widget.patientId,
          refresh: true,
        );
    context.read<FollowupProvider>().loadFollowups(patientId: widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    final patientProvider = context.watch<PatientProvider>();
    final treatmentProvider = context.watch<TreatmentProvider>();
    final patient = patientProvider.selectedPatient;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(patient?.name ?? 'Patient'),
        actions: [
          if (patient != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/add-patient', extra: patient),
            ),
        ],
      ),
      body: patientProvider.isLoading && patient == null
          ? const Center(child: CircularProgressIndicator())
          : patient == null
              ? const EmptyStateWidget(
                  title: 'Patient not found', icon: Icons.person_off)
              : RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _ProfileCard(patient: patient),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: 'Treatments',
                        action: IconButton(
                          icon: const Icon(Icons.add, color: AppColors.primary),
                          onPressed: () =>
                              context.push('/add-treatment', extra: {
                            'patientId': patient.id,
                            'patientName': patient.name,
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (treatmentProvider.isLoading &&
                          treatmentProvider.treatments.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (treatmentProvider.treatments.isEmpty)
                        EmptyStateWidget(
                          title: 'No treatments yet',
                          icon: Icons.medical_services_outlined,
                          action: TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Treatment'),
                            onPressed: () =>
                                context.push('/add-treatment', extra: {
                              'patientId': patient.id,
                              'patientName': patient.name,
                            }),
                          ),
                        )
                      else
                        ...treatmentProvider.treatments.map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _TreatmentTile(
                                title: t.title,
                                status: t.status,
                                finalFee: t.finalFee,
                                balance: t.balanceDouble,
                                onTap: () =>
                                    context.push('/treatments/${t.id}'),
                              ),
                            )),
                    ],
                  ),
                ),
      floatingActionButton: patient != null
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/add-treatment', extra: {
                'patientId': patient.id,
                'patientName': patient.name,
              }),
              icon: const Icon(Icons.add),
              label: const Text('Add Treatment'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final dynamic patient;
  const _ProfileCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                patient.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(patient.phone,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
                if (patient.age != null || patient.gender != null)
                  Text(
                    [
                      if (patient.age != null) '${patient.age} yrs',
                      if (patient.gender != null) patient.genderDisplay,
                    ].join(' · '),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TreatmentTile extends StatelessWidget {
  final String title;
  final String status;
  final double finalFee;
  final double balance;
  final VoidCallback onTap;

  const _TreatmentTile({
    required this.title,
    required this.status,
    required this.finalFee,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      StatusChip.treatmentStatus(status),
                      const SizedBox(width: 8),
                      Text(
                        'Fee: ${AppDateUtils.formatCurrency(finalFee)}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Bal: ${AppDateUtils.formatCurrency(balance)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: balance > 0 ? AppColors.warning : AppColors.success,
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
