import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../models/filtration_session.dart';
import '../models/sensor_reading.dart';
import '../services/water_quality_service.dart';
import 'sensor_provider.dart';

final filtrationProvider = StateNotifierProvider<FiltrationNotifier, FiltrationSession>((ref) {
  final qualityService = ref.watch(waterQualityServiceProvider);

  // Default initial session state for demo
  final initialBeforeReading = SensorReading(
    deviceId: AppConstants.defaultDeviceId,
    timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
    ph: 6.4,
    tds: 450.0,
    turbidity: 8.2,
    temperature: 27.0,
  );

  final initialAfterReading = SensorReading(
    deviceId: AppConstants.defaultDeviceId,
    timestamp: DateTime.now(),
    ph: 7.1,
    tds: 180.0,
    turbidity: 1.1,
    temperature: 25.0,
  );

  return FiltrationNotifier(
    ref,
    qualityService: qualityService,
    initialBeforeReading: initialBeforeReading,
    initialAfterReading: initialAfterReading,
  );
});

class FiltrationNotifier extends StateNotifier<FiltrationSession> {
  final Ref _ref;
  final WaterQualityService _qualityService;
  Timer? _simulationTimer;

  FiltrationNotifier(
    this._ref, {
    required WaterQualityService qualityService,
    required SensorReading initialBeforeReading,
    required SensorReading initialAfterReading,
  })  : _qualityService = qualityService,
        super(
          FiltrationSession(
            id: 'filt_session_001',
            state: FiltrationState.complete,
            progress: 1.0,
            beforeReading: initialBeforeReading,
            afterReading: initialAfterReading,
            beforeResult: qualityService.evaluate(initialBeforeReading),
            afterResult: qualityService.evaluate(initialAfterReading),
            startTime: DateTime.now().subtract(const Duration(minutes: 15)),
            endTime: DateTime.now(),
          ),
        );

  void startFiltrationSimulation() {
    _simulationTimer?.cancel();

    final startTime = DateTime.now();

    // Raw input water reading before filtration
    final dirtyReading = SensorReading(
      deviceId: AppConstants.defaultDeviceId,
      timestamp: startTime,
      ph: 6.4,
      tds: 480.0,
      turbidity: 8.5,
      temperature: 27.2,
    );

    state = FiltrationSession(
      id: 'filt_${startTime.millisecondsSinceEpoch}',
      state: FiltrationState.analyzing,
      progress: 0.1,
      beforeReading: dirtyReading,
      afterReading: null,
      beforeResult: _qualityService.evaluate(dirtyReading),
      afterResult: null,
      startTime: startTime,
    );

    // Emit dirty reading to mock source
    _ref.read(mockSensorDataSourceProvider).emitReading(dirtyReading);

    int step = 0;
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      step++;
      if (step == 1) {
        state = state.copyWith(
          state: FiltrationState.inProgress,
          progress: 0.3,
        );
        // Step 1: Turbidity drops
        _ref.read(mockSensorDataSourceProvider).emitReading(
          dirtyReading.copyWith(turbidity: 4.8, tds: 380.0),
        );
      } else if (step == 2) {
        state = state.copyWith(
          progress: 0.6,
        );
        // Step 2: TDS drops further
        _ref.read(mockSensorDataSourceProvider).emitReading(
          dirtyReading.copyWith(turbidity: 2.2, tds: 260.0, ph: 6.8),
        );
      } else if (step == 3) {
        state = state.copyWith(
          progress: 0.85,
        );
        // Step 3: Nearly filtered
        _ref.read(mockSensorDataSourceProvider).emitReading(
          dirtyReading.copyWith(turbidity: 1.4, tds: 200.0, ph: 7.0, temperature: 25.6),
        );
      } else if (step >= 4) {
        timer.cancel();

        final cleanReading = SensorReading(
          deviceId: AppConstants.defaultDeviceId,
          timestamp: DateTime.now(),
          ph: 7.2,
          tds: 175.0,
          turbidity: 1.1,
          temperature: 25.0,
        );

        _ref.read(mockSensorDataSourceProvider).emitReading(cleanReading);

        state = state.copyWith(
          state: FiltrationState.complete,
          progress: 1.0,
          afterReading: cleanReading,
          afterResult: _qualityService.evaluate(cleanReading),
          endTime: DateTime.now(),
        );
      }
    });
  }

  void resetFiltration() {
    _simulationTimer?.cancel();
    final reading = SensorReading(
      deviceId: AppConstants.defaultDeviceId,
      timestamp: DateTime.now(),
      ph: 7.2,
      tds: 180.0,
      turbidity: 1.2,
      temperature: 25.4,
    );
    state = FiltrationSession(
      id: 'filt_reset',
      state: FiltrationState.notStarted,
      progress: 0.0,
      beforeReading: reading,
      afterReading: null,
      beforeResult: _qualityService.evaluate(reading),
      afterResult: null,
      startTime: DateTime.now(),
    );
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}
