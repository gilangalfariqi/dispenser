// lib/widgets/animated_background.dart
import 'package:flutter/material.dart';

class AnimatedBackground extends StatelessWidget {
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
            const Color(0xFF0A0E21),
            const Color(0xFF1D1E33),
          ]
              : [
            const Color(0xFFF5F7FA),
            const Color(0xFFE8EAF6),
          ],
        ),
      ),
      child: child,
    );
  }
}