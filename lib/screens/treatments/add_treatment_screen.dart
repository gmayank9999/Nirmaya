import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/validators.dart';
import '../../providers/treatment_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AddTreatmentScreen extends StatefulWidget {
  final String patientId;
  final String patientName;
  final dynamic editTreatment;

  const AddTreatmentScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.editTreatment,
  });

  @override
  State<AddTreatmentScreen> createState() => _AddTreatmentScreenState();
}

class _AddTreatmentScreenState extends State<AddTreatmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _totalFeeCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  final _discountValueCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _status = 'ongoing';
  String? _discountType;
  DateTime _startDate = DateTime.now();
  DateTime? _estimatedEndDate;
  DateTime? _actualEndDate;

  bool get _isEdit => widget.editTreatment != null;

  final _statuses = ['planned', 'ongoing', 'paused', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.editTreatment;
      _titleCtrl.text = t.title;
      _totalFeeCtrl.text = t.totalFee.toString();
      _feeCtrl.text = t.finalFee.toString();
      _discountType = t.discountType;
      _discountValueCtrl.text = t.discountValue?.toString() ?? '';
      _notesCtrl.text = t.notes ?? '';
      _status = t.status ?? 'ongoing';
      _startDate = _parseDate(t.startDate) ?? DateTime.now();
      _estimatedEndDate = _parseDate(t.estimatedEndDate);
      _actualEndDate = _parseDate(t.actualEndDate);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _totalFeeCtrl.dispose();
    _feeCtrl.dispose();
    _discountValueCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime?> onPicked,
    bool allowClear = false,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      onPicked(picked);
      setState(() {});
    } else if (allowClear) {
      onPicked(null);
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TreatmentProvider>();
    final totalFee = double.tryParse(_totalFeeCtrl.text) ?? 0;
    final fee = double.tryParse(_feeCtrl.text) ?? 0;
    final data = {
      'patientId': widget.patientId,
      'title': _titleCtrl.text.trim(),
      'status': _status,
      'startDate': AppDateUtils.toApiDate(_startDate),
      if (_estimatedEndDate != null)
        'estimatedEndDate': AppDateUtils.toApiDate(_estimatedEndDate!),
      if (_actualEndDate != null)
        'actualEndDate': AppDateUtils.toApiDate(_actualEndDate!),
      'totalFee': totalFee,
      if (_discountType != null) 'discountType': _discountType,
      if (_discountValueCtrl.text.isNotEmpty)
        'discountValue': double.tryParse(_discountValueCtrl.text),
      'finalFee': fee,
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
    };
    bool ok;
    if (_isEdit) {
      final updated =
          await provider.updateTreatment(widget.editTreatment.id, data);
      ok = updated != null;
    } else {
      final created = await provider.createTreatment(data);
      ok = created != null;
    }
    if (ok && mounted) {
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Something went wrong'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<TreatmentProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Treatment' : 'New Treatment'),
      ),
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
                label: 'Treatment Title',
                controller: _titleCtrl,
                validator: AppValidators.required,
                prefixIcon: const Icon(Icons.medical_services_outlined),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Total Fee (₹)',
                controller: _totalFeeCtrl,
                keyboardType: TextInputType.number,
                validator: AppValidators.amount,
                prefixIcon: const Icon(Icons.currency_rupee),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _discountType,
                      decoration:
                          const InputDecoration(labelText: 'Discount Type'),
                      items: const [
                        DropdownMenuItem(
                          value: 'percentage',
                          child: Text('Percentage'),
                        ),
                        DropdownMenuItem(
                          value: 'fixed_amount',
                          child: Text('Fixed Amount'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _discountType = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Discount',
                      controller: _discountValueCtrl,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.percent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Final Fee (₹)',
                controller: _feeCtrl,
                keyboardType: TextInputType.number,
                validator: AppValidators.amount,
                prefixIcon: const Icon(Icons.currency_rupee),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              _DateTile(
                label: 'Start Date',
                value: _startDate,
                onTap: () => _pickDate(
                  initialDate: _startDate,
                  onPicked: (value) => _startDate = value ?? _startDate,
                ),
              ),
              const SizedBox(height: 12),
              _DateTile(
                label: 'Estimated End',
                value: _estimatedEndDate,
                onTap: () => _pickDate(
                  initialDate: _estimatedEndDate ?? _startDate,
                  onPicked: (value) => _estimatedEndDate = value,
                  allowClear: true,
                ),
              ),
              const SizedBox(height: 12),
              _DateTile(
                label: 'Actual End',
                value: _actualEndDate,
                onTap: () => _pickDate(
                  initialDate: _actualEndDate ?? DateTime.now(),
                  onPicked: (value) => _actualEndDate = value,
                  allowClear: true,
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: _statuses
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s[0].toUpperCase() + s.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? _status),
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
                label: _isEdit ? 'Update Treatment' : 'Add Treatment',
                onPressed: _submit,
                isLoading: isLoading,
                icon: Icons.save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          value == null
              ? 'Not set'
              : AppDateUtils.formatDate(value!.toIso8601String()),
        ),
      ),
    );
  }
}
