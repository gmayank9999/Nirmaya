import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/app_date_utils.dart';
import '../../providers/treatment_provider.dart';
import '../../providers/visit_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

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
            reportFilePaths: _reportFiles.map((item) => item.path).toList(),
            reportNames: _reportFiles.map((item) => item.name).toList(),
            prescriptionFilePaths:
                _prescriptionFiles.map((item) => item.path).toList(),
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
    final file = await _picker.pickImage(source: source);
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
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 20),
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
              decoration: const InputDecoration(labelText: 'Name'),
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
