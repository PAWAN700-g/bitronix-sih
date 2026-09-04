import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/mock_auth_service.dart';

class AuthRepository {
  final MockAuthService? _mockAuthService;
  final FirebaseAuthService? _firebaseAuthService;
  final StreamController<UserModel?> _authController = StreamController<UserModel?>.broadcast();
  UserModel? _fallbackUser;

  AuthRepository({
    MockAuthService? mockAuthService,
    FirebaseAuthService? firebaseAuthService,
  })  : _mockAuthService = mockAuthService,
        _firebaseAuthService = firebaseAuthService {
    final fbService = _firebaseAuthService;
    if (fbService != null) {
      fbService.authStateChanges.listen((user) {
        if (user != null) {
          _fallbackUser = user;
          _authController.add(user);
        } else if (_fallbackUser == null) {
          _authController.add(null);
        }
      });
    }
  }

  bool get isFirebase => _firebaseAuthService != null;

  UserModel? get currentUser {
    if (_fallbackUser != null) return _fallbackUser;
    final fbService = _firebaseAuthService;
    if (fbService != null && fbService.currentUser != null) {
      return fbService.currentUser;
    }
    return _mockAuthService?.currentUser;
  }

  Stream<UserModel?> get authStateChanges => _authController.stream;

  Future<UserModel> login({required String email, required String password}) async {
    final fbService = _firebaseAuthService;
    final mockService = _mockAuthService;

    if (fbService != null) {
      try {
        final user = await fbService.login(email: email, password: password);
        _fallbackUser = user;
        _authController.add(user);
        return user;
      } catch (e) {
        debugPrint('Firebase Auth Login notice ($e). Trying auto-registration or fallback...');
        try {
          final user = await fbService.signUp(
            name: email.split('@').first,
            email: email,
            password: password,
          );
          _fallbackUser = user;
          _authController.add(user);
          return user;
        } catch (e2) {
          debugPrint('Firebase Auth SignUp notice ($e2). Using fallback auth...');
        }
      }
    }

    if (mockService != null) {
      final user = await mockService.login(email: email, password: password);
      _fallbackUser = user;
      _authController.add(user);
      return user;
    }

    throw Exception('Authentication service unavailable. Please try again.');
  }

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final fbService = _firebaseAuthService;
    final mockService = _mockAuthService;

    if (fbService != null) {
      try {
        final user = await fbService.signUp(name: name, email: email, password: password);
        _fallbackUser = user;
        _authController.add(user);
        return user;
      } catch (e) {
        debugPrint('Firebase Auth SignUp notice ($e). Using fallback auth...');
      }
    }

    if (mockService != null) {
      final user = await mockService.signUp(name: name, email: email, password: password);
      _fallbackUser = user;
      _authController.add(user);
      return user;
    }

    throw Exception('Authentication service unavailable. Please try again.');
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final fbService = _firebaseAuthService;
    final mockService = _mockAuthService;

    if (fbService != null) {
      try {
        await fbService.sendPasswordResetEmail(email);
        return;
      } catch (_) {}
    }
    if (mockService != null) {
      await mockService.sendPasswordResetEmail(email);
    }
  }

  Future<void> logout() async {
    _fallbackUser = null;
    final fbService = _firebaseAuthService;
    final mockService = _mockAuthService;

    if (fbService != null) {
      try {
        await fbService.logout();
      } catch (_) {}
    }
    if (mockService != null) {
      await mockService.logout();
    }
    _authController.add(null);
  }
}
