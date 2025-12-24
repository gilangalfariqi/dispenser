import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import '../models/sensor_data.dart';

class AnimateStatusCard extends StatelessWidget {
  final SensorData data;
  const AnimateStatusCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final color = data.color == 'red'
        ? Colors.red
        : data.color == 'orange'
        ? Colors.orange
        : Colors.green;

    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(data.message,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SleekCircularSlider(
              min: 0,
              max: 100,
              initialValue: data.progress.toDouble(),
              appearance: CircularSliderAppearance(
                customWidths: CustomSliderWidths(
                  trackWidth: 6,
                  progressBarWidth: 10,
                ),
                customColors: CustomSliderColors(
                  trackColor: Colors.grey[300]!,
                  progressBarColor: color,
                ),
              ),
              innerWidget: (value) => Center(
                child: Text(
                  '${value.toInt()}%',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoChip('Suhu', '${data.temperature.toStringAsFixed(1)} °C'),
                _infoChip('Galon', '${data.galonPct.toStringAsFixed(0)} %'),
                _infoChip('Volume', '${data.volume.toStringAsFixed(0)} mL'),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .scale(curve: Curves.easeOutBack);
  }

  Widget _infoChip(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }
}