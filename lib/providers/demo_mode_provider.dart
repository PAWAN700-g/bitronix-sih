import 'package:flutter_riverpod/flutter_riverpod.dart';

final demoModeProvider = StateNotifierProvider<DemoModeNotifier, bool>((ref) {
  return DemoModeNotifier();
});

class DemoModeNotifier extends StateNotifier<bool> {
  DemoModeNotifier() : super(true); // Default DEMO MODE ON for SIH presentation

  void toggleDemoMode() {
    state = !state;
  }

  void setDemoMode(bool enabled) {
    state = enabled;
  }
}
