class NotificationSettings {
  final bool waterQualityAlerts;
  final bool deviceAlerts;
  final bool filtrationAlerts;
  final bool maintenanceAlerts;

  const NotificationSettings({
    this.waterQualityAlerts = true,
    this.deviceAlerts = true,
    this.filtrationAlerts = true,
    this.maintenanceAlerts = true,
  });

  NotificationSettings copyWith({
    bool? waterQualityAlerts,
    bool? deviceAlerts,
    bool? filtrationAlerts,
    bool? maintenanceAlerts,
  }) {
    return NotificationSettings(
      waterQualityAlerts: waterQualityAlerts ?? this.waterQualityAlerts,
      deviceAlerts: deviceAlerts ?? this.deviceAlerts,
      filtrationAlerts: filtrationAlerts ?? this.filtrationAlerts,
      maintenanceAlerts: maintenanceAlerts ?? this.maintenanceAlerts,
    );
  }
}
