import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/sensor_data.dart';

class PumpControlButton extends StatelessWidget {
  final SensorData data;
  const PumpControlButton({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final isActive = data.status == 'filling';
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isActive ? 'Stopping pump...' : 'Pump is auto-controlled'),
            behavior: SnackBarBehavior.floating,
          ).animate().fadeIn(duration: 300.ms) as SnackBar,
        );
      },
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isActive
                ? [Colors.orangeAccent, Colors.deepOrange]
                : [Colors.greenAccent, Colors.green],
          ),
          boxShadow: [
            BoxShadow(
              color: (isActive ? Colors.deepOrange : Colors.green).withValues(alpha: 0.5),
              blurRadius: 25,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Icon(
          isActive ? Icons.stop_rounded : Icons.play_arrow_rounded,
          size: 70,
          color: Colors.white,
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }
}