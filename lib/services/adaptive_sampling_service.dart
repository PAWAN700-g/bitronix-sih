import 'dart:collection';
import 'dart:math';
import '../models/sensor_reading.dart';

/// Represents the state computed by the Adaptive Sampling algorithm.
class AdaptiveSamplingState {
  final bool isStable;
  final int recommendedIntervalMs;
  final List<String> changedParameters;
  final double stabilityScore;
  final bool hasThresholdCrossing;

  AdaptiveSamplingState({
    required this.isStable,
    required this.recommendedIntervalMs,
    required this.changedParameters,
    required this.stabilityScore,
    required this.hasThresholdCrossing,
  });
}

/// App-side adaptive intelligence service to determine if sensor readings are stable.
class AdaptiveSamplingService {
  final Queue<SensorReading> _window = Queue<SensorReading>();
  final int _windowSize = 10;

  /// Adds a reading to the sliding window.
  void addReading(SensorReading reading) {
    _window.addLast(reading);
    if (_window.length > _windowSize) {
      _window.removeFirst();
    }
  }

  /// Computes the coefficient of variation (CV = stdDev / mean) for a list of values.
  double _calculateCV(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean == 0) return 0.0; // Avoid division by zero
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final stdDev = sqrt(variance);
    return (stdDev / mean).abs(); // CV is usually positive
  }

  /// Evaluates stability based on the current window of sensor readings.
  AdaptiveSamplingState evaluate() {
    if (_window.isEmpty) {
      return AdaptiveSamplingState(
        isStable: true,
        recommendedIntervalMs: 2000,
        changedParameters: [],
        stabilityScore: 1.0,
        hasThresholdCrossing: false,
      );
    }

    final phValues = _window.map((r) => r.ph.toDouble()).toList();
    final tdsValues = _window.map((r) => r.tds.toDouble()).toList();
    final turbidityValues = _window.map((r) => r.turbidity.toDouble()).toList();

    final cvPh = _calculateCV(phValues);
    final cvTds = _calculateCV(tdsValues);
    final cvTurbidity = _calculateCV(turbidityValues);

    List<String> changedParams = [];
    if (cvPh > 0.05) changedParams.add('pH');
    if (cvTds > 0.05) changedParams.add('TDS');
    if (cvTurbidity > 0.05) changedParams.add('Turbidity');

    bool isStable = changedParams.isEmpty;

    bool hasThresholdCrossing = false;
    for (var r in _window) {
      if (r.ph < 6.5 || r.ph > 8.5) hasThresholdCrossing = true;
      if (r.turbidity > 5.0) hasThresholdCrossing = true;
      if (r.tds > 500.0) hasThresholdCrossing = true;
      if (hasThresholdCrossing) break;
    }

    double maxCv = [cvPh, cvTds, cvTurbidity].reduce(max);
    double score = (1.0 - maxCv).clamp(0.0, 1.0);

    return AdaptiveSamplingState(
      isStable: isStable,
      recommendedIntervalMs: isStable ? 2000 : 500,
      changedParameters: changedParams,
      stabilityScore: score,
      hasThresholdCrossing: hasThresholdCrossing,
    );
  }

  /// Clears the sliding window.
  void reset() {
    _window.clear();
  }
}
