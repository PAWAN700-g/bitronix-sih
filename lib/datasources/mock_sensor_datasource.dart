import 'dart:async';
import 'dart:math';
import '../core/constants/app_constants.dart';
import '../models/sensor_reading.dart';
import 'sensor_datasource.dart';

class MockSensorDataSource implements SensorDataSource {
  final Random _random = Random();
  Timer? _timer;
  final StreamController<SensorReading> _controller = StreamController<SensorReading>.broadcast();

  SensorReading _currentReading = SensorReading(
    deviceId: AppConstants.defaultDeviceId,
    timestamp: DateTime.now(),
    ph: 7.2,
    tds: 180.0,
    turbidity: 1.2,
    salinity: 0.2,
    temperature: 25.4,
  );

  MockSensorDataSource() {
    _startSimulatedStream();
  }

  void _startSimulatedStream() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      // Simulate minor realistic sensor fluctuation
      final phFluctuation = (_random.nextDouble() - 0.5) * 0.08;
      final tdsFluctuation = (_random.nextDouble() - 0.5) * 4.0;
      final turbidityFluctuation = (_random.nextDouble() - 0.5) * 0.1;
      final salinityFluctuation = (_random.nextDouble() - 0.5) * 0.02;
      final tempFluctuation = (_random.nextDouble() - 0.5) * 0.2;

      _currentReading = SensorReading(
        deviceId: _currentReading.deviceId,
        timestamp: DateTime.now(),
        ph: (_currentReading.ph + phFluctuation).clamp(5.5, 9.5),
        tds: (_currentReading.tds + tdsFluctuation).clamp(50.0, 750.0),
        turbidity: (_currentReading.turbidity + turbidityFluctuation).clamp(0.2, 15.0),
        salinity: (_currentReading.salinity + salinityFluctuation).clamp(0.1, 2.5),
        temperature: (_currentReading.temperature + tempFluctuation).clamp(18.0, 38.0),
      );

      _controller.add(_currentReading);
    });
  }

  void emitReading(SensorReading newReading) {
    _currentReading = newReading;
    _controller.add(_currentReading);
  }

  @override
  Stream<SensorReading> getLiveSensorStream(String deviceId) {
    return _controller.stream;
  }

  @override
  Future<SensorReading> fetchLatestReading(String deviceId) async {
    return _currentReading;
  }

  @override
  Future<List<SensorReading>> fetchHistoricalReadings(String deviceId, {required int days}) async {
    final List<SensorReading> history = [];
    final now = DateTime.now();

    final count = days == 1 ? 24 : (days == 7 ? 28 : 30);
    final Duration interval = days == 1
        ? const Duration(hours: 1)
        : (days == 7 ? const Duration(hours: 6) : const Duration(days: 1));

    double basePh = 7.3;
    double baseTds = 210.0;
    double baseTurbidity = 1.4;
    double baseSalinity = 0.25;
    double baseTemp = 24.5;

    for (int i = count; i >= 0; i--) {
      final timestamp = now.subtract(interval * i);
      final phNoise = (sin(i) * 0.3) + ((_random.nextDouble() - 0.5) * 0.1);
      final tdsNoise = (cos(i) * 25.0) + ((_random.nextDouble() - 0.5) * 10.0);
      final turbidityNoise = (sin(i * 0.5) * 0.6) + ((_random.nextDouble() - 0.5) * 0.2);
      final salinityNoise = (sin(i * 0.8) * 0.15) + ((_random.nextDouble() - 0.5) * 0.05);
      final tempNoise = (cos(i * 0.3) * 1.5);

      history.add(SensorReading(
        deviceId: deviceId,
        timestamp: timestamp,
        ph: (basePh + phNoise).clamp(6.2, 8.8),
        tds: (baseTds + tdsNoise).clamp(110.0, 480.0),
        turbidity: (baseTurbidity + turbidityNoise).clamp(0.4, 7.8),
        salinity: (baseSalinity + salinityNoise).clamp(0.1, 1.8),
        temperature: (baseTemp + tempNoise).clamp(20.0, 32.0),
      ));
    }

    return history;
  }

  @override
  Future<void> pushSensorReading(SensorReading reading) async {
    emitReading(reading);
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
