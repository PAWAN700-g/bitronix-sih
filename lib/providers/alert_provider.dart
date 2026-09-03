import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert_model.dart';
import '../models/sensor_reading.dart';
import '../repositories/alert_repository.dart';

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  return AlertRepository();
});

final alertsNotifierProvider = StateNotifierProvider<AlertsNotifier, List<AlertModel>>((ref) {
  return AlertsNotifier(ref.watch(alertRepositoryProvider));
});

class AlertsNotifier extends StateNotifier<List<AlertModel>> {
  final AlertRepository _repository;

  AlertsNotifier(this._repository) : super(_repository.alerts);

  void checkAndAddAlerts(SensorReading reading) {
    final generated = _repository.generateAlertsFromReading(reading);
    if (generated.isNotEmpty) {
      // Prepend newly generated unique alerts
      final existingIds = state.map((a) => a.title).toSet();
      final toAdd = generated.where((g) => !existingIds.contains(g.title)).toList();
      if (toAdd.isNotEmpty) {
        state = [...toAdd, ...state];
      }
    }
  }

  void markAsRead(String alertId) {
    _repository.markAsRead(alertId);
    state = [
      for (final alert in state)
        if (alert.id == alertId) alert.copyWith(isRead: true) else alert,
    ];
  }

  void removeAlert(String alertId) {
    _repository.removeAlert(alertId);
    state = state.where((a) => a.id != alertId).toList();
  }

  void clearAll() {
    _repository.clearAll();
    state = [];
  }
}
