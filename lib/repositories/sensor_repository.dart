import '../datasources/sensor_datasource.dart';
import '../models/sensor_reading.dart';
import '../models/water_quality_result.dart';
import '../services/water_quality_service.dart';

class SensorRepository {
  final SensorDataSource _dataSource;
  final WaterQualityService _qualityService;

  SensorRepository({
    required this._dataSource,
    required WaterQualityService qualityService,
  })  : _qualityService = qualityService;

  Stream<SensorReading> getLiveSensorStream(String deviceId) {
    return _dataSource.getLiveSensorStream(deviceId);
  }

  Future<SensorReading> getLatestReading(String deviceId) {
    return _dataSource.fetchLatestReading(deviceId);
  }

  Future<List<SensorReading>> getHistoricalReadings(String deviceId, {required int days}) {
    return _dataSource.fetchHistoricalReadings(deviceId, days: days);
  }

  Future<void> pushSensorReading(SensorReading reading) {
    return _dataSource.pushSensorReading(reading);
  }

  WaterQualityResult evaluateQuality(SensorReading reading) {
    return _qualityService.evaluate(reading);
  }
}
