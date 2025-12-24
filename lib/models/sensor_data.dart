class SensorData {
  final double waterHeight;
  final double galonPct;
  final double temperature;
  final double volume;
  final String status;
  final int progress;
  final String color;
  final String message;
  final int timestamp;        // ➜ tambahkan
  final String glassStatus;   // ➜ tambahkan

  const SensorData({
    this.waterHeight = 0,
    this.galonPct = 0,
    this.temperature = 0,
    this.volume = 0,
    this.status = 'idle',
    this.progress = 0,
    this.color = 'green',
    this.message = '',
    this.timestamp = 0,        // ➜ tambahkan
    this.glassStatus = 'idle', // ➜ tambahkan
  });

  factory SensorData.fromJson(Map<String, dynamic> json) => SensorData(
    waterHeight: (json['waterHeight'] ?? 0).toDouble(),
    galonPct: (json['galonPct'] ?? 0).toDouble(),
    temperature: (json['temperature'] ?? 0).toDouble(),
    volume: (json['volume'] ?? 0).toDouble(),
    status: json['status'] ?? 'idle',
    progress: json['progress'] ?? 0,
    color: json['color'] ?? 'green',
    message: json['message'] ?? '',
    timestamp: json['timestamp'] ?? 0,        // ➜ tambahkan
    glassStatus: json['glassStatus'] ?? 'idle', // ➜ tambahkan
  );
}