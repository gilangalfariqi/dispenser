// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iot_dispenser/providers/theme_provider.dart';
import 'package:iot_dispenser/widgets/animated_background.dart';

/* =============== MAIN SCREEN =============== */
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Text('Pengaturan',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                /* ---------- TAMPILAN ---------- */
                _Section(title: 'Tampilan', children: [
                  _SettingTile(
                    icon: Icons.brightness_4,
                    title: 'Mode Gelap',
                    trailing: Consumer<ThemeProvider>(
                      builder: (_, prov, __) => Switch(
                        value: prov.isDarkMode,
                        onChanged: (_) => prov.toggleTheme(),
                      ),
                    ),
                  ),
                ]),

                const _Gap(),

                /* ---------- NOTIFIKASI ---------- */
                _Section(title: 'Notifikasi', children: [
                  _SettingTile(
                    icon: Icons.notifications,
                    title: 'Notifikasi Push',
                    trailing: Consumer<SettingsModel>(
                      builder: (_, model, __) => Switch(
                        value: model.pushEnabled,
                        onChanged: (v) => model.pushEnabled = v,
                      ),
                    ),
                  ),
                ]),

                const _Gap(),

                /* ---------- INFORMASI ---------- */
                _Section(title: 'Informasi', children: [
                  _SettingTile(
                    icon: Icons.info,
                    title: 'Tentang Aplikasi',
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAbout(context),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* ----------- About Dialog ----------- */
  void _showAbout(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('Tentang Smart Dispenser',
            style: theme.textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Fitur utama:', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              _item(theme, '💧 Memantau level air real-time'),
              _item(theme, '🌡️ Melihat suhu dispenser'),
              _item(theme, '📊 Menganalisis penggunaan dengan grafik'),
              _item(theme, '🤖 Mengontrol pompa jarak jauh'),
              const SizedBox(height: 16),
              Text(
                  'Dibangun dengan Flutter & Firebase untuk performa cepat dan andal.',
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _item(ThemeData theme, String txt) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Expanded(child: Text(txt, style: theme.textTheme.bodySmall)),
      ],
    ),
  );
}

/* ========================================================= */
/* ------------------ REUSABLE WIDGETS --------------------- */
/* ========================================================= */
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

/* Card + ListTile digabung agar ripple pas */
class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: .5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(title, style: theme.textTheme.bodyLarge),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class _Gap extends StatelessWidget {
  const _Gap();
  @override
  Widget build(BuildContext context) =>
      const SliverToBoxAdapter(child: SizedBox(height: 20));
}

/* ========================================================= */
/* ------------------ SIMPLE STATE MODEL ------------------- */
/* ========================================================= */
class SettingsModel extends ChangeNotifier {
  bool _push = true;
  bool get pushEnabled => _push;
  set pushEnabled(bool v) {
    _push = v;
    notifyListeners();
  }
}