import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/mock_auth_service.dart';

class AuthRepository {
  final MockAuthService? _mockAuthService;
  final FirebaseAuthService? _firebaseAuthService;

  AuthRepository({
    MockAuthService? mockAuthService,
    FirebaseAuthService? firebaseAuthService,
  })  : _mockAuthService = mockAuthService,
        _firebaseAuthService = firebaseAuthService;

  bool get isFirebase => _firebaseAuthService != null;

  UserModel? get currentUser {
    if (_firebaseAuthService != null) {
      return _firebaseAuthService.currentUser;
    }
    return _mockAuthService?.currentUser;
  }

  Stream<UserModel?> get authStateChanges {
    if (_firebaseAuthService != null) {
      return _firebaseAuthService.authStateChanges;
    }
    return Stream.value(currentUser);
  }

  Future<UserModel> login({required String email, required String password}) {
    if (_firebaseAuthService != null) {
      return _firebaseAuthService.login(email: email, password: password);
    }
    return _mockAuthService!.login(email: email, password: password);
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    if (_firebaseAuthService != null) {
      return _firebaseAuthService.signUp(name: name, email: email, password: password);
    }
    return _mockAuthService!.signUp(name: name, email: email, password: password);
  }

  Future<void> sendPasswordResetEmail(String email) {
    if (_firebaseAuthService != null) {
      return _firebaseAuthService.sendPasswordResetEmail(email);
    }
    return _mockAuthService!.sendPasswordResetEmail(email);
  }

  Future<void> logout() {
    if (_firebaseAuthService != null) {
      return _firebaseAuthService.logout();
    }
    return _mockAuthService!.logout();
  }
}
