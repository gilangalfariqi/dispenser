import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iot_dispenser/services/firebase_service.dart';
import 'package:iot_dispenser/models/sensor_data.dart';
import 'package:iot_dispenser/widgets/connection_indicator.dart';
import 'package:iot_dispenser/providers/theme_provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const ConnectionIndicator(),
              const SizedBox(height: 24),
              Expanded(
                child: StreamBuilder<SensorData>(
                  stream: context.read<FirebaseService>().sensorStream,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return _ErrorView(onRetry: () => (context as Element).markNeedsBuild());
                    }
                    if (!snap.hasData) {
                      return _LoadingView(isDark: isDark);
                    }

                    final data = snap.data!;
                    return _DataView(data: data, isDark: isDark);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ------------- SUB-WIDGETS ------------- */
class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text('Gagal Memuat Data',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red)),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Ulang'),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final bool isDark;
  const _LoadingView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: isDark ? Colors.cyan : Colors.blue),
          const SizedBox(height: 16),
          Text('Menunggu data dari dispenser...',
              style: TextStyle(color: isDark ? Colors.grey[300] : Colors.grey[700])),
        ],
      ),
    );
  }
}

class _DataView extends StatelessWidget {
  final SensorData data;
  final bool isDark;
  const _DataView({required this.data, required this.isDark});

  Future<void> _togglePump(BuildContext context) async {
    try {
      final service = context.read<FirebaseService>();
      await service.togglePump(data.glassStatus == 'filling');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Column(
      children: [
        // Big Hydration Card
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.primaryColor, theme.primaryColor.withOpacity(.7)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 10, offset: const Offset(0, 5)),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Current Hydration', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                Text('${data.galonPct.toStringAsFixed(0)} %', style: TextStyle(color: textColor, fontSize: 48, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${data.waterHeight} cm', style: TextStyle(color: textColor.withOpacity(.8), fontSize: 16)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Grid of 4 Cards
        Expanded(
          flex: 3,
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _SensorCard(title: 'Galon', icon: Icons.local_drink, value: '${data.galonPct.toStringAsFixed(0)} %', color: Colors.green),
              _SensorCard(title: 'Temperature', icon: Icons.thermostat, value: '${data.temperature.toStringAsFixed(1)} °C', color: Colors.orange),
              _SensorCard(title: 'Volume', icon: Icons.water_drop, value: '${data.volume} mL', color: Colors.blue),
              _SensorCard(title: 'Glass', icon: Icons.local_bar, value: data.glassStatus, color: Colors.teal),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Start/Stop Button
        SizedBox(
          width: 160,
          height: 50,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.water_drop, color: Colors.white, size: 20),
            label: Text(data.glassStatus == 'filling' ? 'STOP' : 'START', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              elevation: 5,
              shadowColor: theme.primaryColor.withOpacity(.3),
            ),
            onPressed: () => _togglePump(context),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _SensorCard({required this.title, required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [Icon(icon, color: color, size: 24), const SizedBox(width: 8), Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color))]),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
        ],
      ),
    );
  }
}