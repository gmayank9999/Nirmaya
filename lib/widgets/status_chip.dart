import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final _ChipStyle _style;

  const StatusChip._({required this.label, required _ChipStyle style})
      : _style = style;

  factory StatusChip.treatmentStatus(String status) {
    return StatusChip._(
        label: _treatmentLabel(status), style: _treatmentStyle(status));
  }

  factory StatusChip.followupStatus(String status) {
    return StatusChip._(
        label: _followupLabel(status), style: _followupStyle(status));
  }

  factory StatusChip.installmentStatus(String status) {
    return StatusChip._(
        label: _installmentLabel(status), style: _installmentStyle(status));
  }

  factory StatusChip.custom({
    required String label,
    required Color color,
    required Color background,
  }) {
    return StatusChip._(
      label: label,
      style: _ChipStyle(color: color, background: background),
    );
  }

  static String _treatmentLabel(String s) {
    const map = {
      'planned': 'Planned',
      'ongoing': 'Ongoing',
      'paused': 'Paused',
      'completed': 'Completed',
      'cancelled': 'Cancelled',
    };
    return map[s] ?? s;
  }

  static _ChipStyle _treatmentStyle(String s) {
    switch (s) {
      case 'ongoing':
        return _ChipStyle(
            color: AppColors.info, background: const Color(0xFFE3F2FD));
      case 'completed':
        return _ChipStyle(
            color: AppColors.success, background: const Color(0xFFE8F5E9));
      case 'cancelled':
        return _ChipStyle(
            color: AppColors.error, background: const Color(0xFFFFEBEE));
      case 'paused':
        return _ChipStyle(
            color: AppColors.warning, background: const Color(0xFFFFF3E0));
      default:
        return _ChipStyle(
            color: AppColors.textSecondary,
            background: const Color(0xFFF5F5F5));
    }
  }

  static String _followupLabel(String s) {
    const map = {
      'scheduled': 'Scheduled',
      'completed': 'Completed',
      'missed': 'Missed',
      'rescheduled': 'Rescheduled',
    };
    return map[s] ?? s;
  }

  static _ChipStyle _followupStyle(String s) {
    switch (s) {
      case 'completed':
        return _ChipStyle(
            color: AppColors.success, background: const Color(0xFFE8F5E9));
      case 'missed':
        return _ChipStyle(
            color: AppColors.error, background: const Color(0xFFFFEBEE));
      case 'rescheduled':
        return _ChipStyle(
            color: AppColors.warning, background: const Color(0xFFFFF3E0));
      default:
        return _ChipStyle(
            color: AppColors.info, background: const Color(0xFFE3F2FD));
    }
  }

  static String _installmentLabel(String s) {
    const map = {'pending': 'Pending', 'paid': 'Paid', 'overdue': 'Overdue'};
    return map[s] ?? s;
  }

  static _ChipStyle _installmentStyle(String s) {
    switch (s) {
      case 'paid':
        return _ChipStyle(
            color: AppColors.success, background: const Color(0xFFE8F5E9));
      case 'overdue':
        return _ChipStyle(
            color: AppColors.error, background: const Color(0xFFFFEBEE));
      default:
        return _ChipStyle(
            color: AppColors.warning, background: const Color(0xFFFFF3E0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _style.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _style.color,
        ),
      ),
    );
  }
}

class _ChipStyle {
  final Color color;
  final Color background;
  const _ChipStyle({required this.color, required this.background});
}
