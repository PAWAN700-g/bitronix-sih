import 'dart:async';
import '../models/sensor_reading.dart';
import '../services/esp32_service.dart';
import 'sensor_datasource.dart';

/// Direct ESP32-S3 Wi-Fi Access Point data source.
///
/// Delegates all networking, retry, and parsing logic to [Esp32Service],
/// ensuring single-source-of-truth connectivity without duplicated HTTP calls.
/// Connects to http://192.168.4.1 without requiring internet.
class Esp32SensorDataSource implements SensorDataSource {
  final Esp32Service _esp32Service;

  Esp32SensorDataSource({Esp32Service? esp32Service})
      : _esp32Service = esp32Service ?? Esp32Service();

  Esp32Service get service => _esp32Service;

  bool get isConnected => _esp32Service.isConnected;
  String? get lastError => _esp32Service.lastErrorMessage;

  Stream<bool> get connectionStatusStream =>
      _esp32Service.stateStream.map((s) => s == Esp32ConnectionState.connected);

  @override
  Stream<SensorReading> getLiveSensorStream(String deviceId) {
    // If we already have a valid reading, ensure new subscribers receive it
    final stream = _esp32Service.readingStream;
    if (_esp32Service.lastReading != null) {
      return Stream<SensorReading>.multi((controller) {
        controller.add(_esp32Service.lastReading!);
        final sub = stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        controller.onCancel = sub.cancel;
      });
    }
    _esp32Service.checkConnection();
    return stream;
  }

  Future<void> manualRefresh() async {
    await _esp32Service.checkConnection();
  }

  @override
  Future<SensorReading> fetchLatestReading(String deviceId) async {
    final success = await _esp32Service.checkConnection();
    if (success && _esp32Service.lastReading != null) {
      return _esp32Service.lastReading!;
    }
    throw Exception(_esp32Service.lastErrorMessage ?? 'ESP32 at 192.168.4.1 is unreachable');
  }

  @override
  Future<List<SensorReading>> fetchHistoricalReadings(
    String deviceId, {
    required int days,
  }) async {
    final history = _esp32Service.sessionHistory;
    if (history.isNotEmpty) {
      return history;
    }
    if (_esp32Service.lastReading != null) {
      return [_esp32Service.lastReading!];
    }
    return [];
  }

  @override
  Future<void> pushSensorReading(SensorReading reading) async {
    // Local ESP32 AP is read-only
  }

  void dispose() {
    _esp32Service.dispose();
  }
}
