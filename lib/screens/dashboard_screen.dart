import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iot_dispenser/services/firebase_service.dart';
import 'package:iot_dispenser/models/sensor_data.dart';
import 'package:iot_dispenser/widgets/sensor_chart.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('📊 Realtime Monitoring', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<SensorData>(
                stream: context.watch<FirebaseService>().sensorStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data!;
                  return SensorChart(data: data);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}