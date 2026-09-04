import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/sensor_reading.dart';
import 'sensor_datasource.dart';

/// Firebase Realtime Database Data Source
/// Supports native Firebase Realtime SDK with automatic HTTP REST API fallback
class FirebaseRealtimeDataSource implements SensorDataSource {
  final FirebaseDatabase _database;
  static const String _rtdbBaseUrl = 'https://bitronix-sih-default-rtdb.asia-southeast1.firebasedatabase.app';

  FirebaseRealtimeDataSource({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  @override
  Stream<SensorReading> getLiveSensorStream(String deviceId) {
    late StreamController<SensorReading> controller;
    StreamSubscription? nativeSub;
    Timer? pollTimer;

    controller = StreamController<SensorReading>(
      onListen: () {
        try {
          final ref = _database.ref('devices/$deviceId');
          nativeSub = ref.onValue.listen(
            (event) {
              if (controller.isClosed) return;
              final snapshot = event.snapshot;
              if (!snapshot.exists || snapshot.value == null) {
                _fetchRestReading(deviceId).then((reading) {
                  if (!controller.isClosed) controller.add(reading);
                }).catchError((err) {
                  if (!controller.isClosed) controller.addError(err);
                });
                return;
              }

              final Map<String, dynamic> data;
              if (snapshot.value is Map) {
                final rawMap = Map<String, dynamic>.from(snapshot.value as Map);
                if (rawMap.containsKey('live_reading') && rawMap['live_reading'] is Map) {
                  data = Map<String, dynamic>.from(rawMap['live_reading'] as Map);
                } else {
                  data = rawMap;
                }
              } else {
                data = {};
              }

              controller.add(_parseRealtimeMap(deviceId, data));
            },
            onError: (err) {
              debugPrint('Native RTDB Stream error ($err). Activating HTTP REST Fallback...');
              nativeSub?.cancel();
              nativeSub = null;
              pollTimer = _startHttpFallback(deviceId, controller);
            },
          );
        } catch (e) {
          debugPrint('Native RTDB Init exception ($e). Activating HTTP REST Fallback...');
          pollTimer = _startHttpFallback(deviceId, controller);
        }
      },
      onCancel: () {
        nativeSub?.cancel();
        pollTimer?.cancel();
      },
    );

    return controller.stream;
  }

  Timer _startHttpFallback(
    String deviceId,
    StreamController<SensorReading> controller,
  ) {
    _fetchRestReading(deviceId).then((reading) {
      if (!controller.isClosed) controller.add(reading);
    }).catchError((err) {
      if (!controller.isClosed) controller.addError(err);
    });

    return Timer.periodic(const Duration(seconds: 3), (_) async {
      if (controller.isClosed) return;
      try {
        final reading = await _fetchRestReading(deviceId);
        if (!controller.isClosed) controller.add(reading);
      } catch (e) {
        debugPrint('HTTP REST Fallback fetch error: $e');
      }
    });
  }

  Future<SensorReading> _fetchRestReading(String deviceId) async {
    final url = Uri.parse('$_rtdbBaseUrl/devices/$deviceId.json');
    final response = await http.get(url);

    if (response.statusCode != 200 || response.body == 'null' || response.body.isEmpty) {
      return SensorReading(
        deviceId: deviceId,
        timestamp: DateTime.now(),
        ph: 7.2,
        tds: 0.0,
        turbidity: 0.5,
        salinity: 0.1,
        temperature: 25.0,
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map) {
      return SensorReading(
        deviceId: deviceId,
        timestamp: DateTime.now(),
        ph: 7.2,
        tds: 0.0,
        turbidity: 0.5,
        salinity: 0.1,
        temperature: 25.0,
      );
    }

    final rawMap = Map<String, dynamic>.from(decoded);
    final Map<String, dynamic> data;
    if (rawMap.containsKey('live_reading') && rawMap['live_reading'] is Map) {
      data = Map<String, dynamic>.from(rawMap['live_reading'] as Map);
    } else {
      data = rawMap;
    }

    return _parseRealtimeMap(deviceId, data);
  }

  @override
  Future<SensorReading> fetchLatestReading(String deviceId) async {
    try {
      final snapshot = await _database.ref('devices/$deviceId').get();
      if (snapshot.exists && snapshot.value != null && snapshot.value is Map) {
        final rawMap = Map<String, dynamic>.from(snapshot.value as Map);
        final Map<String, dynamic> data;
        if (rawMap.containsKey('live_reading') && rawMap['live_reading'] is Map) {
          data = Map<String, dynamic>.from(rawMap['live_reading'] as Map);
        } else {
          data = rawMap;
        }
        return _parseRealtimeMap(deviceId, data);
      }
    } catch (_) {}

    return _fetchRestReading(deviceId);
  }

  @override
  Future<List<SensorReading>> fetchHistoricalReadings(String deviceId, {required int days}) async {
    try {
      final snapshot = await _database.ref('devices/$deviceId/history').get();
      if (snapshot.exists && snapshot.value != null && snapshot.value is Map) {
        final List<SensorReading> readings = [];
        final map = Map<String, dynamic>.from(snapshot.value as Map);
        map.forEach((key, value) {
          if (value is Map) {
            readings.add(_parseRealtimeMap(deviceId, Map<String, dynamic>.from(value)));
          }
        });
        readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return readings;
      }
    } catch (_) {}

    return [];
  }

  SensorReading _parseRealtimeMap(String deviceId, Map<String, dynamic> data) {
    DateTime timestamp = DateTime.now();
    if (data['timestamp'] != null) {
      if (data['timestamp'] is int) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
      } else if (data['timestamp'] is String) {
        timestamp = DateTime.tryParse(data['timestamp'] as String) ?? DateTime.now();
      }
    }

    return SensorReading(
      deviceId: deviceId,
      timestamp: timestamp,
      ph: (data['ph'] as num?)?.toDouble() ?? 7.2,
      tds: (data['tds'] as num?)?.toDouble() ?? 0.0,
      turbidity: (data['turbidity'] as num?)?.toDouble() ?? 0.5,
      salinity: (data['salinity'] as num?)?.toDouble() ?? 0.1,
      temperature: (data['temperature'] as num?)?.toDouble() ?? 25.0,
    );
  }
}
