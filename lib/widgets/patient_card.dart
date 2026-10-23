import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/patient_model.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/app_date_utils.dart';

class PatientCard extends StatelessWidget {
  final PatientModel patient;
  final String? subtitle;
  final VoidCallback? onTap;

  const PatientCard(
      {super.key, required this.patient, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => context.push('/patients/${patient.id}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _Avatar(initials: patient.initials),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle ??
                        (patient.patientNumber != null
                            ? '${patient.displayId} • ${patient.phone}'
                            : patient.phone),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (patient.pendingAmount != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      patient.pendingAmount! > 0
                          ? 'Pending: ${AppDateUtils.formatCurrency(patient.pendingAmount)}'
                          : 'No pending payment',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: patient.pendingAmount! > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                  ],
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

class _Avatar extends StatelessWidget {
  final String initials;
  const _Avatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
