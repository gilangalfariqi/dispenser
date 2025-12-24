import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iot_dispenser/screens/splash.dart';
import 'package:iot_dispenser/services/firebase_service.dart';
import 'package:iot_dispenser/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
          // kalau butuh dispose, tambahkan dispose: (_, s) => s.dispose(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Dispenser',
      themeMode: ThemeMode.system,
      darkTheme: ThemeData.dark(useMaterial3: true),
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.cyan),
      home: const SplashScreen(),
    );
  }
}