import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../providers/visit_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AddVisitScreen extends StatefulWidget {
  final String treatmentId;
  final String treatmentTitle;

  const AddVisitScreen(
      {super.key, required this.treatmentId, required this.treatmentTitle});

  @override
  State<AddVisitScreen> createState() => _AddVisitScreenState();
}

class _AddVisitScreenState extends State<AddVisitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _paymentNotesCtrl = TextEditingController();
  final _picker = ImagePicker();
  DateTime _visitDate = DateTime.now();
  bool _hasPayment = false;
  String? _paymentMode = 'cash';
  final List<_NamedFile> _reportFiles = [];
  final List<_NamedFile> _prescriptionFiles = [];

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
    if (picked != null) setState(() => _visitDate = picked);
  }

  Future<void> _pickDocument({required bool prescription}) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final name = await _promptDocumentName(
      label: prescription ? 'Prescription name' : 'Report name',
      defaultName: file.name,
    );
    if (name == null) return;
    final trimmedName = name.trim().isEmpty ? file.name : name.trim();
    setState(() {
      if (prescription) {
        _prescriptionFiles
            .add(_NamedFile(file: file, name: trimmedName));
      } else {
        _reportFiles.add(_NamedFile(file: file, name: trimmedName));
      }
    });
  }

  Future<String?> _promptDocumentName({
    required String label,
    required String defaultName,
  }) async {
    final controller = TextEditingController(text: defaultName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(label),
          content: TextField(
            controller: controller,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(hintText: 'Enter name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    final provider = context.read<VisitProvider>();
    final fields = {
      'treatmentId': widget.treatmentId,
      'visitDate': AppDateUtils.toApiDate(_visitDate),
      if (_notesCtrl.text.isNotEmpty) 'notes': _notesCtrl.text.trim(),
      if (_hasPayment && _amountCtrl.text.isNotEmpty)
        'paymentAmount': _amountCtrl.text.trim(),
      if (_hasPayment && _paymentMode != null) 'paymentMode': _paymentMode!,
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
        reportFilePaths:
          _reportFiles.map((item) => item.file.path).toList(),
        reportNames: _reportFiles.map((item) => item.name).toList(),
            prescriptionFilePaths:
          _prescriptionFiles.map((item) => item.file.path).toList(),
        prescriptionNames:
          _prescriptionFiles.map((item) => item.name).toList(),
          )
        : await provider.createVisit(fields);
    if (result != null && mounted) {
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

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<VisitProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Add Visit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                label: 'Visit Date',
                readOnly: true,
                onTap: _pickDate,
                initialValue:
                    '${_visitDate.day}/${_visitDate.month}/${_visitDate.year}',
                prefixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Notes (optional)',
                controller: _notesCtrl,
                maxLines: 4,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              const SizedBox(height: 18),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _hasPayment,
                onChanged: (value) => setState(() => _hasPayment = value),
                title: const Text('Add payment'),
              ),
              if (_hasPayment) ...[
                const SizedBox(height: 10),
                AppTextField(
                  label: 'Amount',
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _paymentMode,
                  decoration: const InputDecoration(labelText: 'Payment Mode'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                    DropdownMenuItem(value: 'card', child: Text('Card')),
                    DropdownMenuItem(value: 'bank', child: Text('Bank')),
                  ],
                  onChanged: (value) => setState(() => _paymentMode = value),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Reference ID (optional)',
                  controller: _referenceCtrl,
                  prefixIcon: const Icon(Icons.receipt_long_outlined),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Payment notes (optional)',
                  controller: _paymentNotesCtrl,
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
              ],
              const SizedBox(height: 18),
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
              const SizedBox(height: 28),
              AppButton(
                label: 'Add Visit',
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              count == 0
                  ? '$title: no files selected'
                  : '$title: $count file(s)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: onPick,
            icon: const Icon(Icons.upload_file),
          ),
        ],
      ),
    );
  }
}

class _NamedFile {
  final XFile file;
  final String name;
  const _NamedFile({required this.file, required this.name});
}
