import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../datasources/mock_sensor_datasource.dart';
import '../models/sensor_reading.dart';
import '../models/water_quality_result.dart';
import '../repositories/sensor_repository.dart';
import '../services/water_quality_service.dart';
import 'demo_mode_provider.dart';

final mockSensorDataSourceProvider = Provider<MockSensorDataSource>((ref) {
  final ds = MockSensorDataSource();
  ref.onDispose(() => ds.dispose());
  return ds;
});

final waterQualityServiceProvider = Provider<WaterQualityService>((ref) {
  return WaterQualityService();
});

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  return SensorRepository(
    dataSource: ref.watch(mockSensorDataSourceProvider),
    qualityService: ref.watch(waterQualityServiceProvider),
  );
});

// Real-Time Sensor Stream Provider
final liveSensorStreamProvider = StreamProvider.family<SensorReading, String>((ref, deviceId) {
  final isDemoMode = ref.watch(demoModeProvider);
  final repo = ref.watch(sensorRepositoryProvider);

  if (!isDemoMode) {
    // Returns last known reading when demo mode is OFF (simulate static hardware state)
    return Stream.fromFuture(repo.getLatestReading(deviceId));
  }

  return repo.getLiveSensorStream(deviceId);
});

// Computed Water Quality Result Provider
final currentWaterQualityResultProvider = Provider.family<WaterQualityResult, SensorReading>((ref, reading) {
  final repo = ref.watch(sensorRepositoryProvider);
  return repo.evaluateQuality(reading);
});

// Selected Time Filter for Analytics
final selectedTimeFilterProvider = StateProvider<int>((ref) => 1); // 1 = Today, 7 = 7 Days, 30 = 30 Days

// Historical Sensor Readings Provider
final historicalSensorReadingsProvider = FutureProvider.family<List<SensorReading>, int>((ref, days) async {
  final repo = ref.watch(sensorRepositoryProvider);
  return repo.getHistoricalReadings(AppConstants.defaultDeviceId, days: days);
});
