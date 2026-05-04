import 'package:flutter/foundation.dart';
import '../models/patient_model.dart';
import '../repositories/patient_repository.dart';

class PatientProvider extends ChangeNotifier {
  final _repo = PatientRepository();

  List<PatientModel> _patients = [];
  int _total = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _search = '';
  String? _gender;
  bool? _hasIdProof;
  bool? _hasCghs;
  bool? _hasEchs;
  int _page = 1;
  static const int _limit = 20;

  PatientModel? _selectedPatient;

  List<PatientModel> get patients => _patients;
  int get total => _total;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  PatientModel? get selectedPatient => _selectedPatient;
  bool get hasMore => _patients.length < _total;

  Future<void> loadPatients({
    String? search,
    String? gender,
    bool? hasIdProof,
    bool? hasCghs,
    bool? hasEchs,
    bool refresh = false,
    bool filtersChanged = false,
  }) async {
    if (filtersChanged) {
      _gender = gender;
      _hasIdProof = hasIdProof;
      _hasCghs = hasCghs;
      _hasEchs = hasEchs;
    }
    if (refresh || search != _search) {
      _search = search ?? '';
      _page = 1;
      _patients = [];
    }
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.list(
        search: _search,
        gender: _gender,
        hasIdProof: _hasIdProof,
        hasCghs: _hasCghs,
        hasEchs: _hasEchs,
        page: _page,
        limit: _limit,
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

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      _page++;
      final result = await _repo.list(
        search: _search,
        gender: _gender,
        hasIdProof: _hasIdProof,
        hasCghs: _hasCghs,
        hasEchs: _hasEchs,
        page: _page,
        limit: _limit,
      );
      _patients.addAll(result.patients);
      _total = result.total;
    } catch (e) {
      _page--;
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<PatientModel?> loadPatient(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedPatient = await _repo.getById(id);
      return _selectedPatient;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PatientModel?> createPatient(
    Map<String, dynamic> body, {
    String? idProofFilePath,
    String? cghsFilePath,
    String? echsFilePath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final patient = await _repo.create(
        body,
        idProofFilePath: idProofFilePath,
        cghsFilePath: cghsFilePath,
        echsFilePath: echsFilePath,
      );
      _patients.insert(0, patient);
      _total++;
      return patient;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<PatientModel?> updatePatient(
    String id,
    Map<String, dynamic> body, {
    String? idProofFilePath,
    String? cghsFilePath,
    String? echsFilePath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _repo.update(
        id,
        body,
        idProofFilePath: idProofFilePath,
        cghsFilePath: cghsFilePath,
        echsFilePath: echsFilePath,
      );
      final idx = _patients.indexWhere((p) => p.id == id);
      if (idx >= 0) _patients[idx] = updated;
      if (_selectedPatient?.id == id) _selectedPatient = updated;
      return updated;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSelected() {
    _selectedPatient = null;
    notifyListeners();
  }
}
