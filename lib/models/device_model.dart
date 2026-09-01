class DeviceModel {
  final String id;
  final String name;
  final bool isOnline;
  final DateTime lastUpdated;
  final bool phSensorActive;
  final bool tdsSensorActive;
  final bool turbiditySensorActive;
  final bool tempSensorActive;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.lastUpdated,
    this.phSensorActive = true,
    this.tdsSensorActive = true,
    this.turbiditySensorActive = true,
    this.tempSensorActive = true,
  });

  DeviceModel copyWith({
    String? id,
    String? name,
    bool? isOnline,
    DateTime? lastUpdated,
    bool? phSensorActive,
    bool? tdsSensorActive,
    bool? turbiditySensorActive,
    bool? tempSensorActive,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isOnline: isOnline ?? this.isOnline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      phSensorActive: phSensorActive ?? this.phSensorActive,
      tdsSensorActive: tdsSensorActive ?? this.tdsSensorActive,
      turbiditySensorActive: turbiditySensorActive ?? this.turbiditySensorActive,
      tempSensorActive: tempSensorActive ?? this.tempSensorActive,
    );
  }
}
