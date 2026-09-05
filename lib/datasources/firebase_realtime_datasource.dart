import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/sensor_reading.dart';
import 'sensor_datasource.dart';

/// Firebase Realtime Database Data Source — Optimized for minimal latency.
///
/// Uses a targeted `.onValue` listener on `devices/{id}/live_reading` (not the
/// entire device node) so only the live sensor fields are transferred. Falls
/// back to HTTP REST polling at 1-second intervals if the native SDK fails.
///
/// Every parsed reading gets `appReceivedTimestamp` set to `DateTime.now()`
/// and `sensorTimestamp` / `firebaseTimestamp` parsed from the RTDB data if
/// the ESP32 firmware provides them.
class FirebaseRealtimeDataSource implements SensorDataSource {
  final FirebaseDatabase _database;
  static const String _rtdbBaseUrl =
      'https://bitronix-sih-default-rtdb.asia-southeast1.firebasedatabase.app';

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
          // Listen specifically to /live_reading — targeted listener for
          // minimal data transfer and instant event-driven updates.
          final ref = _database.ref('devices/$deviceId/live_reading');
          nativeSub = ref.onValue.listen(
            (event) {
              if (controller.isClosed) return;
              final snapshot = event.snapshot;

              if (!snapshot.exists || snapshot.value == null) {
                // No live_reading yet — try fetching from the device root
                _fetchRestReading(deviceId).then((reading) {
                  if (!controller.isClosed) controller.add(reading);
                }).catchError((err) {
                  if (!controller.isClosed) controller.addError(err);
                });
                return;
              }

              if (snapshot.value is Map) {
                final data = Map<String, dynamic>.from(snapshot.value as Map);
                controller.add(_parseRealtimeMap(deviceId, data));
              }
            },
            onError: (err) {
              debugPrint(
                  'Native RTDB Stream error ($err). Activating HTTP REST Fallback...');
              nativeSub?.cancel();
              nativeSub = null;
              pollTimer = _startHttpFallback(deviceId, controller);
            },
          );
        } catch (e) {
          debugPrint(
              'Native RTDB Init exception ($e). Activating HTTP REST Fallback...');
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
    // Immediately fetch once
    _fetchRestReading(deviceId).then((reading) {
      if (!controller.isClosed) controller.add(reading);
    }).catchError((err) {
      if (!controller.isClosed) controller.addError(err);
    });

    // Poll every 1 second as fallback
    return Timer.periodic(const Duration(seconds: 1), (_) async {
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
    final url =
        Uri.parse('$_rtdbBaseUrl/devices/$deviceId/live_reading.json');
    final response = await http.get(url);

    if (response.statusCode != 200 ||
        response.body == 'null' ||
        response.body.isEmpty) {
      return SensorReading(
        deviceId: deviceId,
        timestamp: DateTime.now(),
        ph: 7.2,
        tds: 0.0,
        turbidity: 0.5,
        salinity: 0.1,
        temperature: 25.0,
        appReceivedTimestamp: DateTime.now(),
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
        appReceivedTimestamp: DateTime.now(),
      );
    }

    return _parseRealtimeMap(
        deviceId, Map<String, dynamic>.from(decoded));
  }

  @override
  Future<SensorReading> fetchLatestReading(String deviceId) async {
    try {
      final snapshot =
          await _database.ref('devices/$deviceId/live_reading').get();
      if (snapshot.exists && snapshot.value != null && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return _parseRealtimeMap(deviceId, data);
      }
    } catch (_) {}

    return _fetchRestReading(deviceId);
  }

  @override
  Future<List<SensorReading>> fetchHistoricalReadings(String deviceId,
      {required int days}) async {
    try {
      final snapshot =
          await _database.ref('devices/$deviceId/history').get();
      if (snapshot.exists && snapshot.value != null && snapshot.value is Map) {
        final List<SensorReading> readings = [];
        final map = Map<String, dynamic>.from(snapshot.value as Map);
        map.forEach((key, value) {
          if (value is Map) {
            readings.add(
                _parseRealtimeMap(deviceId, Map<String, dynamic>.from(value)));
          }
        });
        readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return readings;
      }
    } catch (_) {}

    return [];
  }

  /// Parses a raw RTDB map into a [SensorReading] with full latency timestamps.
  SensorReading _parseRealtimeMap(
      String deviceId, Map<String, dynamic> data) {
    final DateTime appReceived = DateTime.now(); // T4

    // Parse primary timestamp (T3 — Firebase server timestamp)
    DateTime timestamp = appReceived;
    DateTime? firebaseTimestamp;
    if (data['timestamp'] != null) {
      if (data['timestamp'] is int) {
        timestamp =
            DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
        firebaseTimestamp = timestamp;
      } else if (data['timestamp'] is String) {
        timestamp =
            DateTime.tryParse(data['timestamp'] as String) ?? appReceived;
        firebaseTimestamp = timestamp;
      }
    }

    // Parse sensor_timestamp (T1 — when ESP32 measured the value)
    DateTime? sensorTimestamp;
    if (data['sensor_timestamp'] != null) {
      if (data['sensor_timestamp'] is int) {
        sensorTimestamp = DateTime.fromMillisecondsSinceEpoch(
            data['sensor_timestamp'] as int);
      } else if (data['sensor_timestamp'] is String) {
        sensorTimestamp =
            DateTime.tryParse(data['sensor_timestamp'] as String);
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
      sensorTimestamp: sensorTimestamp,
      firebaseTimestamp: firebaseTimestamp,
      appReceivedTimestamp: appReceived,
    );
  }

  @override
  Future<void> pushSensorReading(SensorReading reading) async {
    final payload = {
      'ph': reading.ph,
      'tds': reading.tds,
      'turbidity': reading.turbidity,
      'salinity': reading.salinity,
      'temperature': reading.temperature,
      'timestamp': ServerValue.timestamp,
      'sensor_timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await _database
          .ref('devices/${reading.deviceId}/live_reading')
          .set(payload);
      await _database
          .ref('devices/${reading.deviceId}/history')
          .push()
          .set(payload);
    } catch (e) {
      debugPrint('Native RTDB push error ($e). Attempting HTTP REST PUT...');
      final url = Uri.parse(
          '$_rtdbBaseUrl/devices/${reading.deviceId}/live_reading.json');
      await http.put(
        url,
        body: json.encode({
          'ph': reading.ph,
          'tds': reading.tds,
          'turbidity': reading.turbidity,
          'salinity': reading.salinity,
          'temperature': reading.temperature,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sensor_timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    }
  }
}
