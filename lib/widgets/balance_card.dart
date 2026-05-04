import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/app_date_utils.dart';

class BalanceCard extends StatelessWidget {
  final double finalFee;
  final double paidAmount;
  final double balance;

  const BalanceCard({
    super.key,
    required this.finalFee,
    required this.paidAmount,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    final paidPercent =
        finalFee > 0 ? (paidAmount / finalFee).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatColumn(
                label: 'Total Fee',
                value: AppDateUtils.formatCurrency(finalFee),
              ),
              _StatColumn(
                label: 'Paid',
                value: AppDateUtils.formatCurrency(paidAmount),
                valueColor: Colors.greenAccent,
              ),
              _StatColumn(
                label: 'Balance',
                value: AppDateUtils.formatCurrency(balance),
                valueColor:
                    balance > 0 ? Colors.orangeAccent : Colors.greenAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: paidPercent.toDouble(),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.greenAccent),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(paidPercent * 100).toStringAsFixed(0)}% paid',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatColumn(
      {required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
