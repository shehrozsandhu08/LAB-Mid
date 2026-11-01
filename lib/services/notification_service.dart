import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service to handle local notifications for daily reading goals,
/// document additions, and scheduled reading reminders.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked with payload: ${response.payload}');
      },
    );

    // Request permissions on Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  /// Show an immediate notification (e.g. for imported document or goal test)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? soundName,
    String? payload,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'pdf_reader_channel',
        'PDF Reader Notifications',
        channelDescription: 'Notifications for PDF reading goals and activities',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(),
      );

      await _notificationsPlugin.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Trigger notification when a new document is added or scanned
  Future<void> notifyDocumentAdded(String docTitle) async {
    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: 'New PDF Added',
      body: '"$docTitle" is ready in your library for reading.',
    );
  }

  /// Trigger reading goal reminder
  Future<void> notifyReadingGoalReminder(int goalMinutes) async {
    await showNotification(
      id: 9999,
      title: 'Daily Reading Goal Reminder',
      body: 'Time to read! Keep up your daily target of $goalMinutes minutes today.',
    );
  }

  /// Cancel all scheduled or active notifications
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
