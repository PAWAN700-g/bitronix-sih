import 'package:flutter_test/flutter_test.dart';
import 'package:sih_smart_water/models/sensor_reading.dart';
import 'package:sih_smart_water/models/water_quality_result.dart';
import 'package:sih_smart_water/services/water_quality_service.dart';

void main() {
  group('WaterQualityService Tests', () {
    late WaterQualityService service;

    setUp(() {
      service = WaterQualityService();
    });

    test('Optimal drinking water reading yields Excellent grade and high score', () {
      final reading = SensorReading(
        deviceId: 'SWU-TEST',
        timestamp: DateTime.now(),
        ph: 7.2,
        tds: 150.0,
        turbidity: 0.5,
        temperature: 24.0,
      );

      final result = service.evaluate(reading);

      expect(result.overallScore, greaterThanOrEqualTo(90));
      expect(result.grade, equals(WaterGrade.excellent));
      expect(result.phStatus, equals(SensorStatus.normal));
      expect(result.tdsStatus, equals(SensorStatus.good));
      expect(result.turbidityStatus, equals(SensorStatus.normal));
      expect(result.tempStatus, equals(SensorStatus.normal));
      expect(result.hasAlerts, isFalse);
    });

    test('High TDS and high turbidity reading yields Poor/Moderate grade with alerts', () {
      final reading = SensorReading(
        deviceId: 'SWU-TEST',
        timestamp: DateTime.now(),
        ph: 5.8,
        tds: 650.0,
        turbidity: 9.2,
        temperature: 26.0,
      );

      final result = service.evaluate(reading);

      expect(result.overallScore, lessThan(60));
      expect(result.phStatus, equals(SensorStatus.critical));
      expect(result.tdsStatus, equals(SensorStatus.critical));
      expect(result.turbidityStatus, equals(SensorStatus.critical));
      expect(result.hasAlerts, isTrue);
    });
  });
}
