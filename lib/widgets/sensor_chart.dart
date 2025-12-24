import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/sensor_data.dart';

class SensorChart extends StatelessWidget {
  final SensorData data;
  const SensorChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: [
                  FlSpot(0, data.temperature),
                  FlSpot(1, data.waterHeight),
                  FlSpot(2, data.galonPct),
                ],
                isCurved: true,
                color: Colors.blueAccent,
                barWidth: 5,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withOpacity(0.2),
                ),
              ),
            ],
            titlesData: FlTitlesData(show: false),
            gridData: FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
          duration: const Duration(milliseconds: 400),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }
}