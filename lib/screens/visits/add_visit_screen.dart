import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../providers/treatment_provider.dart';
import '../../providers/visit_provider.dart';
import '../../models/visit_model.dart';
import '../../models/transaction_model.dart';
import '../../widgets/app_button.dart';

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

class AddVisitScreen extends StatefulWidget {
  final String treatmentId;
  final String treatmentTitle;
  final double? remainingAmount;

  const AddVisitScreen({
    super.key,
    required this.treatmentId,
    required this.treatmentTitle,
    this.remainingAmount,
  });

  @override
  State<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _paymentNotesCtrl = TextEditingController();
  DateTime _visitDate = DateTime.now();
  bool _hasPayment = false;
  String _paymentMode = 'cash';
  final List<_NamedFile> _reportFiles = [];
  final List<_NamedFile> _prescriptionFiles = [];

  static const _modes = [
    ('cash', 'Cash', Icons.payments_outlined),
    ('upi', 'UPI', Icons.qr_code_scanner_outlined),
    ('card', 'Card', Icons.credit_card_outlined),
    ('bank', 'Bank Transfer', Icons.account_balance_outlined),
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _paymentNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (!mounted) return;
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickDocument({required bool prescription}) async {
    final document = await _showDocumentPickerSheet(
      title: prescription ? 'Upload Prescription' : 'Upload Report',
      defaultName: prescription ? 'Prescription' : 'Report',
    );
    if (!mounted || document == null) return;
    setState(() {
      if (prescription) {
        _prescriptionFiles.add(document);
      } else {
        _reportFiles.add(document);
      }
    });
  }

  Future<_NamedFile?> _showDocumentPickerSheet({
    required String title,
    required String defaultName,
  }) async {
    return showModalBottomSheet<_NamedFile>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DocumentPickerSheet(
        title: title,
        defaultName: defaultName,
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_hasPayment && _amountCtrl.text.trim().isNotEmpty) {
      final amount = _parseAmount(_amountCtrl.text);
      final remaining = await _resolveRemainingAmount();
      if (!mounted) return;
      if (amount != null && remaining != null && amount > remaining) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Amount cannot be greater than leftover amount '
              '${AppDateUtils.formatCurrency(remaining)}. Please update the '
              'total fee by going back then create a new record.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    final provider = context.read<VisitProvider>();
    final fields = {
      'treatmentId': widget.treatmentId,
      'visitDate': AppDateUtils.toApiDate(_visitDate),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
      if (_hasPayment && _amountCtrl.text.isNotEmpty)
        'paymentAmount': _parseAmount(_amountCtrl.text).toString(),
      if (_hasPayment) 'paymentMode': _paymentMode,
      if (_hasPayment && _referenceCtrl.text.isNotEmpty)
        'paymentReferenceId': _referenceCtrl.text.trim(),
      if (_hasPayment && _paymentNotesCtrl.text.isNotEmpty)
        'paymentNotes': _paymentNotesCtrl.text.trim(),
    };
    final hasDetails =
        _hasPayment || _reportFiles.isNotEmpty || _prescriptionFiles.isNotEmpty;
    final result = hasDetails
        ? await provider.createVisitWithDetails(
            fields: fields,
            reportFilePaths: _reportFiles.map((item) => item.path).toList(),
            reportNames: _reportFiles.map((item) => item.name).toList(),
            prescriptionFilePaths:
                _prescriptionFiles.map((item) => item.path).toList(),
            prescriptionNames:
                _prescriptionFiles.map((item) => item.name).toList(),
          )
        : await provider.createVisit(fields);
        
    if (result != null && mounted) {
      if (result is VisitModel) {
        context.read<TreatmentProvider>().addVisitToDetail(result);
      } else if (result is Map<String, dynamic>) {
        if (result['visit'] != null) {
          final v = VisitModel.fromJson(result['visit'] as Map<String, dynamic>);
          context.read<TreatmentProvider>().addVisitToDetail(v);
        }
        if (result['transaction'] != null) {
          final tx = TransactionModel.fromJson(result['transaction'] as Map<String, dynamic>);
          context.read<TreatmentProvider>().addTransactionToDetail(tx);
        }
      }
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to add visit'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  double? _parseAmount(String value) {
    return double.tryParse(value.trim().replaceAll(',', ''));
  }

  Future<double?> _resolveRemainingAmount() async {
    final local = _currentRemainingAmount();
    if (local != null) return local;

    final provider = context.read<TreatmentProvider>();
    await provider.loadTreatmentDetail(widget.treatmentId);
    if (!mounted) return null;
    return _currentRemainingAmount();
  }

  double? _currentRemainingAmount() {
    if (widget.remainingAmount != null) return widget.remainingAmount;

    final provider = context.read<TreatmentProvider>();
    final selected = provider.selectedTreatment;
    if (selected?.id == widget.treatmentId) {
      return provider.balance;
    }

    for (final treatment in provider.treatments) {
      if (treatment.id == widget.treatmentId) {
        return treatment.balanceDouble;
      }
    }
    return null;
  }

  String _formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<VisitProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add Visit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.treatmentTitle.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Visit Date', Icons.calendar_today_outlined),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _pickDate,
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
                            const Icon(Icons.event_outlined,
                                size: 16, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _formatDate(_visitDate),
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
                    const SizedBox(height: 14),
                    _label('Notes', Icons.notes_outlined),
                    const SizedBox(height: 10),
                    _StyledField(
                      controller: _notesCtrl,
                      label: 'Visit Notes (optional)',
                      icon: Icons.notes,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _label('Payment', Icons.payments_outlined),
                        Switch(
                          value: _hasPayment,
                          onChanged: (v) => setState(() => _hasPayment = v),
                          activeTrackColor: AppColors.primary,
                        ),
                      ],
                    ),
                    if (_hasPayment) ...[
                      const Divider(height: 24),
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
                      const SizedBox(height: 16),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
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
                      const SizedBox(height: 16),
                      _StyledField(
                        controller: _referenceCtrl,
                        label: 'Reference / Transaction ID (optional)',
                        icon: Icons.tag_outlined,
                      ),
                      const SizedBox(height: 10),
                      _StyledField(
                        controller: _paymentNotesCtrl,
                        label: 'Payment Notes (optional)',
                        icon: Icons.notes_outlined,
                        maxLines: 2,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Documents', Icons.attach_file),
                    const SizedBox(height: 14),
                    _FilePickRow(
                      title: 'Reports',
                      count: _reportFiles.length,
                      onPick: () => _pickDocument(prescription: false),
                    ),
                    const SizedBox(height: 10),
                    _FilePickRow(
                      title: 'Prescriptions',
                      count: _prescriptionFiles.length,
                      onPick: () => _pickDocument(prescription: true),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              AppButton(
                label: 'Add Visit',
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

class _FilePickRow extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onPick;

  const _FilePickRow({
    required this.title,
    required this.count,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count == 0 ? '$title (None)' : '$title: $count selected',
              style: TextStyle(
                fontWeight: count > 0 ? FontWeight.w700 : FontWeight.w500,
                color: count > 0 ? AppColors.textPrimary : AppColors.textLight,
              ),
            ),
          ),
          IconButton(
            onPressed: onPick,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primarySurface,
              foregroundColor: AppColors.primary,
            ),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}

class _DocumentPickerSheet extends StatefulWidget {
  final String title;
  final String defaultName;

  const _DocumentPickerSheet({
    required this.title,
    required this.defaultName,
  });

  @override
  State<_DocumentPickerSheet> createState() => _DocumentPickerSheetState();
}

class _DocumentPickerSheetState extends State<_DocumentPickerSheet> {
  final _picker = ImagePicker();
  late final TextEditingController _nameCtrl;
  _PickedFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.defaultName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (!mounted || file == null) return;
    _setPickedFile(_PickedFile(path: file.path, fileName: file.name));
  }

  Future<void> _pickAnyFile() async {
    final result = await FilePicker.pickFiles();
    if (!mounted) return;
    final file = result?.files.single;
    if (file?.path == null) return;
    _setPickedFile(_PickedFile(path: file!.path!, fileName: file.name));
  }

  void _setPickedFile(_PickedFile file) {
    setState(() {
      _pickedFile = file;
      if (_nameCtrl.text.trim().isEmpty ||
          _nameCtrl.text == widget.defaultName) {
        _nameCtrl.text = file.fileName;
      }
    });
  }

  void _addFile() {
    final pickedFile = _pickedFile;
    if (pickedFile == null) return;
    final name = _nameCtrl.text.trim().isEmpty
        ? pickedFile.fileName
        : _nameCtrl.text.trim();
    Navigator.pop(
      context,
      _NamedFile(
        path: pickedFile.path,
        fileName: pickedFile.fileName,
        name: name,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Icon(
                    _pickedFile == null
                        ? Icons.upload_file_outlined
                        : Icons.description_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _pickedFile?.fileName ?? 'No file selected',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _pickAnyFile,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Choose File / PDF'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Document Name',
                prefixIcon: const Icon(Icons.edit_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _pickedFile == null ? null : _addFile,
                icon: const Icon(Icons.check),
                label: const Text('Add File'),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _NamedFile {
  final String path;
  final String fileName;
  final String name;
  const _NamedFile({
    required this.path,
    required this.fileName,
    required this.name,
  });
}

class _PickedFile {
  final String path;
  final String fileName;
  const _PickedFile({required this.path, required this.fileName});
}
