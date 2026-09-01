import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/device_provider.dart';
import '../widgets/device_card.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesListProvider);
    final selectedDeviceId = ref.watch(selectedDeviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Devices'),
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
                return DeviceCard(
                  device: device,
                  isSelected: device.id == selectedDeviceId,
                  onTap: () {
                    ref.read(selectedDeviceProvider.notifier).state = device.id;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Active device set to ${device.name}')),
                    );
                  },
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
}
