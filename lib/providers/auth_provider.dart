import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/firebase_auth_service.dart';
import '../services/mock_auth_service.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService?>((ref) {
  try {
    return FirebaseAuthService();
  } catch (_) {
    return null;
  }
});

final mockAuthServiceProvider = Provider<MockAuthService>((ref) {
  return MockAuthService();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthServiceProvider);
  final mockAuth = ref.watch(mockAuthServiceProvider);

  return AuthRepository(
    firebaseAuthService: firebaseAuth,
    mockAuthService: mockAuth,
  );
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});

class AuthStateNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;

  AuthStateNotifier(this._repository)
      : super(AsyncValue.data(_repository.currentUser)) {
    _initListener();
  }

  void _initListener() {
    _repository.authStateChanges.listen((user) {
      state = AsyncValue.data(user);
    });
  }

  Future<void> login(String email, String password, {UserRole role = UserRole.consumer}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(email: email, password: password, role: role);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp(String name, String email, String password, {UserRole role = UserRole.consumer}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signUp(name: name, email: email, password: password, role: role);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _repository.sendPasswordResetEmail(email);
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}
