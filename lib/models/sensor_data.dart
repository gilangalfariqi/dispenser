// lib/models/sensor_data.dart
class SensorData {
  final double waterHeight;
  final double galonPct;
  final double temperature;
  final int volume;
  final String glassStatus;
  final int timestamp;

  SensorData({
    required this.waterHeight,
    required this.galonPct,
    required this.temperature,
    required this.volume,
    required this.glassStatus,
    required this.timestamp,
  });

  factory SensorData.fromJson(Map<dynamic, dynamic> json) {
    return SensorData(
      waterHeight: (json['waterHeight'] ?? 0).toDouble(),
      galonPct: (json['galonLevel'] ?? 0).toDouble(),
      temperature: (json['temperature'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toInt(),
      glassStatus: json['glassStatus'] ?? 'empty',
      timestamp: json['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'waterHeight': waterHeight,
      'galonLevel': galonPct,
      'temperature': temperature,
      'volume': volume,
      'glassStatus': glassStatus,
      'timestamp': timestamp,
    };
  }

  bool get isLowWater => galonPct < 20;
  bool get isCriticalWater => galonPct < 10;
  bool get isFilling => glassStatus.toLowerCase() == 'filling';
}