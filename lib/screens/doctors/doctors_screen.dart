import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/doctor_model.dart';
import '../../providers/doctor_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/empty_state_widget.dart';

/// Admin-only management of the clinic's doctors (reached from Profile).
class DoctorsScreen extends StatefulWidget {
  /// Open the add-doctor form immediately (used by the dashboard shortcut).
  final bool openForm;
  const DoctorsScreen({super.key, this.openForm = false});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DoctorProvider>().loadDoctors();
      if (widget.openForm) _openForm();
    });
  }

  Future<void> _openForm([DoctorModel? doctor]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DoctorForm(doctor: doctor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DoctorProvider>();
    final doctors = provider.doctors;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Doctors')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add Doctor'),
      ),
      body: provider.isLoading && doctors.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : doctors.isEmpty
              ? const EmptyStateWidget(
                  title: 'No doctors yet',
                  subtitle: 'Add a doctor to start booking appointments',
                  icon: Icons.medical_services_outlined,
                )
              : RefreshIndicator(
                  onRefresh: provider.loadDoctors,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: doctors.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _DoctorTile(
                      doctor: doctors[i],
                      onTap: () => _openForm(doctors[i]),
                    ),
                  ),
                ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  final DoctorModel doctor;
  final VoidCallback onTap;
  const _DoctorTile({required this.doctor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (doctor.specialization?.isNotEmpty == true) doctor.specialization!,
      if (doctor.phone?.isNotEmpty == true) doctor.phone!,
    ].join(' • ');

    return Opacity(
      opacity: doctor.isActive ? 1 : 0.55,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primarySurface,
                  child: const Icon(Icons.medical_services_outlined,
                      color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                if (!doctor.isActive)
                  const Text('Inactive',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                const Icon(Icons.chevron_right, color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorForm extends StatefulWidget {
  final DoctorModel? doctor;
  const _DoctorForm({this.doctor});

  @override
  State<_DoctorForm> createState() => _DoctorFormState();
}

class _DoctorFormState extends State<_DoctorForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.doctor?.name);
  late final _specCtrl =
      TextEditingController(text: widget.doctor?.specialization);
  late final _phoneCtrl = TextEditingController(text: widget.doctor?.phone);
  late bool _isActive = widget.doctor?.isActive ?? true;
  bool _saving = false;

  bool get _isEdit => widget.doctor != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _saving = true);
    final provider = context.read<DoctorProvider>();
    final body = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'specialization': _specCtrl.text.trim().isEmpty ? null : _specCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      if (_isEdit) 'isActive': _isActive,
    };
    final ok = _isEdit
        ? await provider.updateDoctor(widget.doctor!.id, body)
        : await provider.addDoctor(body);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Failed to save doctor'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? 'Edit Doctor' : 'Add Doctor',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Name',
              controller: _nameCtrl,
              prefixIcon: const Icon(Icons.person_outline),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Specialization (optional)',
              controller: _specCtrl,
              prefixIcon: const Icon(Icons.medical_services_outlined),
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Phone (optional)',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined),
            ),
            if (_isEdit)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                subtitle: const Text('Inactive doctors cannot be booked'),
                value: _isActive,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            const SizedBox(height: 16),
            AppButton(
              label: _isEdit ? 'Save Changes' : 'Add Doctor',
              onPressed: _save,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
