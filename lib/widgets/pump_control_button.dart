import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iot_dispenser/services/firebase_service.dart';

import '../models/sensor_data.dart';

class PumpControlButton extends StatefulWidget {
  const PumpControlButton({super.key});

  @override
  State<PumpControlButton> createState() => _PumpControlButtonState();
}

class _PumpControlButtonState extends State<PumpControlButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  StreamSubscription<SensorData>? _subscription;
  String _glassStatus = 'idle';
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _colorAnimation = ColorTween(begin: Colors.red, end: Colors.redAccent).animate(_controller);

    _subscription = context.read<FirebaseService>().sensorStream.listen((data) {
      if (mounted) {
        setState(() {
          _glassStatus = data.glassStatus;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFilling = _glassStatus == 'filling';
    final buttonColor = isFilling ? Colors.red : Colors.blue;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      onTap: () async {
        try {
          await context.read<FirebaseService>().togglePump(isFilling);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengirim perintah: $e')),
          );
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: buttonColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.water_drop,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  isFilling ? 'STOP PUMP' : 'START PUMP',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}