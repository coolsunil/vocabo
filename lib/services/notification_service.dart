import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import '../data/word_of_day_store.dart';

final _plugin = FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  tz.initializeTimeZones();
  final tzInfo = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);
  await _plugin.initialize(settings);

  await _plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  await scheduleWordOfDayNotification();
}

Future<void> scheduleWordOfDayNotification() async {
  final word = wordOfDay;
  if (word == null) return;

  await _plugin.cancel(0);

  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }

  final meaning = word.meaningEn.isNotEmpty ? word.meaningEn : word.meaningHi;

  await _plugin.zonedSchedule(
    0,
    'Word of the Day: ${word.word}',
    meaning.length > 80 ? '${meaning.substring(0, 80)}…' : meaning,
    scheduled,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'word_of_day',
        'Word of the Day',
        channelDescription: 'Daily vocabulary word to keep your streak alive',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.time,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
  );
}
