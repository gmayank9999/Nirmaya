import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Shows a bottom sheet asking user to pick Camera or Gallery, then picks the file.
  Future<void> _pickProof(String type) async {
    final source = await _showImageSourceSheet();
    if (source == null) return;
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 1600,
      maxHeight: 1600,
    );
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

  Future<ImageSource?> _showImageSourceSheet() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Choose Source',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('Camera',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Take a new photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary),
                ),
                title: const Text('From Device',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
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
                maxLength: 10,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
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
              const SizedBox(height: 24),
              // Documents section header
              const Text(
                'Documents (Optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              _ProofPickerTile(
                title: 'ID Proof',
                icon: Icons.badge_outlined,
                enabled: _hasIdProof,
                fileName: _idProofFile?.name,
                existingUrl: widget.editPatient?.idProofFileUrl,
                onChanged: (value) => setState(() => _hasIdProof = value),
                onPick: () => _pickProof('id'),
              ),
              const SizedBox(height: 10),
              _ProofPickerTile(
                title: 'CGHS',
                icon: Icons.local_hospital_outlined,
                enabled: _hasCghs,
                fileName: _cghsFile?.name,
                existingUrl: widget.editPatient?.cghsFileUrl,
                onChanged: (value) => setState(() => _hasCghs = value),
                onPick: () => _pickProof('cghs'),
              ),
              const SizedBox(height: 10),
              _ProofPickerTile(
                title: 'ECHS',
                icon: Icons.military_tech_outlined,
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
  final IconData icon;
  final bool enabled;
  final String? fileName;
  final String? existingUrl;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPick;

  const _ProofPickerTile({
    required this.title,
    required this.icon,
    required this.enabled,
    required this.fileName,
    required this.existingUrl,
    required this.onChanged,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = fileName != null || (existingUrl?.isNotEmpty ?? false);
    final fileLabel = fileName != null
        ? fileName!
        : (existingUrl?.isNotEmpty == true ? 'Uploaded ✓' : 'No file selected');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled
              ? (hasFile ? AppColors.success : AppColors.primary)
              : const Color(0xFFE5E7EB),
          width: enabled ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: enabled ? AppColors.primarySurface : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: enabled ? AppColors.primary : AppColors.textLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fileLabel,
                  style: TextStyle(
                    color: hasFile && enabled ? AppColors.success : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Upload button (shown only when enabled)
          if (enabled)
            GestureDetector(
              onTap: onPick,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasFile ? Icons.refresh_rounded : Icons.upload_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasFile ? 'Change' : 'Upload',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Toggle switch
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
