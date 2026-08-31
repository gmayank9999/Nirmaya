import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/treatment_provider.dart';
import '../../widgets/app_button.dart';

// ── Indian number formatter (integers only for payments) ─────────────────────
final _inFmt = NumberFormat('#,##,##0', 'en_IN');
String _strip(String v) => v.replaceAll(',', '');

class _IndianFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final raw = _strip(next.text);
    if (raw.isEmpty) return next.copyWith(text: '');
    final n = int.tryParse(raw);
    if (n == null) return old;
    final formatted = _inFmt.format(n);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class AddTransactionScreen extends StatefulWidget {
  final String treatmentId;
  final String patientId;
  final String treatmentTitle;
  /// Pass an existing transaction to enter edit mode
  final TransactionModel? editTransaction;

  const AddTransactionScreen({
    super.key,
    required this.treatmentId,
    required this.patientId,
    required this.treatmentTitle,
    this.editTransaction,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  String _paymentMode = 'cash';
  late DateTime _transactionDate;

  bool get _isEdit => widget.editTransaction != null;

  static const _modes = [
    ('cash', 'Cash', Icons.payments_outlined),
    ('upi', 'UPI', Icons.qr_code_scanner_outlined),
    ('card', 'Card', Icons.credit_card_outlined),
    ('bank', 'Bank Transfer', Icons.account_balance_outlined),
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final tx = widget.editTransaction!;
      final rawAmt = tx.amountDouble.toInt();
      _amountCtrl.text = rawAmt > 0 ? _inFmt.format(rawAmt) : '';
      _notesCtrl.text = tx.notes ?? '';
      _refCtrl.text = tx.referenceId ?? '';
      _paymentMode = tx.paymentMode ?? 'cash';
      _transactionDate = DateTime.tryParse(tx.transactionDate) ?? DateTime.now();
    } else {
      _transactionDate = DateTime.now(); // default: right now
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  // ── Date + Time picker ────────────────────────────────────────────────────
  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_transactionDate),
    );
    if (!mounted) return;

    setState(() {
      _transactionDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _transactionDate.hour,
        pickedTime?.minute ?? _transactionDate.minute,
      );
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;

    final txProvider = context.read<TransactionProvider>();
    final treatProvider = context.read<TreatmentProvider>();

    final amount = double.parse(_strip(_amountCtrl.text));
    final body = {
      'treatmentId': widget.treatmentId,
      'patientId': widget.patientId,
      'amount': amount,
      'paymentMode': _paymentMode,
      'type': 'payment',
      'transactionDate': _transactionDate.toUtc().toIso8601String(),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
      if (_refCtrl.text.isNotEmpty) 'referenceId': _refCtrl.text.trim(),
    };

    if (_isEdit) {
      final updated = await txProvider.updateTransaction(
          widget.editTransaction!.id, body);
      if (updated != null && mounted) {
        // Instantly update the detail screen's list
        treatProvider.updateTransactionInDetail(updated);
        context.pop();
      } else if (mounted) {
        _showError(txProvider.error ?? 'Failed to update payment');
      }
    } else {
      final result = await txProvider.createTransaction(body);
      if (result != null && mounted) {
        // ── THE FIX: push new transaction into TreatmentProvider's list ──
        treatProvider.addTransactionToDetail(result);
        context.pop();
      } else if (mounted) {
        _showError(txProvider.error ?? 'Failed to record payment');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  String _formatDateTime(DateTime dt) {
    final date = DateFormat('dd MMM yyyy').format(dt);
    final time = DateFormat('hh:mm a').format(dt);
    return '$date, $time';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<TransactionProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Payment' : 'Record Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Treatment banner
              if (widget.treatmentTitle.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medical_services_outlined,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.treatmentTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Amount card ──────────────────────────────────────────────
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Amount', Icons.currency_rupee),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [_IndianFormatter()],
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                      validator: (v) {
                        if (v == null || _strip(v).isEmpty) {
                          return 'Amount is required';
                        }
                        final d = double.tryParse(_strip(v));
                        if (d == null || d <= 0) return 'Enter a valid amount';
                        return null;
                      },
                      decoration: InputDecoration(
                        prefixText: '₹  ',
                        prefixStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                        hintText: '0',
                        hintStyle: const TextStyle(
                            color: AppColors.textLight, fontSize: 22),
                        filled: true,
                        fillColor: AppColors.primarySurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.error, width: 1.5),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.error, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Payment Mode ─────────────────────────────────────────────
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Payment Mode', Icons.payment_outlined),
                    const SizedBox(height: 10),
                    Row(
                      children: _modes.map((m) {
                        final selected = _paymentMode == m.$1;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _paymentMode = m.$1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.primary
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(m.$3,
                                        size: 18,
                                        color: selected
                                            ? Colors.white
                                            : AppColors.textSecondary),
                                    const SizedBox(height: 4),
                                    Text(
                                      m.$2,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Date & Time ──────────────────────────────────────────────
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Date & Time', Icons.access_time_outlined),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _pickDateTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _formatDateTime(_transactionDate),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(Icons.edit_calendar_outlined,
                                size: 16, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Reference ID + Notes ────────────────────────────────────
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Additional Info', Icons.info_outline),
                    const SizedBox(height: 10),
                    _StyledField(
                      controller: _refCtrl,
                      label: 'Reference / Transaction ID (optional)',
                      icon: Icons.tag_outlined,
                    ),
                    const SizedBox(height: 10),
                    _StyledField(
                      controller: _notesCtrl,
                      label: 'Notes (optional)',
                      icon: Icons.notes_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                label: _isEdit ? 'Update Payment' : 'Record Payment',
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

// ── Helpers ───────────────────────────────────────────────────────────────────
Widget _label(String text, IconData icon) => Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
        child: child,
      );
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        maxLines: maxLines,
        textInputAction:
            maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      );
}
