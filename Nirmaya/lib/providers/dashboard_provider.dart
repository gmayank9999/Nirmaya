import 'package:flutter/foundation.dart';
import '../models/dashboard_patient_model.dart';
import '../models/patient_model.dart';
import '../repositories/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final _repo = DashboardRepository();

  List<DashboardPatientModel> _patients = [];
  int _total = 0;
  int _activeTreatments = 0;
  int _todaysFollowups = 0;
  double _todaysCollection = 0;
  List<PatientModel> _recentPatients = [];
  bool _isLoading = false;
  String? _error;

  List<DashboardPatientModel> get patients => _patients;
  int get total => _total;
  int get activeTreatments => _activeTreatments;
  int get todaysFollowups => _todaysFollowups;
  double get todaysCollection => _todaysCollection;
  List<PatientModel> get recentPatients => _recentPatients;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get activeTreatmentCount =>
      _patients.fold(0, (sum, patient) => sum + patient.ongoingTreatmentCount);

  Future<void> loadSummary() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final summary = await _repo.getSummary();
      _total = summary.totalPatients;
      _activeTreatments = summary.activeTreatments;
      _todaysFollowups = summary.todaysFollowups;
      _todaysCollection = summary.todaysCollection;
      _recentPatients = summary.recentPatients;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPatients({
    String? search,
    String? status,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    bool refresh = false,
  }) async {
    if (refresh) _patients = [];
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.listPatients(
        search: search,
        status: status,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
      _patients = result.patients;
      _total = result.total;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
