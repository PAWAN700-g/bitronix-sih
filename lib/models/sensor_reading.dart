class SensorReading {
  final String deviceId;
  final DateTime timestamp;
  final double ph;
  final double tds;
  final double turbidity;
  final double temperature;

  const SensorReading({
    required this.deviceId,
    required this.timestamp,
    required this.ph,
    required this.tds,
    required this.turbidity,
    required this.temperature,
  });

  SensorReading copyWith({
    String? deviceId,
    DateTime? timestamp,
    double? ph,
    double? tds,
    double? turbidity,
    double? temperature,
  }) {
    return SensorReading(
      deviceId: deviceId ?? this.deviceId,
      timestamp: timestamp ?? this.timestamp,
      ph: ph ?? this.ph,
      tds: tds ?? this.tds,
      turbidity: turbidity ?? this.turbidity,
      temperature: temperature ?? this.temperature,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'timestamp': timestamp.toIso8601String(),
      'ph': ph,
      'tds': tds,
      'turbidity': turbidity,
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
      temperature: (json['temperature'] as num).toDouble(),
    );
  }
}
