import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/appointment_model.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Book a new appointment, or reschedule/edit [editAppointment].
class AddAppointmentScreen extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialDoctorId;
  final AppointmentModel? editAppointment;

  const AddAppointmentScreen({
    super.key,
    this.initialDate,
    this.initialDoctorId,
    this.editAppointment,
  });

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  static const _durations = [15, 30, 45, 60];

  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl =
      TextEditingController(text: widget.editAppointment?.patientName);
  late final _phoneCtrl =
      TextEditingController(text: widget.editAppointment?.patientPhone);
  late final _reasonCtrl =
      TextEditingController(text: widget.editAppointment?.reason);

  String? _doctorId;
  late DateTime _date;
  late TimeOfDay _time;
  late int _duration;
  bool _saving = false;

  bool get _isEdit => widget.editAppointment != null;

  @override
  void initState() {
    super.initState();
    final e = widget.editAppointment;
    _doctorId = e?.doctorId ?? widget.initialDoctorId;
    _date = e?.date ?? widget.initialDate ?? DateTime.now();
    _time = e?.time ?? const TimeOfDay(hour: 10, minute: 0);
    _duration = e?.durationMinutes ?? 30;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final doctors = context.read<DoctorProvider>();
      if (doctors.doctors.isEmpty) await doctors.loadDoctors();
      if (!mounted) return;
      // With a single active doctor there is nothing to choose.
      if (_doctorId == null && doctors.activeDoctors.length == 1) {
        setState(() => _doctorId = doctors.activeDoctors.first.id);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: _isEdit ? DateTime(now.year - 1) : DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a doctor'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<AppointmentProvider>();
    final body = <String, dynamic>{
      'doctorId': _doctorId,
      'patientName': _nameCtrl.text.trim(),
      'patientPhone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      'appointmentDate': DateFormat('yyyy-MM-dd').format(_date),
      'startTime': '${_two(_time.hour)}:${_two(_time.minute)}',
      'durationMinutes': _duration,
      'reason': _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
    };
    final ok = _isEdit
        ? await provider.update(widget.editAppointment!.id, body)
        : await provider.create(body);
    if (!mounted) return;
    if (ok) {
      context.pop();
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(provider.error ?? 'Failed to save appointment'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctors = context.watch<DoctorProvider>().activeDoctors;
    // An edited appointment may point at a doctor that was since deactivated.
    final hasSelected = doctors.any((d) => d.id == _doctorId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
          title: Text(_isEdit ? 'Edit Appointment' : 'New Appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey(hasSelected ? _doctorId : null),
                initialValue: hasSelected ? _doctorId : null,
                decoration: const InputDecoration(
                  labelText: 'Doctor',
                  prefixIcon: Icon(Icons.medical_services_outlined),
                ),
                items: [
                  for (final d in doctors)
                    DropdownMenuItem(
                      value: d.id,
                      child: Text(d.specialization?.isNotEmpty == true
                          ? '${d.name} (${d.specialization})'
                          : d.name),
                    ),
                ],
                onChanged: (v) => setState(() => _doctorId = v),
                validator: (v) => v == null ? 'Select a doctor' : null,
              ),
              if (doctors.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'No doctors yet. An admin can add one from Profile → Doctors.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Patient Name',
                controller: _nameCtrl,
                prefixIcon: const Icon(Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Patient name is required'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Phone (optional)',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.event_outlined),
                        ),
                        child: Text(DateFormat('dd MMM yyyy').format(_date)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Time',
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        child: Text(_time.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _durations.contains(_duration) ? _duration : null,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  prefixIcon: Icon(Icons.timelapse),
                ),
                items: [
                  for (final d in _durations)
                    DropdownMenuItem(value: d, child: Text('$d minutes')),
                ],
                onChanged: (v) => setState(() => _duration = v ?? 30),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Reason (optional)',
                controller: _reasonCtrl,
                maxLines: 3,
                prefixIcon: const Icon(Icons.notes_outlined),
              ),
              const SizedBox(height: 28),
              AppButton(
                label: _isEdit ? 'Save Changes' : 'Book Appointment',
                onPressed: _submit,
                isLoading: _saving,
                icon: Icons.event_available,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
