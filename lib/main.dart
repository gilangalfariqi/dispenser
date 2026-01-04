import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

// ----------  SERVICES  ----------
import 'package:iot_dispenser/services/firebase_service.dart';
import 'package:iot_dispenser/services/notification_service.dart';

// ----------  SCREENS  ----------
import 'package:iot_dispenser/screens/home_screen.dart';
import 'package:iot_dispenser/screens/stats_screen.dart';
import 'package:iot_dispenser/screens/settings_screen.dart';
import 'package:iot_dispenser/screens/login_screen.dart';

// ----------  PROVIDERS  ----------
import 'package:iot_dispenser/providers/chart_data_provider.dart';
import 'package:iot_dispenser/providers/theme_provider.dart';
import 'package:iot_dispenser/screens/settings_screen.dart' show SettingsModel;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().initialize();
  runApp(const MyApp());
}

/* ====================  ROOT  ==================== */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => FirebaseService()),
        ChangeNotifierProvider(create: (_) => ChartDataProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsModel()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, theme, __) => MaterialApp(
          title: 'Smart Dispenser',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
          ),
          themeMode: theme.mode,
          home: const AuthWrapper(),   // otomatis ke login/home
        ),
      ),
    );
  }
}

/* ====================  AUTH WRAPPER  ==================== */
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (_, snap) {
        if (snap.hasData) return const MainApp();   // sudah login
        return const LoginScreen();                 // belum login
      },
    );
  }
}

/* ====================  BOTTOM NAV  ==================== */
class MainApp extends StatefulWidget {
  const MainApp({super.key});
  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;
  final List<Widget> _pages = const [
    HomeScreen(),
    StatsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistik'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }
}