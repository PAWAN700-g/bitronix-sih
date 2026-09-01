import 'package:flutter_test/flutter_test.dart';
import 'package:sih_smart_water/models/filtration_session.dart';
import 'package:sih_smart_water/models/sensor_reading.dart';
import 'package:sih_smart_water/services/water_quality_service.dart';

void main() {
  group('FiltrationSession & Improvement Tests', () {
    final qualityService = WaterQualityService();

    test('Calculates positive improvement percentage dynamically', () {
      final beforeReading = SensorReading(
        deviceId: 'SWU-TEST',
        timestamp: DateTime.now(),
        ph: 6.4,
        tds: 480.0,
        turbidity: 8.5,
        temperature: 27.0,
      );

      final afterReading = SensorReading(
        deviceId: 'SWU-TEST',
        timestamp: DateTime.now(),
        ph: 7.2,
        tds: 170.0,
        turbidity: 0.8,
        temperature: 24.5,
      );

      final beforeResult = qualityService.evaluate(beforeReading);
      final afterResult = qualityService.evaluate(afterReading);

      final session = FiltrationSession(
        id: 'test_filt',
        state: FiltrationState.complete,
        progress: 1.0,
        beforeReading: beforeReading,
        afterReading: afterReading,
        beforeResult: beforeResult,
        afterResult: afterResult,
        startTime: DateTime.now(),
      );

      expect(afterResult.overallScore, greaterThan(beforeResult.overallScore));
      expect(session.improvementPercentage, greaterThan(0));
    });

    test('FiltrationState enum maps to correct step indices', () {
      expect(FiltrationState.notStarted.currentStepIndex, equals(0));
      expect(FiltrationState.analyzing.currentStepIndex, equals(1));
      expect(FiltrationState.inProgress.currentStepIndex, equals(2));
      expect(FiltrationState.complete.currentStepIndex, equals(4));
    });
  });
}
