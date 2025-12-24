import 'package:flutter/material.dart';

import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const DashboardScreen()));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Hero(
          tag: 'logo',
          child: ScaleTransition(
              scale: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)),
              child: const FlutterLogo(size: 120)),
        ),
      ),
    );
  }
}