import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/esp32_sensor_datasource.dart';
import '../services/esp32_service.dart';
import '../datasources/firebase_realtime_datasource.dart';
import '../datasources/firebase_sensor_datasource.dart';
import '../datasources/mock_sensor_datasource.dart';
import '../models/sensor_reading.dart';
import '../models/water_quality_result.dart';
import '../repositories/sensor_repository.dart';
import '../services/adaptive_sampling_service.dart';
import '../services/latency_tracker.dart';
import '../services/water_quality_service.dart';
import 'demo_mode_provider.dart';
import 'device_provider.dart';

final mockSensorDataSourceProvider = Provider<MockSensorDataSource>((ref) {
  final ds = MockSensorDataSource();
  ref.onDispose(() => ds.dispose());
  return ds;
});

/// Direct ESP32-S3 Wi-Fi local HTTP data source provider.
final esp32SensorDataSourceProvider = Provider<Esp32SensorDataSource>((ref) {
  final ds = Esp32SensorDataSource();
  ref.onDispose(() => ds.dispose());
  return ds;
});

/// Direct ESP32 Service instance.
final esp32ServiceProvider = Provider<Esp32Service>((ref) {
  final ds = ref.watch(esp32SensorDataSourceProvider);
  return ds.service;
});

/// Stream of connection state from ESP32.
final esp32StateProvider = StreamProvider<Esp32ConnectionState>((ref) {
  final service = ref.watch(esp32ServiceProvider);
  return service.stateStream;
});

/// Stream of connection status boolean from ESP32 (true = connected, false = disconnected).
final esp32ConnectionStatusProvider = StreamProvider<bool>((ref) {
  final ds = ref.watch(esp32SensorDataSourceProvider);
  return ds.connectionStatusStream;
});

final firebaseRealtimeDataSourceProvider = Provider<FirebaseRealtimeDataSource>((ref) {
  return FirebaseRealtimeDataSource();
});

final firebaseSensorDataSourceProvider = Provider<FirebaseSensorDataSource>((ref) {
  return FirebaseSensorDataSource();
});

final waterQualityServiceProvider = Provider<WaterQualityService>((ref) {
  return WaterQualityService();
});

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  final isDemoMode = ref.watch(demoModeProvider);

  // ESP32 is the primary live data source (Mock when demo mode is enabled)
  return SensorRepository(
    dataSource: isDemoMode
        ? ref.watch(mockSensorDataSourceProvider)
        : ref.watch(esp32SensorDataSourceProvider),
    qualityService: ref.watch(waterQualityServiceProvider),
  );
});

// Real-Time Sensor Stream Provider
final liveSensorStreamProvider = StreamProvider.family<SensorReading, String>((ref, deviceId) {
  final repo = ref.watch(sensorRepositoryProvider);
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
  final activeDeviceId = ref.watch(selectedDeviceProvider);
  return repo.getHistoricalReadings(activeDeviceId, days: days);
});

// ═══════════════════════════════════════════════════════════════════════
// LATENCY & ADAPTIVE SAMPLING PROVIDERS
// ═══════════════════════════════════════════════════════════════════════

/// Singleton latency tracker instance.
final latencyTrackerProvider = Provider<LatencyTracker>((ref) {
  return LatencyTracker();
});

/// Singleton adaptive sampling service instance.
final adaptiveSamplingServiceProvider = Provider<AdaptiveSamplingService>((ref) {
  return AdaptiveSamplingService();
});

/// Provides the latest formatted latency string for display.
final latencyDisplayProvider = StateProvider<String>((ref) => '');

/// Provides the latest adaptive sampling state.
final adaptiveSamplingStateProvider = StateProvider<AdaptiveSamplingState?>((ref) => null);
