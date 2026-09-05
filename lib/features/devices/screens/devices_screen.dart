import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/sensor_reading.dart';
import '../../../providers/device_provider.dart';
import '../../../providers/sensor_provider.dart';
import '../widgets/device_card.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesListProvider);
    final selectedDeviceId = ref.watch(selectedDeviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Devices & Firebase Calibration'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Pair New Device',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Device pairing wizard initialized. Searching for ESP32 Bluetooth / Wi-Fi...'),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: devicesAsync.when(
          data: (devices) {
            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: devices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final device = devices[index];
                final isSelected = device.id == selectedDeviceId;
                return Column(
                  children: [
                    DeviceCard(
                      device: device,
                      isSelected: isSelected,
                      onTap: () {
                        ref.read(selectedDeviceProvider.notifier).state = device.id;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Active device set to ${device.name}')),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () => _showPushSensorReadingDialog(context, ref, device.id),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                      label: Text('Calibrate & Push Live Metrics for ${device.name}'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(child: Text('Error loading devices: $err')),
        ),
      ),
    );
  }

  void _showPushSensorReadingDialog(BuildContext context, WidgetRef ref, String deviceId) {
    double ph = 7.2;
    double tds = 180.0;
    double turbidity = 0.8;
    double salinity = 0.15;
    double temperature = 24.5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.cloud_upload_rounded, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Push Live Metrics to Firebase',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Syncing live parameters for device: $deviceId',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const Divider(),
                  _buildSlider('pH Level', ph, 0.0, 14.0, (v) => setModalState(() => ph = v), 'pH'),
                  _buildSlider('Turbidity', turbidity, 0.0, 20.0, (v) => setModalState(() => turbidity = v), 'NTU'),
                  _buildSlider('Salinity', salinity, 0.0, 5.0, (v) => setModalState(() => salinity = v), 'ppt'),
                  _buildSlider('Temperature', temperature, 0.0, 50.0, (v) => setModalState(() => temperature = v), '°C'),
                  _buildSlider('TDS Level', tds, 0.0, 1000.0, (v) => setModalState(() => tds = v), 'ppm'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final reading = SensorReading(
                          deviceId: deviceId,
                          timestamp: DateTime.now(),
                          ph: double.parse(ph.toStringAsFixed(1)),
                          tds: double.parse(tds.toStringAsFixed(0)),
                          turbidity: double.parse(turbidity.toStringAsFixed(1)),
                          salinity: double.parse(salinity.toStringAsFixed(2)),
                          temperature: double.parse(temperature.toStringAsFixed(1)),
                        );
                        await ref.read(sensorRepositoryProvider).pushSensorReading(reading);
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '⚡ Synced to Firebase! pH: ${reading.ph}, Turbidity: ${reading.turbidity} NTU, Salinity: ${reading.salinity} ppt, Temp: ${reading.temperature}°C, TDS: ${reading.tds} ppm',
                              ),
                              backgroundColor: AppColors.excellent,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('PUSH TO FIREBASE REALTIME & FIRESTORE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSlider(String label, double val, double min, double max, ValueChanged<double> onChanged, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(
              '${val.toStringAsFixed(1)} $unit',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ],
        ),
        Slider(
          value: val.clamp(min, max),
          min: min,
          max: max,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
