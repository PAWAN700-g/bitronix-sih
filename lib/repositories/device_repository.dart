import '../models/device_model.dart';
import '../core/constants/app_constants.dart';

class DeviceRepository {
  final List<DeviceModel> _devices = [
    DeviceModel(
      id: 'ESP001',
      name: 'ESP001 Smart Water Unit',
      isOnline: true,
      lastUpdated: DateTime.now(),
      phSensorActive: true,
      tdsSensorActive: true,
      turbiditySensorActive: true,
      tempSensorActive: true,
      salinitySensorActive: true,
    ),
    DeviceModel(
      id: 'SWU-002',
      name: 'Smart Water Unit #02 (Lab Test)',
      isOnline: false,
      lastUpdated: DateTime.now().subtract(const Duration(hours: 4)),
      phSensorActive: true,
      tdsSensorActive: true,
      turbiditySensorActive: false,
      tempSensorActive: true,
    ),
  ];

  Future<List<DeviceModel>> getDevices() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_devices);
  }

  Future<DeviceModel?> getDeviceById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _devices.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
