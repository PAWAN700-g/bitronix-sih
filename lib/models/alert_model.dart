enum AlertSeverity {
  critical,
  warning,
  info,
}

extension AlertSeverityX on AlertSeverity {
  String get label {
    switch (this) {
      case AlertSeverity.critical:
        return 'Critical';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.info:
        return 'Info';
    }
  }
}

class AlertModel {
  final String id;
  final String deviceId;
  final AlertSeverity severity;
  final String title;
  final String description;
  final String sensorValue;
  final String threshold;
  final DateTime timestamp;
  final bool isRead;

  const AlertModel({
    required this.id,
    required this.deviceId,
    required this.severity,
    required this.title,
    required this.description,
    required this.sensorValue,
    required this.threshold,
    required this.timestamp,
    this.isRead = false,
  });

  AlertModel copyWith({
    String? id,
    String? deviceId,
    AlertSeverity? severity,
    String? title,
    String? description,
    String? sensorValue,
    String? threshold,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AlertModel(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      description: description ?? this.description,
      sensorValue: sensorValue ?? this.sensorValue,
      threshold: threshold ?? this.threshold,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}
