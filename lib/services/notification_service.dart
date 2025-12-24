import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings android =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  static Future<void> show(String title, String body) async {
    const AndroidNotificationDetails android = AndroidNotificationDetails(
      'dispenser_channel',
      'Dispenser Alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails details = NotificationDetails(android: android);
    await _plugin.show(0, title, body, details);
  }
}