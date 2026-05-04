import 'package:flutter/foundation.dart';
import '../models/installment_model.dart';
import '../repositories/installment_repository.dart';

class InstallmentProvider extends ChangeNotifier {
  final _repo = InstallmentRepository();

  List<InstallmentModel> _installments = [];
  bool _isLoading = false;
  String? _error;

  List<InstallmentModel> get installments => _installments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInstallments(
      {required String treatmentId, String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.list(treatmentId: treatmentId, status: status);
      _installments = result.installments;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createInstallments(Map<String, dynamic> body) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final created = await _repo.create(body);
      _installments.add(created);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsPaid(String id) async {
    _error = null;
    try {
      final updated = await _repo.update(id, {'status': 'paid'});
      final idx = _installments.indexWhere((i) => i.id == id);
      if (idx >= 0) _installments[idx] = updated;
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
