/// Water quality grade classification based on the overall WQI score.
enum WaterGrade {
  excellent,
  good,
  moderate,
  poor,
  veryPoor,
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
      case WaterGrade.veryPoor:
        return 'Very Poor';
    }
  }
}

/// Status of an individual sensor parameter.
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

/// Holds the computed Water Quality Index result including overall score,
/// individual parameter sub-scores, grade, and a human-readable explanation.
class WaterQualityResult {
  /// Overall Water Quality Screening Score (0–100)
  final int overallScore;

  /// Quality grade classification
  final WaterGrade grade;

  // Individual parameter statuses
  final SensorStatus phStatus;
  final SensorStatus tdsStatus;
  final SensorStatus turbidityStatus;
  final SensorStatus salinityStatus;
  final SensorStatus tempStatus;

  /// Whether any parameter is in warning or critical state
  final bool hasAlerts;

  // Individual sub-scores (0.0–100.0) used in the weighted formula
  final double phScore;
  final double tdsScore;
  final double turbidityScore;

  /// Human-readable explanation of which parameter is mainly reducing the score.
  final String scoreExplanation;

  /// The label for this score type.
  static const String qualityLabel = 'Water Quality Screening Score';

  const WaterQualityResult({
    required this.overallScore,
    required this.grade,
    required this.phStatus,
    required this.tdsStatus,
    required this.turbidityStatus,
    required this.salinityStatus,
    required this.tempStatus,
    required this.hasAlerts,
    this.phScore = 100.0,
    this.tdsScore = 100.0,
    this.turbidityScore = 100.0,
    this.scoreExplanation = '',
  });
}
