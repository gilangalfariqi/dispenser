// lib/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logPumpToggle(bool isOn) async {
    if (kDebugMode) return; // ✅ Nonaktifkan di debug mode

    try {
      await _analytics.logEvent(
        name: 'pump_toggled',
        parameters: {'is_on': isOn},
      );
    } catch (e) {
      // 🤫 Diam-diam gagal, jangan ganggu user
      print('Analytics error (pump): $e');
    }
  }

  static Future<void> logLowGallon() async {
    if (kDebugMode) return; // ✅ Nonaktifkan di debug mode

    try {
      await _analytics.logEvent(name: 'low_gallon_alert');
    } catch (e) {
      print('Analytics error (low gallon): $e');
    }
  }
}