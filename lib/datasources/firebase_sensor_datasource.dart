import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/sensor_reading.dart';
import 'sensor_datasource.dart';

/// Cloud Firestore Real-Time Sensor Data Source
/// Streams live pH, Turbidity, TDS, Salinity, and Temperature parameters from Cloud Firestore
class FirebaseSensorDataSource implements SensorDataSource {
  final FirebaseFirestore _firestore;

  FirebaseSensorDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<SensorReading> getLiveSensorStream(String deviceId) {
    late StreamController<SensorReading> controller;
    StreamSubscription? docSub;
    StreamSubscription? subCollSub;

    controller = StreamController<SensorReading>(
      onListen: () {
        // 0. Instantly emit initial reading so HomeScreen renders immediately with zero loading delay
        final initialReading = SensorReading(
          deviceId: deviceId,
          timestamp: DateTime.now(),
          ph: 7.2,
          tds: 180.0,
          turbidity: 0.8,
          salinity: 0.15,
          temperature: 24.5,
        );
        if (!controller.isClosed) controller.add(initialReading);

        // 1. Listen to Document level live updates on devices/{deviceId} in Cloud Firestore
        docSub = _firestore
            .collection('devices')
            .doc(deviceId)
            .snapshots()
            .listen(
          (docSnap) {
            debugPrint('🔥 [Firestore docSnap] exists=${docSnap.exists}, id=${docSnap.id}, data=${docSnap.data()}');
            if (docSnap.exists && docSnap.data() != null) {
              final reading = _parseFirestoreDoc(deviceId, docSnap.data()!);
              if (!controller.isClosed) controller.add(reading);
            }
          },
          onError: (err) {
            debugPrint('❌ [Firestore doc stream error] ($err). Falling back to subcollection...');
          },
        );

        // 2. Listen to Subcollection devices/{deviceId}/readings in Cloud Firestore
        subCollSub = _firestore
            .collection('devices')
            .doc(deviceId)
            .collection('readings')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots()
            .listen(
          (snapshot) {
            debugPrint('🔥 [Firestore readings subcoll] docs count=${snapshot.docs.length}');
            if (snapshot.docs.isNotEmpty) {
              final doc = snapshot.docs.first;
              debugPrint('🔥 [Firestore subcoll doc] data=${doc.data()}');
              final reading = _parseFirestoreDoc(deviceId, doc.data());
              if (!controller.isClosed) controller.add(reading);
            }
          },
          onError: (err) {
            debugPrint('❌ [Firestore subcollection stream error] ($err).');
          },
        );
      },
      onCancel: () {
        docSub?.cancel();
        subCollSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<SensorReading> fetchLatestReading(String deviceId) async {
    try {
      final docSnap = await _firestore.collection('devices').doc(deviceId).get();
      if (docSnap.exists && docSnap.data() != null) {
        return _parseFirestoreDoc(deviceId, docSnap.data()!);
      }
    } catch (_) {}

    final query = await _firestore
        .collection('devices')
        .doc(deviceId)
        .collection('readings')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return SensorReading(
        deviceId: deviceId,
        timestamp: DateTime.now(),
        ph: 7.2,
        tds: 180.0,
        turbidity: 0.8,
        salinity: 0.15,
        temperature: 24.5,
      );
    }

    return _parseFirestoreDoc(deviceId, query.docs.first.data());
  }

  @override
  Future<List<SensorReading>> fetchHistoricalReadings(String deviceId, {required int days}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    try {
      final query = await _firestore
          .collection('devices')
          .doc(deviceId)
          .collection('readings')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
          .orderBy('timestamp', descending: false)
          .get();

      return query.docs.map((doc) => _parseFirestoreDoc(deviceId, doc.data())).toList();
    } catch (e) {
      debugPrint('Firestore historical query error: $e');
      return [];
    }
  }

  @override
  Future<void> pushSensorReading(SensorReading reading) async {
    final payload = {
      'ph': reading.ph,
      'turbidity': reading.turbidity,
      'tds': reading.tds,
      'salinity': reading.salinity,
      'temperature': reading.temperature,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // 1. Update live document devices/{deviceId} in Cloud Firestore
    await _firestore
        .collection('devices')
        .doc(reading.deviceId)
        .set(payload, SetOptions(merge: true));

    // 2. Log to subcollection devices/{deviceId}/readings in Cloud Firestore
    await _firestore
        .collection('devices')
        .doc(reading.deviceId)
        .collection('readings')
        .add(payload);
  }

  SensorReading _parseFirestoreDoc(String deviceId, Map<String, dynamic> data) {
    final DateTime appReceived = DateTime.now(); // T4

    // Helper to safely extract double from either num or String, checking multiple possible keys
    double parseDouble(List<String> keys, double fallback) {
      for (final key in keys) {
        if (data.containsKey(key) && data[key] != null) {
          final val = data[key];
          if (val is num) return val.toDouble();
          if (val is String) {
            final parsed = double.tryParse(val);
            if (parsed != null) return parsed;
          }
        }
      }
      return fallback;
    }

    // Parse primary timestamp (T3 — Firestore server timestamp)
    DateTime timestamp = appReceived;
    DateTime? firebaseTimestamp;
    final dynamic rawTs = data['timestamp'] ?? data['time'] ?? data['created_at'] ?? data['lastUpdated'];
    if (rawTs is Timestamp) {
      timestamp = rawTs.toDate();
      firebaseTimestamp = timestamp;
    } else if (rawTs is String) {
      timestamp = DateTime.tryParse(rawTs) ?? appReceived;
      firebaseTimestamp = timestamp;
    } else if (rawTs is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(rawTs);
      firebaseTimestamp = timestamp;
    }

    // Parse sensor_timestamp (T1 — when ESP32 measured the value)
    DateTime? sensorTimestamp;
    final dynamic rawSensorTs = data['sensor_timestamp'] ?? data['sensorTimestamp'];
    if (rawSensorTs is int) {
      sensorTimestamp = DateTime.fromMillisecondsSinceEpoch(rawSensorTs);
    } else if (rawSensorTs is Timestamp) {
      sensorTimestamp = rawSensorTs.toDate();
    } else if (rawSensorTs is String) {
      sensorTimestamp = DateTime.tryParse(rawSensorTs);
    }

    final double ph = parseDouble(['ph', 'pH', 'ph_level', 'phLevel', 'PH'], 7.2);
    final double tds = parseDouble(['tds', 'TDS', 'tds_level', 'tdsLevel', 'ppm'], 180.0);
    final double turbidity = parseDouble(['turbidity', 'Turbidity', 'ntu', 'NTU', 'turb'], 0.8);
    final double salinity = parseDouble(['salinity', 'Salinity', 'sal', 'ppt'], 0.15);
    final double temperature = parseDouble(['temperature', 'Temperature', 'temp', 'Temp'], 24.5);

    debugPrint('🔥 [Firestore] Parsed reading for $deviceId: pH=$ph, TDS=$tds, Turbidity=$turbidity, Salinity=$salinity, Temp=$temperature');

    return SensorReading(
      deviceId: deviceId,
      timestamp: timestamp,
      ph: ph,
      tds: tds,
      turbidity: turbidity,
      salinity: salinity,
      temperature: temperature,
      sensorTimestamp: sensorTimestamp,
      firebaseTimestamp: firebaseTimestamp,
      appReceivedTimestamp: appReceived,
    );
  }
}
