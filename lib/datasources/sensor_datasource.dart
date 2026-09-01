import '../models/sensor_reading.dart';

abstract class SensorDataSource {
  Stream<SensorReading> getLiveSensorStream(String deviceId);
  Future<SensorReading> fetchLatestReading(String deviceId);
  Future<List<SensorReading>> fetchHistoricalReadings(String deviceId, {required int days});
}
