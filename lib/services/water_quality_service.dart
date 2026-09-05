import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../models/sensor_reading.dart';
import '../models/water_quality_result.dart';

/// Water Quality Index (WQI) scoring service.
///
/// Computes a scientifically-grounded Water Quality Screening Score (0–100)
/// using a weighted formula based on three primary parameters:
///   - Turbidity: 40% weight
///   - pH: 35% weight
///   - TDS: 25% weight
///
/// The score is labelled as a "Water Quality Screening Score" because
/// pH, TDS, and turbidity alone cannot detect microbiological or many
/// chemical contaminants (E. coli, arsenic, fluoride, lead, pesticides, etc.).
class WaterQualityService {
  WaterQualityResult evaluate(SensorReading reading) {
    // ─── 1. pH Sub-Score (weight: 0.35) ───
    final double phScore = _calculatePhScore(reading.ph);
    final SensorStatus phStatus = _getPhStatus(reading.ph);

    // ─── 2. Turbidity Sub-Score (weight: 0.40) ───
    final double turbidityScore = _calculateTurbidityScore(reading.turbidity);
    final SensorStatus turbidityStatus = _getTurbidityStatus(reading.turbidity);

    // ─── 3. TDS Sub-Score (weight: 0.25) ───
    final double tdsScore = _calculateTdsScore(reading.tds);
    final SensorStatus tdsStatus = _getTdsStatus(reading.tds);

    // ─── 4. Salinity Status (displayed but not in WQI) ───
    final SensorStatus salinityStatus = _getSalinityStatus(reading.salinity);

    // ─── 5. Temperature Status (displayed but not in WQI) ───
    final SensorStatus tempStatus = _getTempStatus(reading.temperature);

    // ─── 6. Weighted Overall Calculation ───
    final weightedScore =
        (AppConstants.wqiTurbidityWeight * turbidityScore) +
        (AppConstants.wqiPhWeight * phScore) +
        (AppConstants.wqiTdsWeight * tdsScore);

    final overallScore = clampDouble(weightedScore, 0.0, 100.0).round();

    // ─── 7. Grade Classification ───
    final WaterGrade grade;
    if (overallScore >= 90) {
      grade = WaterGrade.excellent;
    } else if (overallScore >= 75) {
      grade = WaterGrade.good;
    } else if (overallScore >= 50) {
      grade = WaterGrade.moderate;
    } else if (overallScore >= 25) {
      grade = WaterGrade.poor;
    } else {
      grade = WaterGrade.veryPoor;
    }

    // ─── 8. Score Explanation ───
    final explanation = _generateExplanation(
      phScore: phScore,
      tdsScore: tdsScore,
      turbidityScore: turbidityScore,
      reading: reading,
    );

    // ─── 9. Alert Detection ───
    final hasAlerts = phStatus == SensorStatus.critical ||
        tdsStatus == SensorStatus.critical ||
        turbidityStatus == SensorStatus.critical ||
        salinityStatus == SensorStatus.critical ||
        phStatus == SensorStatus.warning ||
        tdsStatus == SensorStatus.warning ||
        turbidityStatus == SensorStatus.warning ||
        salinityStatus == SensorStatus.warning;

    return WaterQualityResult(
      overallScore: overallScore,
      grade: grade,
      phStatus: phStatus,
      tdsStatus: tdsStatus,
      turbidityStatus: turbidityStatus,
      salinityStatus: salinityStatus,
      tempStatus: tempStatus,
      hasAlerts: hasAlerts,
      phScore: phScore,
      tdsScore: tdsScore,
      turbidityScore: turbidityScore,
      scoreExplanation: explanation,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // pH SCORING — BIS IS 10500 ideal range: 6.5–8.5
  // ═══════════════════════════════════════════════════════════════════════

  /// pH Score:
  /// - 6.5–8.5 → 100 (ideal BIS range)
  /// - 6.0–6.5 or 8.5–9.0 → linear 70–100
  /// - 4.0–6.0 or 9.0–11.0 → linear 10–70
  /// - <4.0 or >11.0 → 0
  double _calculatePhScore(double ph) {
    if (ph >= 6.5 && ph <= 8.5) {
      return 100.0;
    } else if (ph >= 6.0 && ph < 6.5) {
      // Linear interpolation: 6.0→70, 6.5→100
      return 70.0 + (ph - 6.0) / 0.5 * 30.0;
    } else if (ph > 8.5 && ph <= 9.0) {
      // Linear interpolation: 8.5→100, 9.0→70
      return 100.0 - (ph - 8.5) / 0.5 * 30.0;
    } else if (ph >= 4.0 && ph < 6.0) {
      // Linear interpolation: 4.0→10, 6.0→70
      return 10.0 + (ph - 4.0) / 2.0 * 60.0;
    } else if (ph > 9.0 && ph <= 11.0) {
      // Linear interpolation: 9.0→70, 11.0→10
      return 70.0 - (ph - 9.0) / 2.0 * 60.0;
    } else {
      // Extremely acidic (<4) or alkaline (>11)
      return 0.0;
    }
  }

  SensorStatus _getPhStatus(double ph) {
    if (ph >= 6.5 && ph <= 8.5) return SensorStatus.normal;
    if (ph >= 6.0 && ph <= 9.0) return SensorStatus.warning;
    return SensorStatus.critical;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TURBIDITY SCORING — BIS optimal: ≤1 NTU, acceptable: ≤5 NTU
  // ═══════════════════════════════════════════════════════════════════════

  /// Turbidity Score:
  /// - 0–1 NTU → 100 (excellent)
  /// - 1–5 NTU → linear 100→40 (caution)
  /// - 5–10 NTU → linear 40→10 (poor)
  /// - >10 NTU → approaches 0 (asymptotic decay)
  double _calculateTurbidityScore(double turbidity) {
    if (turbidity <= 1.0) {
      return 100.0;
    } else if (turbidity <= 5.0) {
      // Linear: 1→100, 5→40
      return 100.0 - (turbidity - 1.0) / 4.0 * 60.0;
    } else if (turbidity <= 10.0) {
      // Linear: 5→40, 10→10
      return 40.0 - (turbidity - 5.0) / 5.0 * 30.0;
    } else {
      // Exponential decay towards 0 for very high turbidity
      final excess = turbidity - 10.0;
      return (10.0 * (1.0 / (1.0 + excess * 0.2))).clamp(0.0, 10.0);
    }
  }

  SensorStatus _getTurbidityStatus(double turbidity) {
    if (turbidity <= AppConstants.turbidityMaxOptimal) return SensorStatus.normal;
    if (turbidity <= AppConstants.turbidityMaxAcceptable) return SensorStatus.warning;
    return SensorStatus.critical;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TDS SCORING — BIS desirable: ≤300 ppm, acceptable: ≤500 ppm
  // ═══════════════════════════════════════════════════════════════════════

  /// TDS Score (Indian BIS IS 10500:2012 reference):
  /// - 0–300 ppm → 100 (excellent, BIS desirable)
  /// - 300–500 ppm → linear 100→80 (BIS acceptable limit)
  /// - 500–1000 ppm → linear 80→40
  /// - 1000–2000 ppm → linear 40→10
  /// - >2000 ppm → approaches 0
  double _calculateTdsScore(double tds) {
    if (tds <= AppConstants.tdsDesirable) {
      return 100.0;
    } else if (tds <= AppConstants.tdsAcceptable) {
      // Linear: 300→100, 500→80
      return 100.0 - (tds - AppConstants.tdsDesirable) /
          (AppConstants.tdsAcceptable - AppConstants.tdsDesirable) * 20.0;
    } else if (tds <= AppConstants.tdsPoor) {
      // Linear: 500→80, 1000→40
      return 80.0 - (tds - AppConstants.tdsAcceptable) /
          (AppConstants.tdsPoor - AppConstants.tdsAcceptable) * 40.0;
    } else if (tds <= AppConstants.tdsVeryPoor) {
      // Linear: 1000→40, 2000→10
      return 40.0 - (tds - AppConstants.tdsPoor) /
          (AppConstants.tdsVeryPoor - AppConstants.tdsPoor) * 30.0;
    } else {
      // Exponential decay for extreme values
      final excess = tds - AppConstants.tdsVeryPoor;
      return (10.0 * (1.0 / (1.0 + excess * 0.001))).clamp(0.0, 10.0);
    }
  }

  SensorStatus _getTdsStatus(double tds) {
    if (tds <= AppConstants.tdsMaxOptimal) return SensorStatus.good;
    if (tds <= AppConstants.tdsMaxAcceptable) return SensorStatus.warning;
    return SensorStatus.critical;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SALINITY & TEMPERATURE — displayed but not in WQI score
  // ═══════════════════════════════════════════════════════════════════════

  SensorStatus _getSalinityStatus(double salinity) {
    if (salinity <= AppConstants.salinityMaxOptimal) return SensorStatus.normal;
    if (salinity <= AppConstants.salinityMaxAcceptable) return SensorStatus.warning;
    return SensorStatus.critical;
  }

  SensorStatus _getTempStatus(double temperature) {
    if (temperature >= AppConstants.tempMinOptimal &&
        temperature <= AppConstants.tempMaxOptimal) {
      return SensorStatus.normal;
    }
    final distFromRange = temperature < AppConstants.tempMinOptimal
        ? AppConstants.tempMinOptimal - temperature
        : temperature - AppConstants.tempMaxOptimal;
    return distFromRange > 8.0 ? SensorStatus.warning : SensorStatus.normal;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // EXPLANATION GENERATOR
  // ═══════════════════════════════════════════════════════════════════════

  /// Generates a human-readable explanation of which parameter
  /// is the primary factor reducing the overall score.
  String _generateExplanation({
    required double phScore,
    required double tdsScore,
    required double turbidityScore,
    required SensorReading reading,
  }) {
    // If all scores are excellent, no explanation needed
    if (phScore >= 95 && tdsScore >= 95 && turbidityScore >= 95) {
      return 'All parameters are within optimal ranges.';
    }

    // Find the lowest-scoring parameter
    final scores = {
      'pH': phScore,
      'TDS': tdsScore,
      'Turbidity': turbidityScore,
    };
    final sorted = scores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final worst = sorted.first;

    String valueStr;
    switch (worst.key) {
      case 'pH':
        valueStr = '${reading.ph.toStringAsFixed(1)}';
        break;
      case 'TDS':
        valueStr = '${reading.tds.toStringAsFixed(0)} ppm';
        break;
      case 'Turbidity':
        valueStr = '${reading.turbidity.toStringAsFixed(1)} NTU';
        break;
      default:
        valueStr = '';
    }

    // Check if multiple parameters are significantly reducing the score
    final belowThreshold = sorted.where((e) => e.value < 80).toList();
    if (belowThreshold.length > 1) {
      final names = belowThreshold.map((e) => e.key).join(' & ');
      return '$names are reducing your score. ${worst.key} ($valueStr) is the primary concern.';
    }

    return '${worst.key} ($valueStr) is the primary factor reducing your score.';
  }
}
