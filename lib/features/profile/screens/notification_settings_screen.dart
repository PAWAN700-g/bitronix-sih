import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/notification_settings.dart';

final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((ref) {
  return NotificationSettingsNotifier();
});

class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings());

  void toggleWaterQuality(bool value) {
    state = state.copyWith(waterQualityAlerts: value);
  }

  void toggleDeviceAlerts(bool value) {
    state = state.copyWith(deviceAlerts: value);
  }

  void toggleFiltrationAlerts(bool value) {
    state = state.copyWith(filtrationAlerts: value);
  }

  void toggleMaintenanceAlerts(bool value) {
    state = state.copyWith(maintenanceAlerts: value);
  }
}

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notifier = ref.read(notificationSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            SwitchListTile(
              title: const Text('Water Quality Alerts'),
              subtitle: const Text('Receive notifications when pH, TDS, or turbidity cross safety boundaries'),
              value: settings.waterQualityAlerts,
              onChanged: notifier.toggleWaterQuality,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('IoT Device Alerts'),
              subtitle: const Text('Notifications when ESP32 or sensors disconnect/reconnect'),
              value: settings.deviceAlerts,
              onChanged: notifier.toggleDeviceAlerts,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Filtration Alerts'),
              subtitle: const Text('Updates when automated filtration completes or requires intervention'),
              value: settings.filtrationAlerts,
              onChanged: notifier.toggleFiltrationAlerts,
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Maintenance Alerts'),
              subtitle: const Text('Reminders for carbon filter replacement & sensor calibration'),
              value: settings.maintenanceAlerts,
              onChanged: notifier.toggleMaintenanceAlerts,
            ),
          ],
        ),
      ),
    );
  }
}
