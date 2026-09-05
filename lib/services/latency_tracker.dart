import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Represents a single latency measurement sample in the sensor pipeline.
class LatencySample {
  final int? sensorToFirebaseMs;
  final int? firebaseToAppMs;
  final int? endToEndMs;
  final DateTime recordedAt;

  LatencySample({
    this.sensorToFirebaseMs,
    this.firebaseToAppMs,
    this.endToEndMs,
    required this.recordedAt,
  });
}

/// A lightweight singleton service to track end-to-end latency in the sensor pipeline.
class LatencyTracker {
  // Singleton pattern
  static final LatencyTracker _instance = LatencyTracker._internal();
  factory LatencyTracker() => _instance;
  LatencyTracker._internal();

  final Queue<LatencySample> _samples = Queue<LatencySample>();
  final int _maxSamples = 50;

  /// Records one latency sample based on timestamps.
  void addSample(DateTime? sensorTimestamp, DateTime? firebaseTimestamp, DateTime appReceivedTimestamp) {
    int? sensorToFirebaseMs;
    int? firebaseToAppMs;
    int? endToEndMs;

    if (firebaseTimestamp != null) {
      firebaseToAppMs = appReceivedTimestamp.difference(firebaseTimestamp).inMilliseconds;
      if (sensorTimestamp != null) {
        sensorToFirebaseMs = firebaseTimestamp.difference(sensorTimestamp).inMilliseconds;
        endToEndMs = appReceivedTimestamp.difference(sensorTimestamp).inMilliseconds;
      }
    }

    final sample = LatencySample(
      sensorToFirebaseMs: sensorToFirebaseMs,
      firebaseToAppMs: firebaseToAppMs,
      endToEndMs: endToEndMs,
      recordedAt: DateTime.now(),
    );

    _samples.addLast(sample);
    if (_samples.length > _maxSamples) {
      _samples.removeFirst();
    }
  }

  /// Most recent LatencySample
  LatencySample? get latestSample => _samples.isNotEmpty ? _samples.last : null;

  /// Average end-to-end latency in ms of the last 50 samples
  double get averageEndToEndMs {
    final validSamples = _samples.where((s) => s.endToEndMs != null).toList();
    if (validSamples.isEmpty) return 0.0;
    
    final total = validSamples.fold(0, (sum, item) => sum + item.endToEndMs!);
    return total / validSamples.length;
  }

  /// Average Firebase to App latency in ms of the last 50 samples
  double get averageFirebaseToAppMs {
    final validSamples = _samples.where((s) => s.firebaseToAppMs != null).toList();
    if (validSamples.isEmpty) return 0.0;
    
    final total = validSamples.fold(0, (sum, item) => sum + item.firebaseToAppMs!);
    return total / validSamples.length;
  }

  /// Formatted string representing current latency statistics
  String get formattedLatency {
    final e2e = averageEndToEndMs.round();
    final f2a = averageFirebaseToAppMs.round();
    return "E2E: ${e2e}ms | FB→App: ${f2a}ms";
  }
}
