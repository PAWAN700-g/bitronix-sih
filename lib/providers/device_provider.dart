import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_model.dart';
import '../repositories/device_repository.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository();
});

final devicesListProvider = FutureProvider<List<DeviceModel>>((ref) async {
  final repo = ref.watch(deviceRepositoryProvider);
  return repo.getDevices();
});

final selectedDeviceProvider = StateProvider<String>((ref) => 'SWU-001');
