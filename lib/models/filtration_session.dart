import 'sensor_reading.dart';
import 'water_quality_result.dart';

enum FiltrationState {
  notStarted,
  analyzing,
  inProgress,
  complete,
  maintenanceRequired,
}

extension FiltrationStateX on FiltrationState {
  String get label {
    switch (this) {
      case FiltrationState.notStarted:
        return 'Not Started';
      case FiltrationState.analyzing:
        return 'Analyzing Quality...';
      case FiltrationState.inProgress:
        return 'Filtration in Progress';
      case FiltrationState.complete:
        return 'Filtration Complete';
      case FiltrationState.maintenanceRequired:
        return 'Filter Maintenance Required';
    }
  }

  int get currentStepIndex {
    switch (this) {
      case FiltrationState.notStarted:
        return 0;
      case FiltrationState.analyzing:
        return 1;
      case FiltrationState.inProgress:
        return 2;
      case FiltrationState.complete:
        return 4;
      case FiltrationState.maintenanceRequired:
        return 0;
    }
  }
}

class FiltrationSession {
  final String id;
  final FiltrationState state;
  final double progress; // 0.0 to 1.0
  final SensorReading beforeReading;
  final SensorReading? afterReading;
  final WaterQualityResult beforeResult;
  final WaterQualityResult? afterResult;
  final DateTime startTime;
  final DateTime? endTime;

  const FiltrationSession({
    required this.id,
    required this.state,
    required this.progress,
    required this.beforeReading,
    this.afterReading,
    required this.beforeResult,
    this.afterResult,
    required this.startTime,
    this.endTime,
  });

  double get improvementPercentage {
    if (afterResult == null) return 0.0;
    final beforeScore = beforeResult.overallScore;
    final afterScore = afterResult!.overallScore;
    if (beforeScore == 0) return 100.0;
    final diff = afterScore - beforeScore;
    return (diff / beforeScore) * 100.0;
  }

  FiltrationSession copyWith({
    String? id,
    FiltrationState? state,
    double? progress,
    SensorReading? beforeReading,
    SensorReading? afterReading,
    WaterQualityResult? beforeResult,
    WaterQualityResult? afterResult,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return FiltrationSession(
      id: id ?? this.id,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      beforeReading: beforeReading ?? this.beforeReading,
      afterReading: afterReading ?? this.afterReading,
      beforeResult: beforeResult ?? this.beforeResult,
      afterResult: afterResult ?? this.afterResult,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
