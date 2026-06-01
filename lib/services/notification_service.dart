import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool _timeZonesInitialized = false;
  static const int _waterReminderId = 0;
  static const int _workoutReminderId = 1;
  static const int _experienceRankUpId = 2;
  static const int _workoutReminderHour = 8;

  static Future<void> init() async {
    if (_initialized) return;
    await _initTimeZones();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
    _initialized = true;
  }

  static Future<void> _initTimeZones() async {
    if (_timeZonesInitialized) return;
    try {
      tzdata.initializeTimeZones();
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    _timeZonesInitialized = true;
  }

  static Future<bool> requestPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final requested = await Permission.notification.request();
    return requested.isGranted;
  }

  static Future<bool> enableWaterReminders() async {
    await init();
    final granted = await requestPermission();
    if (!granted) return false;
    await cancelWaterReminder();
    await scheduleWaterReminder();
    return true;
  }

  static Future<void> scheduleWaterReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'water_channel',
      'Water Reminders',
      channelDescription: 'Reminds you to drink water every 2 hours',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.periodicallyShowWithDuration(
      id: _waterReminderId,
      title: 'Time to Hydrate',
      body: 'Drink a glass of water now. Keep your energy up.',
      repeatDurationInterval: const Duration(hours: 2),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<bool> enableWorkoutReminders() async {
    await init();
    final granted = await requestPermission();
    if (!granted) return false;
    await cancelWorkoutReminder();
    await scheduleWorkoutReminder();
    return true;
  }

  static Future<void> scheduleWorkoutReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'workout_channel',
      'Workout Reminders',
      channelDescription: 'Reminds you to train every day',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    final scheduledDate = _nextWorkoutReminderInstance();
    await _plugin.zonedSchedule(
      id: _workoutReminderId,
      title: 'Time to Train',
      body: 'Open LockIn and finish today\'s workout. No excuses.',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> showExperienceRankUpNotification({
    required String oldRank,
    required String newRank,
  }) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'experience_channel',
        'Experience Updates',
        channelDescription: 'Notifies you when your workout rank changes',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: _experienceRankUpId,
      title: 'Rank up',
      body:
          'Your experience changed from ${_experienceLabel(oldRank)} to ${_experienceLabel(newRank)}.',
      notificationDetails: details,
    );
  }

  static tz.TZDateTime _nextWorkoutReminderInstance() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      _workoutReminderHour,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> cancelWaterReminder() async {
    await _plugin.cancel(id: _waterReminderId);
  }

  static Future<void> cancelWorkoutReminder() async {
    await _plugin.cancel(id: _workoutReminderId);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static String _experienceLabel(String rank) {
    switch (rank.toLowerCase()) {
      case 'intermediate':
        return 'INTERMEDIATE';
      case 'advanced':
        return 'ADVANCED';
      default:
        return 'BEGINNER';
    }
  }
}
