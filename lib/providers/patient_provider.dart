import 'package:flutter/foundation.dart';
import '../models/patient_model.dart';
import '../repositories/patient_repository.dart';

class PatientProvider extends ChangeNotifier {
  final PatientRepository _repo;

  PatientProvider({PatientRepository? repository})
      : _repo = repository ?? PatientRepository();

  List<PatientModel> _patients = [];
  int _total = 0;
  bool _isLoading = false;
  bool _isLoadingList = false;
  int _listRequestId = 0;
  bool _isLoadingMore = false;
  String? _error;
  String _search = '';
  String? _gender;
  bool? _hasIdProof;
  bool? _hasCghs;
  bool? _hasEchs;
  double? _minPending;
  bool _highestPendingFirst = false;
  int _page = 1;
  static const int _limit = 20;

  PatientModel? _selectedPatient;

  List<PatientModel> get patients => _patients;
  int get total => _total;
  bool get isLoading => _isLoading || _isLoadingList;
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
    double? minPending,
    bool highestPendingFirst = false,
    bool refresh = false,
    bool filtersChanged = false,
  }) async {
    if (filtersChanged) {
      _gender = gender;
      _hasIdProof = hasIdProof;
      _hasCghs = hasCghs;
      _hasEchs = hasEchs;
      _minPending = minPending;
      _highestPendingFirst = highestPendingFirst;
    }
    // Every new query supersedes earlier searches and pagination requests.
    // An omitted search preserves it; an empty string explicitly clears it.
    if (search != null) _search = search.trim();
    final requestId = ++_listRequestId;
    _page = 1;
    _patients = [];
    _total = 0;
    _isLoadingList = true;
    _isLoadingMore = false;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.list(
        search: _search,
        gender: _gender,
        hasIdProof: _hasIdProof,
        hasCghs: _hasCghs,
        hasEchs: _hasEchs,
        minPending: _minPending,
        highestPendingFirst: _highestPendingFirst,
        page: _page,
        limit: _limit,
      );
      if (requestId != _listRequestId) return;
      _patients = result.patients;
      _total = result.total;
    } catch (e) {
      if (requestId != _listRequestId) return;
      _error = e.toString();
    } finally {
      if (requestId == _listRequestId) {
        _isLoadingList = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingList || _isLoadingMore || !hasMore) return;
    final requestId = _listRequestId;
    final nextPage = _page + 1;
    _isLoadingMore = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.list(
        search: _search,
        gender: _gender,
        hasIdProof: _hasIdProof,
        hasCghs: _hasCghs,
        hasEchs: _hasEchs,
        minPending: _minPending,
        highestPendingFirst: _highestPendingFirst,
        page: nextPage,
        limit: _limit,
      );
      if (requestId != _listRequestId) return;
      _page = nextPage;
      _patients.addAll(result.patients);
      _total = result.total;
    } catch (e) {
      if (requestId != _listRequestId) return;
      _error = e.toString();
    } finally {
      if (requestId == _listRequestId) {
        _isLoadingMore = false;
        notifyListeners();
      }
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
