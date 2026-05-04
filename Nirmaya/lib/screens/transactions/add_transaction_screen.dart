import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AddTransactionScreen extends StatefulWidget {
  final String treatmentId;
  final String patientId;
  final String treatmentTitle;

  const AddTransactionScreen({
    super.key,
    required this.treatmentId,
    required this.patientId,
    required this.treatmentTitle,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _paymentMode = 'cash';

  final _modes = ['cash', 'upi', 'card', 'bank'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    final provider = context.read<TransactionProvider>();
    final data = {
      'treatmentId': widget.treatmentId,
      'patientId': widget.patientId,
      'amount': double.parse(_amountCtrl.text),
      'paymentMode': _paymentMode,
      'type': 'payment',
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };
    final result = await provider.createTransaction(data);
    if (result != null && mounted) {
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to record payment'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<TransactionProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Record Payment')),
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
                label: 'Amount (₹)',
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                validator: AppValidators.amount,
                prefixIcon: const Icon(Icons.currency_rupee),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _paymentMode,
                decoration: const InputDecoration(labelText: 'Payment Mode'),
                items: _modes
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m[0].toUpperCase() + m.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _paymentMode = v ?? _paymentMode),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Notes (optional)',
                controller: _notesCtrl,
                maxLines: 3,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Record Payment',
                onPressed: _submit,
                isLoading: isLoading,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
