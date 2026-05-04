import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../providers/followup_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AddFollowupScreen extends StatefulWidget {
  final String patientId;
  final String treatmentId;
  final String patientName;

  const AddFollowupScreen({
    super.key,
    required this.patientId,
    required this.treatmentId,
    required this.patientName,
  });

  @override
  State<AddFollowupScreen> createState() => _AddFollowupScreenState();
}

class _AddFollowupScreenState extends State<AddFollowupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    final provider = context.read<FollowupProvider>();
    final data = {
      'patientId': widget.patientId,
      'treatmentId': widget.treatmentId,
      'scheduledDate': AppDateUtils.toApiDate(_scheduledDate),
      'status': 'scheduled',
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };
    final result = await provider.createFollowup(data);
    if (result != null && mounted) {
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to schedule follow-up'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<FollowupProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Schedule Follow-up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (widget.patientName.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Patient: ${widget.patientName}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              AppTextField(
                label: 'Scheduled Date',
                readOnly: true,
                onTap: _pickDate,
                initialValue:
                    '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                prefixIcon: const Icon(Icons.event_outlined),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Notes (optional)',
                controller: _notesCtrl,
                maxLines: 4,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: 'Schedule Follow-up',
                onPressed: _submit,
                isLoading: isLoading,
                icon: Icons.event_available,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
