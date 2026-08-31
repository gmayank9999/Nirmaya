import 'package:flutter/foundation.dart';
import '../models/treatment_model.dart';
import '../models/visit_model.dart';
import '../models/transaction_model.dart';
import '../models/document_model.dart';
import '../repositories/treatment_repository.dart';

class TreatmentProvider extends ChangeNotifier {
  final _repo = TreatmentRepository();

  List<TreatmentModel> _treatments = [];
  int _total = 0;
  bool _isLoading = false;
  String? _error;

  TreatmentModel? _selectedTreatment;
  List<VisitModel> _treatmentVisits = [];
  List<TransactionModel> _treatmentTransactions = [];
  List<DocumentModel> _treatmentDocuments = [];
  double _balance = 0;
  double _paidAmount = 0;

  List<TreatmentModel> get treatments => _treatments;
  int get total => _total;
  bool get isLoading => _isLoading;
  String? get error => _error;
  TreatmentModel? get selectedTreatment => _selectedTreatment;
  List<VisitModel> get treatmentVisits => _treatmentVisits;
  List<TransactionModel> get treatmentTransactions => _treatmentTransactions;
  List<DocumentModel> get treatmentDocuments => _treatmentDocuments;
  double get balance => _balance;
  double get paidAmount => _paidAmount;

  Future<void> loadTreatments({
    String? patientId,
    String? status,
    String? filter,
    bool refresh = false,
  }) async {
    if (refresh) _treatments = [];
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.list(
        patientId: patientId,
        status: status,
        filter: filter,
      );
      _treatments = result.treatments;
      _total = result.total;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTreatmentDetail(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _repo.getById(id);
      _selectedTreatment = TreatmentModel.fromJson(
          data['treatment'] as Map<String, dynamic>? ?? data);
      final balanceData = data['balance'];
      if (balanceData is Map<String, dynamic>) {
        _balance = double.tryParse(balanceData['balance'].toString()) ??
            _selectedTreatment!.balanceDouble;
        _paidAmount = double.tryParse(balanceData['paidAmount'].toString()) ??
            _selectedTreatment!.paidAmountDouble;
      } else {
        _balance = double.tryParse(balanceData?.toString() ?? '') ??
            _selectedTreatment!.balanceDouble;
        _paidAmount = double.tryParse(data['paidAmount']?.toString() ?? '') ??
            _selectedTreatment!.paidAmountDouble;
      }
      final visitsRaw = data['visits'] as List<dynamic>?;
      final txRaw = data['transactions'] as List<dynamic>?;
      final documentsRaw = data['documents'] as List<dynamic>?;
      if (visitsRaw != null) {
        _treatmentVisits = visitsRaw
            .map((e) => VisitModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (txRaw != null) {
        _treatmentTransactions = txRaw
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (documentsRaw != null) {
        _treatmentDocuments = documentsRaw
            .map((e) => DocumentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TreatmentModel?> createTreatment(Map<String, dynamic> body) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final treatment = await _repo.create(body);
      _treatments.insert(0, treatment);
      _total++;
      return treatment;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TreatmentModel?> updateTreatment(
      String id, Map<String, dynamic> body) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updated = await _repo.update(id, body);
      final idx = _treatments.indexWhere((t) => t.id == id);
      if (idx >= 0) _treatments[idx] = updated;
      if (_selectedTreatment?.id == id) _selectedTreatment = updated;
      return updated;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelected() {
    _selectedTreatment = null;
    _treatmentVisits = [];
    _treatmentTransactions = [];
    _treatmentDocuments = [];
    _balance = 0;
    _paidAmount = 0;
    notifyListeners();
  }

  // ── Instant local updates for the Visits tab ────────────────────────────
  void addVisitToDetail(VisitModel visit) {
    _treatmentVisits.insert(0, visit);
    notifyListeners();
  }

  void updateVisitInDetail(VisitModel updated) {
    final idx = _treatmentVisits.indexWhere((v) => v.id == updated.id);
    if (idx >= 0) {
      _treatmentVisits[idx] = updated;
      notifyListeners();
    }
  }

  void removeVisitFromDetail(String visitId) {
    _treatmentVisits.removeWhere((v) => v.id == visitId);
    notifyListeners();
  }

  // ── Instant local updates for the Payments tab ────────────────────────────
  // The detail screen watches _treatmentTransactions; add/edit/delete here so
  // the UI updates immediately without a full reload.
  void addTransactionToDetail(TransactionModel tx) {
    _treatmentTransactions.insert(0, tx);
    // Update running paid/balance totals locally
    _paidAmount += tx.amountDouble;
    if (_selectedTreatment != null) {
      _balance = (_selectedTreatment!.finalFee - _paidAmount)
          .clamp(0, double.infinity);
    }
    notifyListeners();
  }

  void updateTransactionInDetail(TransactionModel updated) {
    final idx = _treatmentTransactions.indexWhere((t) => t.id == updated.id);
    if (idx >= 0) {
      final old = _treatmentTransactions[idx];
      _treatmentTransactions[idx] = updated;
      _paidAmount = _paidAmount - old.amountDouble + updated.amountDouble;
      if (_selectedTreatment != null) {
        _balance = (_selectedTreatment!.finalFee - _paidAmount)
            .clamp(0, double.infinity);
      }
    }
    notifyListeners();
  }

  void removeTransactionFromDetail(String txId) {
    final idx = _treatmentTransactions.indexWhere((t) => t.id == txId);
    if (idx >= 0) {
      _paidAmount -= _treatmentTransactions[idx].amountDouble;
      _treatmentTransactions.removeAt(idx);
      if (_selectedTreatment != null) {
        _balance = (_selectedTreatment!.finalFee - _paidAmount)
            .clamp(0, double.infinity);
      }
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
