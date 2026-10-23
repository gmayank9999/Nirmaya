import 'package:flutter/material.dart' show TimeOfDay;

class AppointmentModel {
  final String id;
  final String doctorId;
  final String? doctorName;
  final String? patientId;
  final String patientName;
  final String? patientPhone;

  /// Clinic-local calendar date, `YYYY-MM-DD`.
  final String appointmentDate;

  /// Clinic-local 24h time, `HH:MM`.
  final String startTime;
  final int durationMinutes;
  final String? reason;
  final String status;
  final String? notes;

  const AppointmentModel({
    required this.id,
    required this.doctorId,
    this.doctorName,
    this.patientId,
    required this.patientName,
    this.patientPhone,
    required this.appointmentDate,
    required this.startTime,
    required this.durationMinutes,
    this.reason,
    required this.status,
    this.notes,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] as String,
      doctorId: json['doctorId'] as String,
      doctorName: json['doctorName'] as String?,
      patientId: json['patientId'] as String?,
      patientName: json['patientName'] as String? ?? '',
      patientPhone: json['patientPhone'] as String?,
      appointmentDate: json['appointmentDate'] as String,
      startTime: json['startTime'] as String,
      durationMinutes: json['durationMinutes'] as int? ?? 30,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'scheduled',
      notes: json['notes'] as String?,
    );
  }

  DateTime get date {
    final p = appointmentDate.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]);
  }

  TimeOfDay get time {
    final p = startTime.split(':').map(int.parse).toList();
    return TimeOfDay(hour: p[0], minute: p[1]);
  }

  bool get isScheduled => status == 'scheduled';

  String get statusDisplay {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'no_show':
        return 'No show';
      default:
        return 'Scheduled';
    }
  }
}
