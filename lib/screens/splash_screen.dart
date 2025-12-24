import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iot_dispenser/services/firebase_service.dart';
import 'package:iot_dispenser/models/sensor_data.dart';
import 'package:iot_dispenser/widgets/connection_indicator.dart';
import 'package:iot_dispenser/widgets/sensor_card.dart';
import 'package:iot_dispenser/widgets/pump_control_button.dart';
import 'package:iot_dispenser/providers/theme_provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Dispenser'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            icon: Icon(
              context.watch<ThemeProvider>().isDarkMode
                  ? Icons.wb_sunny_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ConnectionIndicator(),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<SensorData>(
                stream: context.watch<FirebaseService>().sensorStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'Gagal Memuat Data',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Muat Ulang'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Menunggu data dari dispenser...'),
                        ],
                      ),
                    );
                  }

                  return SensorCard(data: snapshot.data!);
                },
              ),
            ),
            const SizedBox(height: 24),
            PumpControlButton(),
          ],
        ),
      ),
    );
  }
}