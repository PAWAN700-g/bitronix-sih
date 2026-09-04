import '../models/user_model.dart';

class MockAuthService {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  Future<UserModel> login({
    required String email,
    required String password,
    UserRole role = UserRole.consumer,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    final effectiveRole = (email.contains('gov') || email.contains('sih'))
        ? UserRole.govtAuthority
        : role;
    _currentUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: email.split('@').first.toUpperCase(),
      email: email,
      role: effectiveRole,
      department: effectiveRole == UserRole.govtAuthority ? 'Jal Shakti Ministry Inspection' : null,
    );
    return _currentUser!;
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.consumer,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }
    final effectiveRole = (email.contains('gov') || email.contains('sih'))
        ? UserRole.govtAuthority
        : role;
    _currentUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      role: effectiveRole,
      department: effectiveRole == UserRole.govtAuthority ? 'Jal Shakti Ministry Inspection' : null,
    );
    return _currentUser!;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!email.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }
}
