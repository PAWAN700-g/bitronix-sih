import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sih_smart_water/features/auth/screens/login_screen.dart';
import '../../../providers/auth_provider.dart';
import '../../navigation/screens/main_navigation_screen.dart';
import 'signup_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // User is authenticated -> Open Main Application
          return const MainNavigationScreen();
        }
        // New or signed out person -> Open Sign Up Screen
        return const SignUpScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => const SignUpScreen(),
    );
  }
}
