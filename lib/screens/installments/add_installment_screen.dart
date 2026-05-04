import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/validators.dart';
import '../../providers/installment_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AddInstallmentScreen extends StatefulWidget {
  final String treatmentId;
  final String treatmentTitle;

  const AddInstallmentScreen({
    super.key,
    required this.treatmentId,
    required this.treatmentTitle,
  });

  @override
  State<AddInstallmentScreen> createState() => _AddInstallmentScreenState();
}

class _AddInstallmentScreenState extends State<AddInstallmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _planCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();

  @override
  void dispose() {
    _planCtrl.dispose();
    _totalCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<InstallmentProvider>();
    final data = {
      'treatmentId': widget.treatmentId,
      'planName': _planCtrl.text.trim(),
      'totalInstallments': int.parse(_totalCtrl.text),
      'installmentAmount': double.parse(_amountCtrl.text),
      'dueDate': AppDateUtils.toApiDate(_startDate),
    };
    final ok = await provider.createInstallments(data);
    if (ok && mounted) {
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to create plan'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<InstallmentProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Installment Plan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (widget.treatmentTitle.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.treatmentTitle,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              AppTextField(
                label: 'Plan Name',
                controller: _planCtrl,
                validator: AppValidators.required,
                prefixIcon: const Icon(Icons.label_outlined),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Total Installments',
                controller: _totalCtrl,
                keyboardType: TextInputType.number,
                validator: AppValidators.positiveNumber,
                prefixIcon: const Icon(Icons.format_list_numbered),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Amount per Installment (₹)',
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                validator: AppValidators.amount,
                prefixIcon: const Icon(Icons.currency_rupee),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Start Date',
                readOnly: true,
                onTap: _pickDate,
                initialValue:
                    '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Create Plan',
                onPressed: _submit,
                isLoading: isLoading,
                icon: Icons.playlist_add_check,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
