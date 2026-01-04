// lib/providers/chart_data_provider.dart
import 'package:flutter/material.dart';
import 'package:iot_dispenser/models/sensor_data.dart';

class ChartDataProvider with ChangeNotifier {
  final List<double> _temperatureHistory = [];
  final List<double> _volumeHistory = [];
  static const int maxPoints = 20;

  List<double> get temperatureHistory => List.unmodifiable(_temperatureHistory);
  List<double> get volumeHistory => List.unmodifiable(_volumeHistory);

  void addDataPoint(SensorData data) {
    _temperatureHistory.add(data.temperature);
    _volumeHistory.add(data.volume as double);

    if (_temperatureHistory.length > maxPoints) {
      _temperatureHistory.removeAt(0);
      _volumeHistory.removeAt(0);
    }

    notifyListeners();
  }

  void clear() {
    _temperatureHistory.clear();
    _volumeHistory.clear();
    notifyListeners();
  }
}