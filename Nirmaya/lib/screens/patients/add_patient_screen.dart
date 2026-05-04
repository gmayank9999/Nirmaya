import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../models/patient_model.dart';
import '../../providers/patient_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class AddPatientScreen extends StatefulWidget {
  final PatientModel? editPatient;
  const AddPatientScreen({super.key, this.editPatient});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _picker = ImagePicker();
  String? _gender;
  bool _hasIdProof = false;
  bool _hasCghs = false;
  bool _hasEchs = false;
  XFile? _idProofFile;
  XFile? _cghsFile;
  XFile? _echsFile;

  bool get _isEdit => widget.editPatient != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final p = widget.editPatient!;
      _nameCtrl.text = p.name;
      _phoneCtrl.text = p.phone;
      _emailCtrl.text = p.email ?? '';
      _ageCtrl.text = p.age?.toString() ?? '';
      _gender = p.gender;
      _hasIdProof = p.hasIdProof;
      _hasCghs = p.hasCghs;
      _hasEchs = p.hasEchs;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProof(String type) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      if (type == 'id') {
        _idProofFile = file;
        _hasIdProof = true;
      } else if (type == 'cghs') {
        _cghsFile = file;
        _hasCghs = true;
      } else {
        _echsFile = file;
        _hasEchs = true;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.editPatient;
    if (_hasCghs &&
        _cghsFile == null &&
        (existing?.cghsFileUrl?.isNotEmpty != true)) {
      _showValidation('Upload the CGHS document before saving.');
      return;
    }
    if (_hasEchs &&
        _echsFile == null &&
        (existing?.echsFileUrl?.isNotEmpty != true)) {
      _showValidation('Upload the ECHS document before saving.');
      return;
    }
    final provider = context.read<PatientProvider>();
    final data = {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      if (_emailCtrl.text.isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (_ageCtrl.text.isNotEmpty) 'age': int.tryParse(_ageCtrl.text),
      if (_gender != null) 'gender': _gender,
      'hasIdProof': _hasIdProof,
      'hasCghs': _hasCghs,
      'hasEchs': _hasEchs,
    };
    bool ok;
    if (_isEdit) {
      final updated = await provider.updatePatient(
        widget.editPatient!.id,
        data,
        idProofFilePath: _idProofFile?.path,
        cghsFilePath: _cghsFile?.path,
        echsFilePath: _echsFile?.path,
      );
      ok = updated != null;
    } else {
      final created = await provider.createPatient(
        data,
        idProofFilePath: _idProofFile?.path,
        cghsFilePath: _cghsFile?.path,
        echsFilePath: _echsFile?.path,
      );
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

  void _showValidation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<PatientProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_isEdit ? 'Edit Patient' : 'New Patient')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Full Name',
                controller: _nameCtrl,
                validator: AppValidators.required,
                prefixIcon: const Icon(Icons.person_outline),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Phone Number',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: AppValidators.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Email (optional)',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: AppValidators.email,
                prefixIcon: const Icon(Icons.email_outlined),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Age',
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'female', child: Text('Female')),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ProofPickerTile(
                title: 'ID proof',
                enabled: _hasIdProof,
                fileName: _idProofFile?.name,
                existingUrl: widget.editPatient?.idProofFileUrl,
                onChanged: (value) => setState(() => _hasIdProof = value),
                onPick: () => _pickProof('id'),
              ),
              const SizedBox(height: 10),
              _ProofPickerTile(
                title: 'CGHS',
                enabled: _hasCghs,
                fileName: _cghsFile?.name,
                existingUrl: widget.editPatient?.cghsFileUrl,
                onChanged: (value) => setState(() => _hasCghs = value),
                onPick: () => _pickProof('cghs'),
              ),
              const SizedBox(height: 10),
              _ProofPickerTile(
                title: 'ECHS',
                enabled: _hasEchs,
                fileName: _echsFile?.name,
                existingUrl: widget.editPatient?.echsFileUrl,
                onChanged: (value) => setState(() => _hasEchs = value),
                onPick: () => _pickProof('echs'),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: _isEdit ? 'Update Patient' : 'Add Patient',
                onPressed: _submit,
                isLoading: isLoading,
                icon: _isEdit ? Icons.save : Icons.person_add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProofPickerTile extends StatelessWidget {
  final String title;
  final bool enabled;
  final String? fileName;
  final String? existingUrl;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPick;

  const _ProofPickerTile({
    required this.title,
    required this.enabled,
    required this.fileName,
    required this.existingUrl,
    required this.onChanged,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null || (existingUrl?.isNotEmpty ?? false);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Switch(value: enabled, onChanged: onChanged),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  hasFile ? (fileName ?? 'Uploaded') : 'No file selected',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: enabled ? onPick : null,
            icon: const Icon(Icons.upload_file),
          ),
        ],
      ),
    );
  }
}
