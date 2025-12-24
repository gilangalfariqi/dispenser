import 'package:flutter/material.dart';

class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 16),
      child: Row(
        children: [
          Icon(Icons.circle, color: Colors.green, size: 12),
          SizedBox(width: 4),
          Text('Connected', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}