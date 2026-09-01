import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/sensor_reading.dart';
import '../models/water_quality_result.dart';

class WaterQualityService {
  WaterQualityResult evaluate(SensorReading reading) {
    // 1. Evaluate pH Sub-score & Status
    double phScore = 100.0;
    SensorStatus phStatus = SensorStatus.normal;

    if (reading.ph < AppConstants.phMinOptimal) {
      final diff = AppConstants.phMinOptimal - reading.ph;
      phScore = (100.0 - (diff * 40.0)).clamp(0.0, 100.0);
      phStatus = reading.ph < 6.0 ? SensorStatus.critical : SensorStatus.warning;
    } else if (reading.ph > AppConstants.phMaxOptimal) {
      final diff = reading.ph - AppConstants.phMaxOptimal;
      phScore = (100.0 - (diff * 40.0)).clamp(0.0, 100.0);
      phStatus = reading.ph > 9.0 ? SensorStatus.critical : SensorStatus.warning;
    } else {
      phStatus = SensorStatus.normal;
    }

    // 2. Evaluate TDS Sub-score & Status
    double tdsScore = 100.0;
    SensorStatus tdsStatus = SensorStatus.good;

    if (reading.tds <= AppConstants.tdsMaxOptimal) {
      tdsScore = 100.0;
      tdsStatus = SensorStatus.good;
    } else if (reading.tds <= AppConstants.tdsMaxAcceptable) {
      final diff = reading.tds - AppConstants.tdsMaxOptimal;
      tdsScore = (100.0 - (diff * 0.15)).clamp(50.0, 100.0);
      tdsStatus = SensorStatus.warning;
    } else {
      final diff = reading.tds - AppConstants.tdsMaxAcceptable;
      tdsScore = (70.0 - (diff * 0.08)).clamp(0.0, 70.0);
      tdsStatus = SensorStatus.critical;
    }

    // 3. Evaluate Turbidity Sub-score & Status
    double turbidityScore = 100.0;
    SensorStatus turbidityStatus = SensorStatus.normal;

    if (reading.turbidity <= AppConstants.turbidityMaxOptimal) {
      turbidityScore = 100.0;
      turbidityStatus = SensorStatus.normal;
    } else if (reading.turbidity <= AppConstants.turbidityMaxAcceptable) {
      final diff = reading.turbidity - AppConstants.turbidityMaxOptimal;
      turbidityScore = (100.0 - (diff * 12.0)).clamp(40.0, 100.0);
      turbidityStatus = SensorStatus.warning;
    } else {
      final diff = reading.turbidity - AppConstants.turbidityMaxAcceptable;
      turbidityScore = (52.0 - (diff * 6.0)).clamp(0.0, 52.0);
      turbidityStatus = SensorStatus.critical;
    }

    // 4. Evaluate Temperature Sub-score & Status
    double tempScore = 100.0;
    SensorStatus tempStatus = SensorStatus.normal;

    if (reading.temperature < AppConstants.tempMinOptimal) {
      final diff = AppConstants.tempMinOptimal - reading.temperature;
      tempScore = (100.0 - (diff * 5.0)).clamp(0.0, 100.0);
      tempStatus = diff > 8.0 ? SensorStatus.warning : SensorStatus.normal;
    } else if (reading.temperature > AppConstants.tempMaxOptimal) {
      final diff = reading.temperature - AppConstants.tempMaxOptimal;
      tempScore = (100.0 - (diff * 5.0)).clamp(0.0, 100.0);
      tempStatus = diff > 8.0 ? SensorStatus.warning : SensorStatus.normal;
    } else {
      tempStatus = SensorStatus.normal;
    }

    // Weighted Overall Calculation
    // pH: 30%, TDS: 35%, Turbidity: 25%, Temp: 10%
    final weightedScore = (phScore * 0.30) +
        (tdsScore * 0.35) +
        (turbidityScore * 0.25) +
        (tempScore * 0.10);

    final overallScore = clampDouble(weightedScore, 0.0, 100.0).round();

    // Determine Water Quality Grade
    WaterGrade grade;
    if (overallScore >= 90) {
      grade = WaterGrade.excellent;
    } else if (overallScore >= 75) {
      grade = WaterGrade.good;
    } else if (overallScore >= 50) {
      grade = WaterGrade.moderate;
    } else {
      grade = WaterGrade.poor;
    }

    final hasAlerts = phStatus == SensorStatus.critical ||
        tdsStatus == SensorStatus.critical ||
        turbidityStatus == SensorStatus.critical ||
        phStatus == SensorStatus.warning ||
        tdsStatus == SensorStatus.warning ||
        turbidityStatus == SensorStatus.warning;

    return WaterQualityResult(
      overallScore: overallScore,
      grade: grade,
      phStatus: phStatus,
      tdsStatus: tdsStatus,
      turbidityStatus: turbidityStatus,
      tempStatus: tempStatus,
      hasAlerts: hasAlerts,
    );
  }
}
