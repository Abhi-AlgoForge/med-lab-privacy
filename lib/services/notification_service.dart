import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/user_profile.dart';
import '../models/medication_reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
  }

  Future<bool> requestPermissions() async {
    if (await Permission.notification.isGranted) {
      return true;
    }
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> scheduleReminder({
    required MedicationReminder reminder,
    required UserProfile userProfile,
  }) async {
    await initialize();

    // Cancel existing notifications for this reminder
    await cancelReminder(reminder);

    // Get the time based on timing
    TimeOfDay scheduleTime;
    switch (reminder.timing) {
      case MedicationTiming.morning:
        scheduleTime = userProfile.breakfastTime;
        break;
      case MedicationTiming.afternoon:
        scheduleTime = userProfile.lunchTime;
        break;
      case MedicationTiming.night:
        scheduleTime = userProfile.dinnerTime;
        break;
    }

    // Adjust time based on before/after eating
    final minutes = reminder.beforeEating ? -30 : 30;
    final adjustedTime = _adjustTime(scheduleTime, minutes);

    final notificationId = reminder.id.hashCode;

    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Daily medication reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final timingText = reminder.beforeEating ? 'before' : 'after';
    final mealText = reminder.timing.displayName.toLowerCase();

    // Calculate the next occurrence of the scheduled time
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      adjustedTime.hour,
      adjustedTime.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      notificationId,
      'Medication Reminder',
      'Time to take ${reminder.medicineName} ($timingText $mealText)',
      scheduledDate,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  TimeOfDay _adjustTime(TimeOfDay time, int minutesToAdd) {
    int totalMinutes = time.hour * 60 + time.minute + minutesToAdd;
    while (totalMinutes < 0) {
      totalMinutes += 24 * 60;
    }
    totalMinutes = totalMinutes % (24 * 60);
    return TimeOfDay(
      hour: totalMinutes ~/ 60,
      minute: totalMinutes % 60,
    );
  }

  Future<void> cancelReminder(MedicationReminder reminder) async {
    final notificationId = reminder.id.hashCode;
    await _notifications.cancel(notificationId);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
