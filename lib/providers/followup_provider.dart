import 'package:flutter/foundation.dart';
import '../models/followup_model.dart';
import '../repositories/followup_repository.dart';

class FollowupProvider extends ChangeNotifier {
  final _repo = FollowupRepository();

  List<FollowupModel> _followups = [];
  int _total = 0;
  bool _isLoading = false;
  String? _error;

  List<FollowupModel> get followups => _followups;
  int get total => _total;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadFollowups({
    String? patientId,
    String? treatmentId,
    String? status,
    bool refresh = false,
  }) async {
    if (refresh) _followups = [];
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.list(
        patientId: patientId,
        treatmentId: treatmentId,
        status: status,
      );
      _followups = result.followups;
      _total = result.total;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FollowupModel?> createFollowup(Map<String, dynamic> body) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final f = await _repo.create(body);
      _followups.insert(0, f);
      _total++;
      return f;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<FollowupModel?> updateFollowup(
      String id, Map<String, dynamic> body) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _repo.update(id, body);
      final idx = _followups.indexWhere((f) => f.id == id);
      if (idx >= 0) _followups[idx] = updated;
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
}
