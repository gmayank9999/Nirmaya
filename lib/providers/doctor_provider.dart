import 'package:flutter/foundation.dart';
import '../models/doctor_model.dart';
import '../repositories/doctor_repository.dart';

class DoctorProvider extends ChangeNotifier {
  final _repo = DoctorRepository();

  List<DoctorModel> _doctors = [];
  bool _isLoading = false;
  String? _error;

  List<DoctorModel> get doctors => _doctors;
  List<DoctorModel> get activeDoctors =>
      _doctors.where((d) => d.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Loads all doctors, including inactive ones, so the management screen can
  /// re-enable them. Booking UIs should use [activeDoctors].
  Future<void> loadDoctors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _doctors = await _repo.list(includeInactive: true);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addDoctor(Map<String, dynamic> body) =>
      _mutate(() => _repo.create(body));

  Future<bool> updateDoctor(String id, Map<String, dynamic> body) =>
      _mutate(() => _repo.update(id, body));

  Future<bool> _mutate(Future<DoctorModel> Function() action) async {
    _error = null;
    try {
      await action();
      await loadDoctors();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
