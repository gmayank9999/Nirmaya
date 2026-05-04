import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../core/utils/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();
  final _storage = StorageService();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> checkAuth() async {
    final hasToken = await _storage.hasToken();
    if (!hasToken) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    final cachedUser = await _storage.getUser();
    if (cachedUser != null) {
      _user = UserModel.fromJson(cachedUser);
      _status = AuthStatus.authenticated;
      notifyListeners();
    }
    final user = await _repo.verifyToken();
    if (user != null) {
      _user = user;
      _status = AuthStatus.authenticated;
    } else if (cachedUser == null) {
      await _storage.clear();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String phone, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repo.login(phone: phone, password: password);
      _user = result.user;
      _status = AuthStatus.authenticated;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
