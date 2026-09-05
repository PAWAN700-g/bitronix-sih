import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
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

final mockSensorDataSourceProvider = Provider<MockSensorDataSource>((ref) {
  final ds = MockSensorDataSource();
  ref.onDispose(() => ds.dispose());
  return ds;
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

  return SensorRepository(
    dataSource: isDemoMode
        ? ref.watch(mockSensorDataSourceProvider)
        : ref.watch(firebaseRealtimeDataSourceProvider),
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
  return repo.getHistoricalReadings(AppConstants.defaultDeviceId, days: days);
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
