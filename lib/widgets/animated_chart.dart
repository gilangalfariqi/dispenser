import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AnimatedLineChart extends StatelessWidget {
  final List<FlSpot> spots;
  const AnimatedLineChart({super.key, required this.spots});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.white,
            barWidth: 4,
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: const FlTitlesData(show: false),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}