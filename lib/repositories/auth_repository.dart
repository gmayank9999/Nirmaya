import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../core/utils/storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _client = ApiClient();
  final _storage = StorageService();

  Future<({String token, UserModel user})> login({
    required String phone,
    required String password,
  }) async {
    final res = await _client.post(
      ApiEndpoints.login,
      body: {'phone': phone, 'password': password},
    );
    final data = res['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _storage.saveToken(token);
    await _storage.saveUser(user.toJson());
    return (token: token, user: user);
  }

  Future<UserModel?> verifyToken() async {
    try {
      final res = await _client.get(ApiEndpoints.verifyToken);
      final data = res['data'] as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userJson);
      await _storage.saveUser(user.toJson());
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storage.clear();
  }
}
