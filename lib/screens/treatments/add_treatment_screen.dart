import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../core/utils/validators.dart';
import '../../providers/treatment_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

// ── Indian number formatter (no decimals for input display) ──────────────────
final _inFmt = NumberFormat('#,##,##0', 'en_IN');

/// Strips commas and returns the raw numeric string
String _stripCommas(String v) => v.replaceAll(',', '');

// ── Input formatter: formats digits with Indian commas as user types ──────────
class _IndianNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = _stripCommas(newValue.text);
    if (raw.isEmpty) return newValue.copyWith(text: '');
    final num = int.tryParse(raw);
    if (num == null) return oldValue; // reject non-numeric
    final formatted = _inFmt.format(num);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

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
  final _discountValueCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _status = 'ongoing';
  String? _discountType;
  DateTime _startDate = DateTime.now();
  DateTime? _estimatedEndDate;
  DateTime? _actualEndDate;

  // Computed final fee (auto-calculated)
  double _computedFinalFee = 0;

  bool get _isEdit => widget.editTreatment != null;

  final _statuses = ['planned', 'ongoing', 'paused', 'completed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.editTreatment;
      _titleCtrl.text = t.title;
      // Format existing total fee in Indian format
      final totalRaw = (t.totalFee as num?)?.toInt() ?? 0;
      _totalFeeCtrl.text = totalRaw > 0 ? _inFmt.format(totalRaw) : '';
      _discountType = t.discountType;
      // Format existing discount value in Indian format when fixed_amount
      final discRaw = (t.discountValue as num?)?.toDouble();
      if (discRaw != null && discRaw > 0) {
        if (t.discountType == 'fixed_amount') {
          _discountValueCtrl.text = _inFmt.format(discRaw.toInt());
        } else {
          _discountValueCtrl.text = discRaw.toString();
        }
      }
      _notesCtrl.text = t.notes ?? '';
      _status = t.status ?? 'ongoing';
      _startDate = _parseDate(t.startDate) ?? DateTime.now();
      _estimatedEndDate = _parseDate(t.estimatedEndDate);
      _actualEndDate = _parseDate(t.actualEndDate);
    }

    // Listen for live fee calculation
    _totalFeeCtrl.addListener(_recalcFee);
    _discountValueCtrl.addListener(_recalcFee);
    _recalcFee();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _totalFeeCtrl.dispose();
    _discountValueCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Auto-calculate final fee ───────────────────────────────────────────────
  void _recalcFee() {
    final total =
        double.tryParse(_stripCommas(_totalFeeCtrl.text)) ?? 0;
    final discVal =
        double.tryParse(_stripCommas(_discountValueCtrl.text)) ?? 0;

    double finalFee = total;
    if (_discountType == 'percentage') {
      final pct = discVal.clamp(0, 100);
      finalFee = total - (total * pct / 100);
    } else if (_discountType == 'fixed_amount') {
      finalFee = (total - discVal).clamp(0, double.infinity);
    }

    if (finalFee != _computedFinalFee) {
      setState(() => _computedFinalFee = finalFee);
    }
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
    DateTime? firstDate, // minimum selectable date
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate ?? DateTime(2020))
          ? (firstDate ?? DateTime.now())
          : initialDate,
      firstDate: firstDate ?? DateTime(2020),
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
    final totalFee =
        double.tryParse(_stripCommas(_totalFeeCtrl.text)) ?? 0;

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
        'discountValue':
            double.tryParse(_stripCommas(_discountValueCtrl.text)),
      'finalFee': _computedFinalFee,
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

  // ── Helpers ────────────────────────────────────────────────────────────────
  double get _totalFeeRaw =>
      double.tryParse(_stripCommas(_totalFeeCtrl.text)) ?? 0;

  double get _discountAmountRaw {
    final discVal =
        double.tryParse(_stripCommas(_discountValueCtrl.text)) ?? 0;
    if (_discountType == 'percentage') {
      return _totalFeeRaw * discVal / 100;
    } else if (_discountType == 'fixed_amount') {
      return discVal;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<TreatmentProvider>().isLoading;
    final hasDiscount = _discountType != null &&
        _discountValueCtrl.text.isNotEmpty &&
        _discountAmountRaw > 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Treatment' : 'New Treatment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Patient banner ─────────────────────────────────────────────
              if (widget.patientName.isNotEmpty)
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
                      const Icon(Icons.person_outline,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        widget.patientName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Section: Basic Info ────────────────────────────────────────
              _SectionCard(
                title: 'Treatment Info',
                icon: Icons.medical_services_outlined,
                children: [
                  AppTextField(
                    label: 'Treatment Title',
                    controller: _titleCtrl,
                    validator: AppValidators.required,
                    prefixIcon: const Icon(Icons.label_outline),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  const SizedBox(height: 4),
                  // Status — dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      prefixIcon: const Icon(Icons.info_outline,
                          color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    items: _statuses
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s[0].toUpperCase() + s.substring(1),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _status = v ?? _status),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Section: Fees ──────────────────────────────────────────────
              _SectionCard(
                title: 'Fees & Discount',
                icon: Icons.currency_rupee,
                children: [
                  // Total Fee with Indian comma formatting
                  TextFormField(
                    controller: _totalFeeCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [_IndianNumberFormatter()],
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || _stripCommas(v).isEmpty) {
                        return 'Total fee is required';
                      }
                      if ((double.tryParse(_stripCommas(v)) ?? -1) < 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Total Fee',
                      prefixIcon: const Icon(Icons.currency_rupee,
                          color: AppColors.primary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Discount Type — full width dropdown (avoids overflow)
                  DropdownButtonFormField<String>(
                    initialValue: _discountType,
                    decoration: InputDecoration(
                      labelText: 'Discount Type',
                      prefixIcon: const Icon(
                          Icons.discount_outlined,
                          color: AppColors.primary),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'percentage',
                        child: Text('Percentage (%)'),
                      ),
                      DropdownMenuItem(
                        value: 'fixed_amount',
                        child: Text('Fixed Amount (₹)'),
                      ),
                    ],
                    // Also clear discount value when type changes to avoid stale data
                    onChanged: (v) {
                      setState(() {
                        _discountType = v;
                        _discountValueCtrl.clear(); // reset so formatter applies fresh
                      });
                      _recalcFee();
                    },
                  ),
                  const SizedBox(height: 12),
                  // Discount Value — dynamic formatter based on type
                  TextFormField(
                    controller: _discountValueCtrl,
                    // For fixed_amount: integer commas; for percentage: decimal
                    keyboardType: _discountType == 'fixed_amount'
                        ? TextInputType.number
                        : const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: _discountType == 'fixed_amount'
                        ? [_IndianNumberFormatter()]
                        : [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d{0,3}(\.\d{0,2})?')),
                          ],
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (_discountType == null) return null; // discount is optional
                      if (v == null || _stripCommas(v).isEmpty) return null;
                      final val = double.tryParse(_stripCommas(v));
                      if (val == null || val < 0) return 'Enter a valid value';
                      if (_discountType == 'percentage' && val > 100) {
                        return 'Cannot exceed 100%';
                      }
                      final total = double.tryParse(_stripCommas(_totalFeeCtrl.text)) ?? 0;
                      if (_discountType == 'fixed_amount' && val > total) {
                        return 'Discount cannot exceed total fee';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: _discountType == 'fixed_amount'
                          ? 'Discount Amount (₹)'
                          : 'Discount (%)',
                      // Dynamic icon: ₹ for fixed_amount, % otherwise
                      prefixIcon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          _discountType == 'fixed_amount'
                              ? Icons.currency_rupee
                              : Icons.percent,
                          key: ValueKey(_discountType),
                          color: _discountType != null
                              ? AppColors.primary
                              : AppColors.textLight,
                          size: 18,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFE5E7EB), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Auto-calculated Final Fee banner ──────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: hasDiscount
                          ? AppColors.success.withValues(alpha: 0.08)
                          : AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: hasDiscount
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Final Fee',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Text(
                                AppDateUtils.formatCurrency(
                                    _computedFinalFee),
                                key: ValueKey(_computedFinalFee),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: hasDiscount
                                      ? AppColors.success
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.arrow_downward_rounded,
                                  size: 12, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                'Discount of ${AppDateUtils.formatCurrency(_discountAmountRaw)} applied',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_totalFeeRaw > 0 && !hasDiscount) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'No discount applied',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Section: Dates ─────────────────────────────────────────────
              _SectionCard(
                title: 'Dates',
                icon: Icons.calendar_month_outlined,
                children: [
                  _DateTile(
                    label: 'Start Date',
                    value: _startDate,
                    required: true,
                    onTap: () => _pickDate(
                      initialDate: _startDate,
                      onPicked: (v) {
                        final newStart = v ?? _startDate;
                        // If end dates become invalid, clear them
                        if (_estimatedEndDate != null &&
                            _estimatedEndDate!.isBefore(newStart)) {
                          _estimatedEndDate = null;
                        }
                        if (_actualEndDate != null &&
                            _actualEndDate!.isBefore(newStart)) {
                          _actualEndDate = null;
                        }
                        _startDate = newStart;
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DateTile(
                    label: 'Estimated End (optional)',
                    value: _estimatedEndDate,
                    onTap: () => _pickDate(
                      initialDate: _estimatedEndDate ?? _startDate,
                      firstDate: _startDate, // cannot be before start date
                      onPicked: (v) => _estimatedEndDate = v,
                      allowClear: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DateTile(
                    label: 'Actual End (optional)',
                    value: _actualEndDate,
                    onTap: () => _pickDate(
                      initialDate: _actualEndDate ?? _startDate,
                      firstDate: _startDate, // cannot be before start date
                      onPicked: (v) => _actualEndDate = v,
                      allowClear: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Section: Notes ─────────────────────────────────────────────
              _SectionCard(
                title: 'Notes',
                icon: Icons.notes_outlined,
                children: [
                  AppTextField(
                    label: 'Notes (optional)',
                    controller: _notesCtrl,
                    maxLines: 3,
                    prefixIcon: const Icon(Icons.edit_note_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              AppButton(
                label: _isEdit ? 'Update Treatment' : 'Add Treatment',
                onPressed: _submit,
                isLoading: isLoading,
                icon: Icons.save_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Card container
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// Date Tile
// ─────────────────────────────────────────────────────────────────────────────
class _DateTile extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final bool required;

  const _DateTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? AppColors.primary.withValues(alpha: 0.4)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: hasValue ? AppColors.primary : AppColors.textLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label + (required ? ' *' : ''),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasValue
                        ? AppDateUtils.formatDate(value!.toIso8601String())
                        : 'Tap to select',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          hasValue ? FontWeight.w600 : FontWeight.w400,
                      color: hasValue
                          ? AppColors.textPrimary
                          : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
