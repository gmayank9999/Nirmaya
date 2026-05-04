import 'package:flutter/foundation.dart';
import '../models/document_model.dart';
import '../repositories/document_repository.dart';

class DocumentProvider extends ChangeNotifier {
  final _repo = DocumentRepository();

  List<DocumentModel> _documents = [];
  bool _isLoading = false;
  String? _error;

  List<DocumentModel> get documents => _documents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadDocuments(
      {String? patientId, String? treatmentId, String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.list(
        patientId: patientId,
        treatmentId: treatmentId,
        category: category,
      );
      _documents = result.documents;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteDocument(String id) async {
    try {
      await _repo.delete(id);
      _documents.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<DocumentModel?> uploadDocument({
    required String filePath,
    required String patientId,
    String? treatmentId,
    String? visitId,
    required String category,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final document = await _repo.upload(
        filePath: filePath,
        patientId: patientId,
        treatmentId: treatmentId,
        visitId: visitId,
        category: category,
      );
      _documents.insert(0, document);
      return document;
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
