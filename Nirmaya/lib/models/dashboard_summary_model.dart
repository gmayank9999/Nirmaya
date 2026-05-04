import 'patient_model.dart';

class DashboardSummaryModel {
  final int totalPatients;
  final int activeTreatments;
  final int todaysFollowups;
  final double todaysCollection;
  final List<PatientModel> recentPatients;

  const DashboardSummaryModel({
    required this.totalPatients,
    required this.activeTreatments,
    required this.todaysFollowups,
    required this.todaysCollection,
    required this.recentPatients,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final recent = json['recentPatients'] as List<dynamic>? ?? [];
    return DashboardSummaryModel(
      totalPatients: int.tryParse(json['totalPatients'].toString()) ?? 0,
      activeTreatments: int.tryParse(json['activeTreatments'].toString()) ?? 0,
      todaysFollowups: int.tryParse(json['todaysFollowups'].toString()) ?? 0,
      todaysCollection:
          double.tryParse(json['todaysCollection'].toString()) ?? 0,
      recentPatients: recent
          .map((e) => PatientModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
