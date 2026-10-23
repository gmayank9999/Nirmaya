import 'package:flutter/material.dart';
import '../repositories/patient_repository.dart';
import '../repositories/treatment_repository.dart';

class PaymentSmsOption extends StatefulWidget {
  final String? patientId;
  final String treatmentId;
  final bool value;
  final ValueChanged<bool> onChanged;
  const PaymentSmsOption(
      {super.key,
      this.patientId,
      required this.treatmentId,
      required this.value,
      required this.onChanged});

  @override
  State<PaymentSmsOption> createState() => _PaymentSmsOptionState();
}

class _PaymentSmsOptionState extends State<PaymentSmsOption> {
  String? _phone;
  String? _name;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      var patientId = widget.patientId;
      if (patientId == null) {
        final detail = await TreatmentRepository().getById(widget.treatmentId);
        final treatment =
            detail['treatment'] as Map<String, dynamic>? ?? detail;
        patientId = treatment['patientId'] as String;
      }
      final patient = await PatientRepository().getById(patientId);
      if (!mounted) return;
      setState(() {
        _phone = patient.phone;
        _name = patient.name;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = (_phone ?? '').replaceAll(RegExp(r'\D'), '');
    final valid = RegExp(r'^(91)?[6-9]\d{9}$').hasMatch(digits);
    return SwitchListTile(
      title: const Text('Send payment SMS'),
      subtitle: Text(_loading
          ? 'Loading patient number…'
          : _failed
              ? 'Could not load patient number. Reopen to retry.'
              : valid
                  ? '$_name • $_phone\nSend after saving this payment.'
                  : 'No valid mobile number. Update the patient profile first.'),
      value: widget.value && valid,
      onChanged: valid ? widget.onChanged : null,
    );
  }
}

class UpiQrCard extends StatelessWidget {
  const UpiQrCard({super.key});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Sample Clinic — Demo QR',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Image.asset('assets/images/upi_sample.png',
                  width: 220, height: 220),
              const Text('Demo only • Do not pay using this QR'),
              const Text(
                  'Replace with the clinic’s actual payment QR before use.',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
