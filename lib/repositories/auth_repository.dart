import '../models/user_model.dart';
import '../services/mock_auth_service.dart';

class AuthRepository {
  final MockAuthService _authService;

  AuthRepository({MockAuthService? authService})
      : _authService = authService ?? MockAuthService();

  UserModel? get currentUser => _authService.currentUser;

  Future<UserModel> login({required String email, required String password}) {
    return _authService.login(email: email, password: password);
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return _authService.signUp(name: name, email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _authService.sendPasswordResetEmail(email);
  }

  Future<void> logout() {
    return _authService.logout();
  }
}
