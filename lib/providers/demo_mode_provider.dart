import 'package:flutter_riverpod/flutter_riverpod.dart';

final demoModeProvider = StateNotifierProvider<DemoModeNotifier, bool>((ref) {
  return DemoModeNotifier();
});

class DemoModeNotifier extends StateNotifier<bool> {
  DemoModeNotifier() : super(false); // Default DEMO MODE OFF - Live Firebase Realtime DB mode

  void toggleDemoMode() {
    state = !state;
  }

  void setDemoMode(bool enabled) {
    state = enabled;
  }
}
