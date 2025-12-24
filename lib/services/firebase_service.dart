import 'package:firebase_database/firebase_database.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  final DatabaseReference _ref =
  FirebaseDatabase.instance.ref('sensor_data');

  Stream<SensorData> get sensorStream =>
      _ref.onValue.map((event) {
        final val = event.snapshot.value;
        if (val == null) return const SensorData();
        return SensorData.fromJson(Map<String, dynamic>.from(val as Map));
      }).handleError((_) => const SensorData());

  /// ➜ tambahkan method yang dipanggil FAB
  Future<void> togglePump(bool current) async {
    await _ref.child('pumpCommand').set(current ? 'stop' : 'start');
  }
}