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
            if (docSnap.exists && docSnap.data() != null) {
              final reading = _parseFirestoreDoc(deviceId, docSnap.data()!);
              if (!controller.isClosed) controller.add(reading);
            }
          },
          onError: (err) {
            debugPrint('Firestore document stream notice ($err). Falling back to subcollection...');
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
            if (snapshot.docs.isNotEmpty) {
              final doc = snapshot.docs.first;
              final reading = _parseFirestoreDoc(deviceId, doc.data());
              if (!controller.isClosed) controller.add(reading);
            }
          },
          onError: (err) {
            debugPrint('Firestore subcollection stream notice ($err).');
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
    DateTime timestamp = DateTime.now();
    if (data['timestamp'] is Timestamp) {
      timestamp = (data['timestamp'] as Timestamp).toDate();
    } else if (data['timestamp'] is String) {
      timestamp = DateTime.tryParse(data['timestamp'] as String) ?? DateTime.now();
    }

    return SensorReading(
      deviceId: deviceId,
      timestamp: timestamp,
      ph: (data['ph'] as num?)?.toDouble() ?? 7.2,
      tds: (data['tds'] as num?)?.toDouble() ?? 180.0,
      turbidity: (data['turbidity'] as num?)?.toDouble() ?? 0.8,
      salinity: (data['salinity'] as num?)?.toDouble() ?? 0.15,
      temperature: (data['temperature'] as num?)?.toDouble() ?? 24.5,
    );
  }
}
