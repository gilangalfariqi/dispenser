// lib/widgets/connection_indicator.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ConnectionIndicator extends StatefulWidget {
  const ConnectionIndicator({super.key});

  @override
  State<ConnectionIndicator> createState() => _ConnectionIndicatorState();
}

class _ConnectionIndicatorState extends State<ConnectionIndicator> {
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  void _checkConnection() {
    final connectedRef = FirebaseDatabase.instance.ref('.info/connected');
    connectedRef.onValue.listen((event) {
      if (mounted) {
        setState(() {
          _isConnected = event.snapshot.value == true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _isConnected
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isConnected
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green : Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isConnected ? 'Connected' : 'Connecting...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _isConnected
                  ? Colors.green
                  : (isDark ? Colors.orange.shade300 : Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }
}