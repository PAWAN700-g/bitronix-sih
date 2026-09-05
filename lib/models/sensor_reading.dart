/// Represents a single sensor measurement from an ESP32 device.
///
/// Contains the 5 water quality parameters (pH, TDS, turbidity, salinity,
/// temperature) along with timestamps for latency tracking.
class SensorReading {
  final String deviceId;
  final DateTime timestamp;
  final double ph;
  final double tds;
  final double turbidity;
  final double salinity;
  final double temperature;

  /// T1 — When the ESP32 physically measured the sensor value (epoch ms).
  /// Null if ESP32 firmware hasn't been updated to send this field.
  final DateTime? sensorTimestamp;

  /// T3 — Firebase server timestamp when the write was acknowledged.
  /// Parsed from RTDB ServerValue.timestamp.
  final DateTime? firebaseTimestamp;

  /// T4 — When the Flutter app received and parsed this reading.
  /// Auto-set when the reading is created from a Firebase snapshot.
  final DateTime? appReceivedTimestamp;

  const SensorReading({
    required this.deviceId,
    required this.timestamp,
    required this.ph,
    required this.tds,
    required this.turbidity,
    this.salinity = 0.2,
    required this.temperature,
    this.sensorTimestamp,
    this.firebaseTimestamp,
    this.appReceivedTimestamp,
  });

  SensorReading copyWith({
    String? deviceId,
    DateTime? timestamp,
    double? ph,
    double? tds,
    double? turbidity,
    double? salinity,
    double? temperature,
    DateTime? sensorTimestamp,
    DateTime? firebaseTimestamp,
    DateTime? appReceivedTimestamp,
  }) {
    return SensorReading(
      deviceId: deviceId ?? this.deviceId,
      timestamp: timestamp ?? this.timestamp,
      ph: ph ?? this.ph,
      tds: tds ?? this.tds,
      turbidity: turbidity ?? this.turbidity,
      salinity: salinity ?? this.salinity,
      temperature: temperature ?? this.temperature,
      sensorTimestamp: sensorTimestamp ?? this.sensorTimestamp,
      firebaseTimestamp: firebaseTimestamp ?? this.firebaseTimestamp,
      appReceivedTimestamp: appReceivedTimestamp ?? this.appReceivedTimestamp,
    );
  }

  /// End-to-end latency in milliseconds (T4 - T1).
  /// Returns null if either timestamp is unavailable.
  int? get endToEndLatencyMs {
    if (sensorTimestamp != null && appReceivedTimestamp != null) {
      return appReceivedTimestamp!.difference(sensorTimestamp!).inMilliseconds;
    }
    return null;
  }

  /// Firebase-to-App latency in milliseconds (T4 - T3).
  /// Returns null if either timestamp is unavailable.
  int? get firebaseToAppLatencyMs {
    if (firebaseTimestamp != null && appReceivedTimestamp != null) {
      return appReceivedTimestamp!.difference(firebaseTimestamp!).inMilliseconds;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'timestamp': timestamp.toIso8601String(),
      'ph': ph,
      'tds': tds,
      'turbidity': turbidity,
      'salinity': salinity,
      'temperature': temperature,
    };
  }

  factory SensorReading.fromJson(Map<String, dynamic> json) {
    return SensorReading(
      deviceId: json['deviceId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      ph: (json['ph'] as num).toDouble(),
      tds: (json['tds'] as num).toDouble(),
      turbidity: (json['turbidity'] as num).toDouble(),
      salinity: (json['salinity'] as num?)?.toDouble() ?? 0.2,
      temperature: (json['temperature'] as num).toDouble(),
    );
  }
}
