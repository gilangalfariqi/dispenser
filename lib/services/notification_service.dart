// lib/services/notification_service.dart
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  Future<void> showLowWaterNotification({
    required double percentage,
    required bool isCritical,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'water_level_channel',
      'Water Level Alerts',
      channelDescription: 'Notifications for low water levels',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFF5252),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      isCritical ? '⚠️ Critical Water Level!' : '💧 Low Water Level',
      isCritical
          ? 'Water level is critically low at ${percentage.toStringAsFixed(0)}%'
          : 'Water level is low at ${percentage.toStringAsFixed(0)}%. Please refill soon.',
      details,
    );
  }

  Future<void> showPumpStatusNotification({
    required bool isPumping,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pump_status_channel',
      'Pump Status',
      channelDescription: 'Notifications for pump status changes',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      isPumping ? '🚰 Pump Started' : '✓ Pump Stopped',
      isPumping
          ? 'Water dispenser pump is now running'
          : 'Water dispenser pump has stopped',
      details,
    );
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }
}