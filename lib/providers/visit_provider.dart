import 'package:flutter/foundation.dart';
import '../models/visit_model.dart';
import '../repositories/visit_repository.dart';

class VisitProvider extends ChangeNotifier {
  final _repo = VisitRepository();

  List<VisitModel> _visits = [];
  Map<String, dynamic>? _selectedVisitDetail;
  bool _isLoading = false;
  String? _error;

  List<VisitModel> get visits => _visits;
  Map<String, dynamic>? get selectedVisitDetail => _selectedVisitDetail;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadVisits({required String treatmentId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.list(treatmentId: treatmentId);
      _visits = result.visits;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<VisitModel?> createVisit(Map<String, dynamic> body) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final visit = await _repo.create(body);
      _visits.insert(0, visit);
      return visit;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> loadVisitDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _selectedVisitDetail = await _repo.getById(id);
      return _selectedVisitDetail;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> createVisitWithDetails({
    required Map<String, String> fields,
    List<String> reportFilePaths = const [],
    List<String> reportNames = const [],
    List<String> prescriptionFilePaths = const [],
    List<String> prescriptionNames = const [],
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _repo.createWithDetails(
        fields: fields,
        reportFilePaths: reportFilePaths,
        reportNames: reportNames,
        prescriptionFilePaths: prescriptionFilePaths,
        prescriptionNames: prescriptionNames,
      );
      final visit = VisitModel.fromJson(res['visit'] as Map<String, dynamic>);
      _visits.insert(0, visit);
      
      return res; // returns { 'visit': Map, 'transaction': Map?, 'documents': List }
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteVisit(String id) async {
    try {
      await _repo.delete(id);
      _visits.removeWhere((v) => v.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
