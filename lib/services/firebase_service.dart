// lib/services/firebase_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:iot_dispenser/models/sensor_data.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  // Auth Methods
  Future<User?> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sensor Data Stream
  Stream<SensorData> get sensorStream {
    return _dbRef.child('sensors').onValue.map((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        return SensorData.fromJson(data);
      }
      throw Exception('No sensor data available');
    });
  }

  // Manual Pump Control
  Future<void> togglePump(bool currentlyFilling) async {
    try {
      await _dbRef.child('control').update({
        'pumpManual': !currentlyFilling,
        'lastCommand': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to control pump: ${e.toString()}');
    }
  }

  // Get pump control status
  Stream<bool> get pumpControlStream {
    return _dbRef.child('control/pumpManual').onValue.map((event) {
      if (event.snapshot.value != null) {
        return event.snapshot.value as bool;
      }
      return false;
    });
  }

  // Get latest sensor data (one-time)
  Future<SensorData?> getSensorData() async {
    try {
      final snapshot = await _dbRef.child('sensors').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return SensorData.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get sensor data: ${e.toString()}');
    }
  }

  // Reset pump control
  Future<void> resetPumpControl() async {
    await _dbRef.child('control').update({
      'pumpManual': false,
      'lastCommand': DateTime.now().millisecondsSinceEpoch,
    });
  }
}