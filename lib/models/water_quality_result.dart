enum WaterGrade {
  excellent,
  good,
  moderate,
  poor,
}

extension WaterGradeX on WaterGrade {
  String get label {
    switch (this) {
      case WaterGrade.excellent:
        return 'Excellent';
      case WaterGrade.good:
        return 'Good';
      case WaterGrade.moderate:
        return 'Moderate';
      case WaterGrade.poor:
        return 'Poor';
    }
  }
}

enum SensorStatus {
  normal,
  good,
  warning,
  critical,
}

extension SensorStatusX on SensorStatus {
  String get label {
    switch (this) {
      case SensorStatus.normal:
        return 'Normal';
      case SensorStatus.good:
        return 'Good';
      case SensorStatus.warning:
        return 'Warning';
      case SensorStatus.critical:
        return 'Critical';
    }
  }
}

class WaterQualityResult {
  final int overallScore; // 0 - 100
  final WaterGrade grade;
  final SensorStatus phStatus;
  final SensorStatus tdsStatus;
  final SensorStatus turbidityStatus;
  final SensorStatus salinityStatus;
  final SensorStatus tempStatus;
  final bool hasAlerts;

  const WaterQualityResult({
    required this.overallScore,
    required this.grade,
    required this.phStatus,
    required this.tdsStatus,
    required this.turbidityStatus,
    required this.salinityStatus,
    required this.tempStatus,
    required this.hasAlerts,
  });
}
