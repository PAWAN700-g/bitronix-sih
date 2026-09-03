import '../models/alert_model.dart';
import '../models/sensor_reading.dart';
import '../core/constants/app_constants.dart';

class AlertRepository {
  final List<AlertModel> _alerts = [
    AlertModel(
      id: 'alert_001',
      deviceId: AppConstants.defaultDeviceId,
      severity: AlertSeverity.critical,
      title: 'HIGH TURBIDITY DETECTED',
      description: 'Turbidity measured 8.4 NTU, exceeding the 5.0 NTU limit. Filtration advised.',
      sensorValue: '8.4 NTU',
      threshold: '5.0 NTU',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      isRead: false,
    ),
    AlertModel(
      id: 'alert_002',
      deviceId: AppConstants.defaultDeviceId,
      severity: AlertSeverity.warning,
      title: 'ELEVATED TDS LEVEL',
      description: 'TDS reading reached 480 ppm (recommended threshold: 300 ppm).',
      sensorValue: '480.0 ppm',
      threshold: '300.0 ppm',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
    ),
    AlertModel(
      id: 'alert_003',
      deviceId: AppConstants.defaultDeviceId,
      severity: AlertSeverity.info,
      title: 'FILTER MAINTENANCE REMINDER',
      description: 'Pre-filter cartridge has completed 48 out of 50 rated filtration cycles.',
      sensorValue: '48 Cycles',
      threshold: '50 Cycles',
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
      isRead: true,
    ),
  ];

  List<AlertModel> get alerts => List.unmodifiable(_alerts);

  List<AlertModel> generateAlertsFromReading(SensorReading reading) {
    final List<AlertModel> newAlerts = [];

    // Check Turbidity
    if (reading.turbidity > AppConstants.turbidityMaxAcceptable) {
      newAlerts.add(
        AlertModel(
          id: 'auto_${DateTime.now().millisecondsSinceEpoch}_turb',
          deviceId: reading.deviceId,
          severity: AlertSeverity.critical,
          title: 'HIGH TURBIDITY DETECTED',
          description: 'Turbidity reached ${reading.turbidity.toStringAsFixed(1)} NTU (acceptable limit: ${AppConstants.turbidityMaxAcceptable} NTU).',
          sensorValue: '${reading.turbidity.toStringAsFixed(1)} NTU',
          threshold: '${AppConstants.turbidityMaxAcceptable} NTU',
          timestamp: DateTime.now(),
        ),
      );
    }

    // Check TDS
    if (reading.tds > AppConstants.tdsMaxAcceptable) {
      newAlerts.add(
        AlertModel(
          id: 'auto_${DateTime.now().millisecondsSinceEpoch}_tds',
          deviceId: reading.deviceId,
          severity: AlertSeverity.critical,
          title: 'CRITICAL TDS LEVEL',
          description: 'TDS is ${reading.tds.toStringAsFixed(0)} ppm, exceeding the 500 ppm safe drinking limit.',
          sensorValue: '${reading.tds.toStringAsFixed(0)} ppm',
          threshold: '${AppConstants.tdsMaxAcceptable} ppm',
          timestamp: DateTime.now(),
        ),
      );
    } else if (reading.tds > AppConstants.tdsMaxOptimal) {
      newAlerts.add(
        AlertModel(
          id: 'auto_${DateTime.now().millisecondsSinceEpoch}_tds_warn',
          deviceId: reading.deviceId,
          severity: AlertSeverity.warning,
          title: 'ELEVATED TDS LEVEL',
          description: 'TDS is ${reading.tds.toStringAsFixed(0)} ppm, above optimal target of 300 ppm.',
          sensorValue: '${reading.tds.toStringAsFixed(0)} ppm',
          threshold: '${AppConstants.tdsMaxOptimal} ppm',
          timestamp: DateTime.now(),
        ),
      );
    }

    // Check Salinity
    if (reading.salinity > AppConstants.salinityMaxAcceptable) {
      newAlerts.add(
        AlertModel(
          id: 'auto_${DateTime.now().millisecondsSinceEpoch}_sal_crit',
          deviceId: reading.deviceId,
          severity: AlertSeverity.critical,
          title: 'HIGH SALINITY DETECTED',
          description: 'Salinity measured ${reading.salinity.toStringAsFixed(2)} ppt (acceptable limit: ${AppConstants.salinityMaxAcceptable} ppt).',
          sensorValue: '${reading.salinity.toStringAsFixed(2)} ppt',
          threshold: '${AppConstants.salinityMaxAcceptable} ppt',
          timestamp: DateTime.now(),
        ),
      );
    } else if (reading.salinity > AppConstants.salinityMaxOptimal) {
      newAlerts.add(
        AlertModel(
          id: 'auto_${DateTime.now().millisecondsSinceEpoch}_sal_warn',
          deviceId: reading.deviceId,
          severity: AlertSeverity.warning,
          title: 'ELEVATED SALINITY LEVEL',
          description: 'Salinity is ${reading.salinity.toStringAsFixed(2)} ppt, slightly above baseline.',
          sensorValue: '${reading.salinity.toStringAsFixed(2)} ppt',
          threshold: '${AppConstants.salinityMaxOptimal} ppt',
          timestamp: DateTime.now(),
        ),
      );
    }

    // Check pH
    if (reading.ph < 6.0 || reading.ph > 9.0) {
      newAlerts.add(
        AlertModel(
          id: 'auto_${DateTime.now().millisecondsSinceEpoch}_ph_crit',
          deviceId: reading.deviceId,
          severity: AlertSeverity.critical,
          title: reading.ph < 6.0 ? 'LOW pH DETECTED' : 'HIGH pH DETECTED',
          description: 'pH level is ${reading.ph.toStringAsFixed(1)} (safe range is 6.5 – 8.5).',
          sensorValue: reading.ph.toStringAsFixed(1),
          threshold: '6.5 - 8.5',
          timestamp: DateTime.now(),
        ),
      );
    }

    return newAlerts;
  }

  void markAsRead(String alertId) {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isRead: true);
    }
  }

  void removeAlert(String alertId) {
    _alerts.removeWhere((a) => a.id == alertId);
  }

  void clearAll() {
    _alerts.clear();
  }
}
