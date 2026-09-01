import 'package:flutter_test/flutter_test.dart';
import 'package:sih_smart_water/models/alert_model.dart';
import 'package:sih_smart_water/models/sensor_reading.dart';
import 'package:sih_smart_water/repositories/alert_repository.dart';

void main() {
  group('AlertRepository Tests', () {
    late AlertRepository repository;

    setUp(() {
      repository = AlertRepository();
    });

    test('Generates critical alert when turbidity exceeds safety limit', () {
      final reading = SensorReading(
        deviceId: 'SWU-TEST',
        timestamp: DateTime.now(),
        ph: 7.2,
        tds: 180.0,
        turbidity: 8.5, // limit is 5.0
        temperature: 25.0,
      );

      final alerts = repository.generateAlertsFromReading(reading);

      expect(alerts.isNotEmpty, isTrue);
      expect(alerts.any((a) => a.title.contains('HIGH TURBIDITY')), isTrue);
      expect(alerts.firstWhere((a) => a.title.contains('HIGH TURBIDITY')).severity, equals(AlertSeverity.critical));
    });

    test('Generates critical alert when TDS exceeds 500 ppm', () {
      final reading = SensorReading(
        deviceId: 'SWU-TEST',
        timestamp: DateTime.now(),
        ph: 7.2,
        tds: 580.0, // limit is 500
        turbidity: 0.8,
        temperature: 25.0,
      );

      final alerts = repository.generateAlertsFromReading(reading);

      expect(alerts.any((a) => a.title.contains('CRITICAL TDS')), isTrue);
    });
  });
}
