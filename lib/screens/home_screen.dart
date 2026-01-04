// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:iot_dispenser/services/firebase_service.dart';
import 'package:iot_dispenser/services/notification_service.dart';
import 'package:iot_dispenser/models/sensor_data.dart';
import 'package:iot_dispenser/widgets/connection_indicator.dart';
import 'package:iot_dispenser/widgets/animated_background.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isProcessing = false;
  AnimationController? _pulseController;
  double _lastNotifiedPercentage = 100;
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _startMonitoring();
  }

  void _startMonitoring() {
    context.read<FirebaseService>().sensorStream.listen((data) {
      if (data.isLowWater && data.galonPct < _lastNotifiedPercentage - 10) {
        _notificationService.showLowWaterNotification(
          percentage: data.galonPct,
          isCritical: data.isCriticalWater,
        );
        _lastNotifiedPercentage = data.galonPct;
      }
    });
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E21) : const Color(0xFFF5F7FA),
      body: AnimatedBackground(
        child: SafeArea(
          child: StreamBuilder<SensorData>(
            stream: context.watch<FirebaseService>().sensorStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString(), isDark);
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState(colors);
              }

              if (!snapshot.hasData) {
                return _buildNoDataState(colors, isDark);
              }

              final data = snapshot.data!;
              return _buildMainContent(data, isDark, colors);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(SensorData data, bool isDark, ColorScheme colors) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 16),
              const ConnectionIndicator(),
              const SizedBox(height: 24),
              _buildMainStatusCard(data, isDark),
              const SizedBox(height: 24),
              Text(
                'Sensor Monitoring',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1F3A),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailedMetrics(data, isDark),
              const SizedBox(height: 24),
              // _buildPumpControl(data, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final firebaseService = context.read<FirebaseService>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Dispenser',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1F3A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'IoT Water Monitoring',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.water_drop,
                color: Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () async {
                await firebaseService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              icon: Icon(
                Icons.logout,
                color: isDark ? Colors.white : Colors.black54,
              ),
              tooltip: 'Logout',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainStatusCard(SensorData data, bool isDark) {
    final percentage = data.galonPct.clamp(0.0, 100.0).toDouble();
    final color = _getStatusColor(percentage);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Water Level',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getStatusText(percentage),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (_pulseController != null)
                AnimatedBuilder(
                  animation: _pulseController!,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(
                          0.15 + (_pulseController!.value * 0.1),
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.water_drop,
                        color: Colors.white,
                        size: 28,
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                percentage.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  '%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.straighten,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Height: ${data.waterHeight.clamp(0.0, 100.0).toStringAsFixed(1)} cm',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(SensorData data, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            icon: Icons.thermostat_rounded,
            label: 'Temp',
            value: '${data.temperature.clamp(-50.0, 150.0).toStringAsFixed(1)}°',
            color: Colors.orange,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            icon: Icons.opacity,
            label: 'Volume',
            value: '${data.volume.clamp(0, 10000)} mL',
            color: Colors.blue,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            icon: Icons.local_bar,
            label: 'Status',
            value: _getGlassStatusEmoji(data.glassStatus),
            color: Colors.teal,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1E33) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedMetrics(SensorData data, bool isDark) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.35,
      children: [
        _buildMetricCard(
          title: 'Galon Level',
          value: '${data.galonPct.clamp(0.0, 100.0).toStringAsFixed(0)}%',
          icon: Icons.local_drink,
          color: Colors.green,
          isDark: isDark,
          progress: data.galonPct / 100,
        ),
        _buildMetricCard(
          title: 'Temperature',
          value: '${data.temperature.clamp(-50.0, 150.0).toStringAsFixed(1)}°C',
          icon: Icons.thermostat,
          color: Colors.orange,
          isDark: isDark,
          progress: data.temperature.clamp(0.0, 50.0) / 50,
        ),
        _buildMetricCard(
          title: 'Water Volume',
          value: '${data.volume.clamp(0, 10000)} mL',
          icon: Icons.water_drop,
          color: Colors.blue,
          isDark: isDark,
          progress: data.volume.clamp(0, 500).toDouble() / 500,
        ),
        _buildMetricCard(
          title: 'Glass Status',
          value: _getGlassStatusText(data.glassStatus),
          icon: Icons.local_bar,
          color: Colors.purple,
          isDark: isDark,
          progress: data.glassStatus.toLowerCase() == 'full' ? 1.0 : 0.5,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    required double progress,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D1E33) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 4,
                color: color.withOpacity(0.2),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(color: color),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget _buildPumpControl(SensorData data, bool isDark) {
  //   final isFilling = data.glassStatus.toLowerCase() == 'filling';
  //
  //   return Column(
  //     children: [
  //       Text(
  //         'Pump Control',
  //         style: TextStyle(
  //           fontSize: 18,
  //           fontWeight: FontWeight.bold,
  //           color: isDark ? Colors.white : const Color(0xFF1A1F3A),
  //         ),
  //       ),
  //       const SizedBox(height: 16),
  //       Material(
  //         color: Colors.transparent,
  //         child: InkWell(
  //           onTap: _isProcessing ? null : () => _handlePumpToggle(isFilling),
  //           borderRadius: BorderRadius.circular(30),
  //           child: Container(
  //             height: 65,
  //             decoration: BoxDecoration(
  //               gradient: LinearGradient(
  //                 colors: isFilling
  //                     ? [Colors.red.shade600, Colors.red.shade400]
  //                     : [Colors.blue.shade600, Colors.blue.shade400],
  //               ),
  //               borderRadius: BorderRadius.circular(30),
  //               boxShadow: [
  //                 BoxShadow(
  //                   color: (isFilling ? Colors.red : Colors.blue)
  //                       .withOpacity(0.4),
  //                   blurRadius: 20,
  //                   offset: const Offset(0, 10),
  //                 ),
  //               ],
  //             ),
  //             child: Center(
  //               child: _isProcessing
  //                   ? const SizedBox(
  //                 width: 28,
  //                 height: 28,
  //                 child: CircularProgressIndicator(
  //                   color: Colors.white,
  //                   strokeWidth: 3,
  //                 ),
  //               )
  //                   : Row(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Icon(
  //                     isFilling ? Icons.stop_circle : Icons.play_circle,
  //                     color: Colors.white,
  //                     size: 28,
  //                   ),
  //                   const SizedBox(width: 12),
  //                   Text(
  //                     isFilling ? 'STOP PUMP' : 'START PUMP',
  //                     style: const TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.bold,
  //                       letterSpacing: 1.2,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Future<void> _handlePumpToggle(bool isFilling) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      await context.read<FirebaseService>().togglePump(isFilling);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isFilling ? Icons.stop_circle : Icons.play_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  isFilling ? 'Pump Stopped' : 'Pump Started',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor:
            isFilling ? Colors.red.shade600 : Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildLoadingState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colors.primary),
          const SizedBox(height: 24),
          Text(
            'Loading sensor data...',
            style: TextStyle(
              fontSize: 16,
              color: colors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(ColorScheme colors, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sensors_off,
              color: colors.primary,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Data Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Please ensure your IoT device is connected',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                isDark ? const Color(0xFF1D1E33) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Connection'),
              style: ElevatedButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(double percentage) {
    if (percentage >= 70) return Colors.green.shade600;
    if (percentage >= 40) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  String _getStatusText(double percentage) {
    if (percentage >= 70) return 'Optimal Level';
    if (percentage >= 40) return 'Medium Level';
    if (percentage >= 20) return 'Low Level';
    return 'Critical Level';
  }

  String _getGlassStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'filling':
        return 'Filling';
      case 'full':
        return 'Full';
      case 'empty':
        return 'Empty';
      default:
        return status;
    }
  }

  String _getGlassStatusEmoji(String status) {
    switch (status.toLowerCase()) {
      case 'filling':
        return '⏳';
      case 'full':
        return '✓';
      case 'empty':
        return '○';
      default:
        return '?';
    }
  }
}