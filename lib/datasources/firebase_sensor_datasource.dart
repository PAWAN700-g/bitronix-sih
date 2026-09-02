import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sensor_reading.dart';
import 'sensor_datasource.dart';

class FirebaseSensorDataSource implements SensorDataSource {
  final FirebaseFirestore _firestore;

  FirebaseSensorDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<SensorReading> getLiveSensorStream(String deviceId) {
    return _firestore
        .collection('devices')
        .doc(deviceId)
        .collection('readings')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        throw Exception('No sensor readings found in Firestore for device $deviceId');
      }
      final doc = snapshot.docs.first;
      final data = doc.data();
      return _parseFirestoreDoc(deviceId, data);
    });
  }

  @override
  Future<SensorReading> fetchLatestReading(String deviceId) async {
    final query = await _firestore
        .collection('devices')
        .doc(deviceId)
        .collection('readings')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('No sensor readings found in Firestore for device $deviceId');
    }

    return _parseFirestoreDoc(deviceId, query.docs.first.data());
  }

  @override
  Future<List<SensorReading>> fetchHistoricalReadings(String deviceId, {required int days}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final query = await _firestore
        .collection('devices')
        .doc(deviceId)
        .collection('readings')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('timestamp', descending: false)
        .get();

    return query.docs.map((doc) => _parseFirestoreDoc(deviceId, doc.data())).toList();
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
      ph: (data['ph'] as num?)?.toDouble() ?? 7.0,
      tds: (data['tds'] as num?)?.toDouble() ?? 200.0,
      turbidity: (data['turbidity'] as num?)?.toDouble() ?? 1.0,
      salinity: (data['salinity'] as num?)?.toDouble() ?? 0.2,
      temperature: (data['temperature'] as num?)?.toDouble() ?? 25.0,
    );
  }
}
