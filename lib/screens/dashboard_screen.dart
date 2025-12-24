import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/sensor_data.dart';
import '../services/firebase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  /* ---------- animasi air (nullable) ---------- */
  AnimationController? _waveCtrl;
  Animation<double>? _waveAnim;
  /* ---------- bottom nav ----------- */
  int _currentIndex = 0;
  /* ---------- notifikasi ----------- */
  final FlutterLocalNotificationsPlugin _notif =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initWave();
    _initNotif();
    tz.initializeTimeZones(); // untuk TZDateTime
  }

  void _initWave() {
    _waveCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))..repeat();
    _waveAnim = Tween<double>(begin: 0, end: 1).animate(_waveCtrl!);
  }

  Future<void> _initNotif() async {
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(android: android);
    await _notif.initialize(initSettings);
  }

  @override
  void dispose() {
    _waveCtrl?.dispose();
    super.dispose();
  }

  /* ---------------- build ---------------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: const Color(0xFFF2F7FB),
      body: StreamBuilder<SensorData>(
        stream: context.read<FirebaseService>().sensorStream,
        initialData: const SensorData(),
        builder: (context, snap) {
          final data = snap.data!;
          if (snap.hasError) {
            return Center(child: Text('Stream Error: ${snap.error}'));
          }
          if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          /* notif saat data baru */
          if (snap.connectionState == ConnectionState.active &&
              data.timestamp > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Updated • ${data.glassStatus}'),
                backgroundColor: Colors.cyan[700],
                duration: const Duration(milliseconds: 700),
              ));
            });
          }
          return _buildPage(_currentIndex, data);
        },
      ),
      floatingActionButton: _fab(_currentIndex),
      bottomNavigationBar: _bottomBar(),
    );
  }

  /* ---------------- halaman per tab ---------------- */
  Widget _buildPage(int index, SensorData data) {
    switch (index) {
      case 0:
        return _homeTab(data);
      case 1:
        return _alarmTab();
      case 2:
        return _statsTab(data);
      case 3:
        return _settingsTab();
      default:
        return _homeTab(data);
    }
  }

  /* ---------------- TAB 1 : HOME (dashboard) ---------------- */
  Widget _homeTab(SensorData d) {
    return Stack(
      children: [
        _animatedWave(),
        SafeArea(
          child: LayoutBuilder(builder: (_, box) {
            final isTablet = box.maxWidth > 600;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: isTablet ? _tabletContent(d) : _phoneContent(d),
            );
          }),
        ),
      ],
    );
  }

  /* ---------------- TAB 2 : ALARM ---------------- */
  Widget _alarmTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.alarm, size: 64, color: Colors.indigo),
          const SizedBox(height: 16),
          Text('Set Dispenser Alarm',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_alarm),
            label: const Text('Add Alarm'),
            onPressed: () => _showAlarmDialog(),
          ),
          const SizedBox(height: 20),
          _alarmList(),
        ],
      ),
    );
  }

  /* ---------------- TAB 3 : STATS ---------------- */
  Widget _statsTab(SensorData d) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart, size: 64, color: Colors.green),
          const SizedBox(height: 16),
          Text('Weekly Statistics',
              style: GoogleFonts.poppins(
                  fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text('Water: ${d.waterHeight} cm\nGalon: ${d.galonPct} %',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16)),
          const SizedBox(height: 20),
          /* dummy chart - bisa ganti Fl_Chart */
          SizedBox(
            height: 200,
            child: SleekCircularSlider(
              min: 0,
              max: 100,
              initialValue: d.galonPct,
              appearance: CircularSliderAppearance(
                  size: 180,
                  customColors: CustomSliderColors(
                      progressBarColor: Colors.green)),
              innerWidget: (_) => Center(
                child: Text('${d.galonPct.toStringAsFixed(0)} %',
                    style: GoogleFonts.poppins(
                        fontSize: 28, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /* ---------------- TAB 4 : SETTINGS ---------------- */
  Widget _settingsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings',
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.indigo),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAbout(),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens, color: Colors.indigo),
            title: const Text('Theme'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.indigo),
            title: const Text('Sign Out'),
            onTap: () {/* todo logout */},
          ),
        ],
      ),
    );
  }

  /* ---------------- FAB dinamis ---------------- */
  Widget? _fab(int index) {
    if (index == 0) {
      return FloatingActionButton.extended(
        icon: const Icon(Icons.water_drop, color: Colors.white),
        label: Text('START', style: GoogleFonts.poppins(fontSize: 16)),
        backgroundColor: Colors.indigoAccent,
        onPressed: () => context.read<FirebaseService>().togglePump(true),
      );
    }
    return null; // tidak tampil di tab lain
  }

  /* ---------------- dialog alarm ---------------- */
  void _showAlarmDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Alarm'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(hintText: '08:00'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
              onPressed: () async {
                /* simpan ke shared_pref + jadwalkan notif */
                final pref = await SharedPreferences.getInstance();
                await pref.setString('alarm', ctrl.text);
                _scheduleAlarm(ctrl.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Alarm ${ctrl.text} saved')));
              },
              child: const Text('SAVE'))
        ],
      ),
    );
  }

  /* ---------------- jadwal notif (dummy) ---------------- */
  Future<void> _scheduleAlarm(String time) async {
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;
    final now = DateTime.now();
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));

    final tzScheduled = tz.TZDateTime.from(scheduled, tz.local);

    await _notif.zonedSchedule(
      1,
      'Dispenser Alarm',
      'Time to drink water!',
      tzScheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dispenser_alarm',
          'Alarm',
          channelDescription: 'Reminder to drink',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /* ---------------- list alarm (dummy) ---------------- */
  Widget _alarmList() {
    return FutureBuilder<List<String>>(
      future: _loadAlarms(),
      builder: (_, snap) {
        if (!snap.hasData) return const CircularProgressIndicator();
        final alarms = snap.data!;
        if (alarms.isEmpty) return const Text('No alarms');
        return Column(
          children: alarms
              .map((a) => Card(
            child: ListTile(
              leading: const Icon(Icons.alarm),
              title: Text(a),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final pref = await SharedPreferences.getInstance();
                  await pref.remove('alarm');
                  setState(() {});
                },
              ),
            ),
          ))
              .toList(),
        );
      },
    );
  }

  Future<List<String>> _loadAlarms() async {
    final pref = await SharedPreferences.getInstance();
    final alarm = pref.getString('alarm');
    return alarm == null ? [] : [alarm];
  }

  /* ---------------- dialog about ---------------- */
  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Smart Dispenser',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Your Company',
    );
  }

  /* ---------------- dialog tema ---------------- */
  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['System', 'Light', 'Dark']
              .map((e) => ListTile(
            title: Text(e),
            onTap: () {
              /* todo ganti tema */
              Navigator.pop(context);
            },
          ))
              .toList(),
        ),
      ),
    );
  }

  /* ---------------- animasi wave (safe) ---------------- */
  Widget _animatedWave() {
    final anim = _waveAnim;
    if (anim == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        return ClipPath(
          clipper: _WaveClipper(anim.value),
          child: Container(
            height: 300,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight),
            ),
          ),
        );
      },
    );
  }

  /* ---------------- phone / tablet layout ---------------- */
  Widget _phoneContent(SensorData d) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _hydrationCard(d.waterHeight),
      const SizedBox(height: 24),
      _gridInfo(d),
      const SizedBox(height: 100),
    ],
  );

  Widget _tabletContent(SensorData d) => Column(
    children: [
      _hydrationCard(d.waterHeight),
      const SizedBox(height: 24),
      _gridInfo(d),
      const SizedBox(height: 100),
    ],
  );

  Widget _gridInfo(SensorData d) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 1.15),
      children: [
        _infoCard('Galon', '${d.galonPct.toStringAsFixed(0)} %',
            Icons.inventory, const Color(0xFF4CAF50)),
        _infoCard('Temperature', '${d.temperature.toStringAsFixed(1)} °C',
            Icons.thermostat, const Color(0xFFFF9800)),
        _infoCard('Volume', '${d.volume.toStringAsFixed(0)} mL',
            Icons.water_drop, const Color(0xFF03A9F4)),
        _infoCard('Glass', d.glassStatus, Icons.wine_bar,
            const Color(0xFF009688)),
      ],
    );
  }

  Widget _hydrationCard(double height) {
    final percent = ((height / 20) * 100).clamp(0, 100);
    return GlassmorphicContainer(
      width: double.infinity,
      height: 180,
      borderRadius: 24,
      blur: 15,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.cyan.withOpacity(.25),
            Colors.cyanAccent.withOpacity(.15)
          ]),
      borderGradient: LinearGradient(colors: [
        Colors.cyanAccent.withOpacity(.4),
        Colors.cyan.withOpacity(.1)
      ]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Current Hydration',
              style: GoogleFonts.poppins(
                  fontSize: 16, color: Colors.white.withOpacity(.9))),
          const SizedBox(height: 8),
          Text('${percent.toStringAsFixed(0)} %',
              style: GoogleFonts.poppins(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 4),
          Text('${height.toStringAsFixed(1)} cm',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
              colors: [color.withOpacity(.08), Colors.transparent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 6),
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  /* ---------------- bottom bar ---------------- */
  Widget _bottomBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Alarm'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}

/* ---------------- Custom clipper wave (bergerak) ---------------- */
class _WaveClipper extends CustomClipper<Path> {
  final double progress;
  _WaveClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    final ctrl = Offset(size.width * .5, size.height + 20 * progress);
    final end = Offset(size.width, size.height - 40);
    path.quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}