// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iot_dispenser/providers/theme_provider.dart';
import 'package:iot_dispenser/widgets/animated_background.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pengaturan',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),

                _buildSettingTile(
                  context,
                  icon: Icons.brightness_4,
                  title: 'Mode Gelap',
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) => themeProvider.toggleTheme(),
                    activeColor: Colors.blue,
                  ),
                ),

                const SizedBox(height: 20),

                _buildSettingTile(
                  context,
                  icon: Icons.notifications,
                  title: 'Notifikasi',
                  trailing: const Switch(value: true, activeColor: Colors.blue),
                ),

                const SizedBox(height: 20),

                _buildSettingTile(
                  context,
                  icon: Icons.info,
                  title: 'Tentang Aplikasi',
                  trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                  onTap: () {
                    // Buka dialog about
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Colors.grey[900],
                        title: const Text('Tentang Smart Dispenser'),
                        content: const Text('Aplikasi IoT untuk memantau dan mengontrol dispenser pintar secara real-time.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Tutup', style: TextStyle(color: Colors.blue)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, {
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[800]?.withOpacity(0.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
            const Spacer(),
            trailing,
          ],
        ),
      ),
    );
  }
}