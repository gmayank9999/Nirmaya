import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final _repo = TransactionRepository();

  List<TransactionModel> _transactions = [];
  int _total = 0;
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> get transactions => _transactions;
  int get total => _total;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTransactions({
    String? treatmentId,
    String? patientId,
    String? dateFrom,
    String? dateTo,
    String? paymentMode,
    bool refresh = false,
  }) async {
    if (refresh) _transactions = [];
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.list(
        treatmentId: treatmentId,
        patientId: patientId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        paymentMode: paymentMode,
      );
      _transactions = result.transactions;
      _total = result.total;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TransactionModel?> createTransaction(Map<String, dynamic> body) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final tx = await _repo.create(body);
      _transactions.insert(0, tx);
      _total++;
      return tx;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TransactionModel?> updateTransaction(
      String id, Map<String, dynamic> body) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _repo.update(id, body);
      final updated = TransactionModel.fromJson(data);
      final idx = _transactions.indexWhere((t) => t.id == id);
      if (idx >= 0) _transactions[idx] = updated;
      return updated;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      await _repo.delete(id);
      _transactions.removeWhere((t) => t.id == id);
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
