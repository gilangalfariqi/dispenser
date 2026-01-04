// lib/screens/stats_screen.dart  (fl_chart ^1.1.1)
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:iot_dispenser/services/firebase_service.dart';
import 'package:iot_dispenser/models/sensor_data.dart';
import 'package:iot_dispenser/providers/chart_data_provider.dart';
import 'package:iot_dispenser/widgets/animated_background.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late StreamSubscription<SensorData> _subscription;

  @override
  void initState() {
    super.initState();
    final chartProvider = context.read<ChartDataProvider>();
    final firebaseService = context.read<FirebaseService>();
    _subscription = firebaseService.sensorStream.listen(chartProvider.addDataPoint);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onBackground;
    final cardColor = theme.colorScheme.surface.withOpacity(isDark ? 0.6 : 0.85);

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Statistik Real-Time',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
                const SizedBox(height: 24),
                Text('Suhu (°C)', style: theme.textTheme.titleMedium?.copyWith(color: textColor)),
                const SizedBox(height: 8),
                _buildChart(context, isTemperature: true, cardColor: cardColor, isDark: isDark),
                const SizedBox(height: 32),
                Text('Volume (mL)', style: theme.textTheme.titleMedium?.copyWith(color: textColor)),
                const SizedBox(height: 8),
                _buildChart(context, isTemperature: false, cardColor: cardColor, isDark: isDark),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () => context.read<ChartDataProvider>().clear(),
                    child: const Text('Reset Grafik'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context,
      {required bool isTemperature, required Color cardColor, required bool isDark}) {
    final theme = Theme.of(context);
    final lineColor = isTemperature
        ? (isDark ? Colors.orangeAccent : Colors.deepOrange)
        : (isDark ? Colors.lightBlueAccent : Colors.blue);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
      child: LineChart(
        LineChartData(
          backgroundColor: Colors.transparent,
          borderData: FlBorderData(show: false),
          /* ----------  fl_chart 1.1.1  ---------- */
          gridData: const FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            // tidak ada getDrawingLine di 1.x
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, _) => Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: theme.textTheme.bodySmall?.color,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: lineColor,
              barWidth: 2,
              spots: _getSpots(context, isTemperature: isTemperature),
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.1),
              ),
            ),
          ],
          lineTouchData: LineTouchData(enabled: false),
        ),
      ),
    );
  }

  List<FlSpot> _getSpots(BuildContext context, {required bool isTemperature}) {
    final provider = context.watch<ChartDataProvider>();
    final history = isTemperature
        ? provider.temperatureHistory
        : provider.volumeHistory;
    if (history.isEmpty) return const [FlSpot(0, 0)];
    return history.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();
  }
}