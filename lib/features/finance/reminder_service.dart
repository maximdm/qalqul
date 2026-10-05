import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/features/finance/transactions_repository.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules local notifications for recurring transactions that are due soon.
///
/// Best-effort: any failure (unsupported platform, missing permission) is
/// swallowed so the app never crashes because of notifications.
class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Asks for the runtime permissions the scheduled reminders need. Safe to
  /// call repeatedly: Android only shows the prompt once, and a refusal leaves
  /// reminders simply unscheduled.
  static Future<void> requestPermissions() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      // Android 14+ gates exact alarms behind a separate grant.
      await android?.requestExactAlarmsPermission();

      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  static Future<void> init() async {
    try {
      tz_data.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Loads recurring transactions and schedules reminders for those due within
  /// [withinDays] days.
  static Future<void> scheduleDueSoon({int withinDays = 14}) async {
    if (!_ready) return;
    try {
      final all = await TransactionsRepository().getAll();
      final now = DateTime.now();
      final limit = now.add(Duration(days: withinDays));
      final due = all.where((t) {
        if (!t.isRecurring || t.nextDue <= 0) return false;
        final d = DateTime.fromMillisecondsSinceEpoch(t.nextDue);
        return !d.isBefore(now) && !d.isAfter(limit);
      });
      for (final t in due) {
        await _scheduleOne(t);
      }
    } catch (_) {}
  }

  static Future<void> _scheduleOne(AppTransaction t) async {
    final when = DateTime.fromMillisecondsSinceEpoch(t.nextDue);
    final scheduled = tz.TZDateTime.from(
      DateTime(when.year, when.month, when.day, 9, 0),
      tz.local,
    );
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: t.id ?? 0,
      title: 'Due: ${t.category.isEmpty ? t.kind : t.category}',
      body: '${_label(t.recurrence)} · ${formatMoney(t.amount)}',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'qalqul_reminders',
          'Reminders',
          channelDescription: 'Recurring payment reminders',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static String _label(String r) => switch (r) {
        'daily' => 'Daily',
        'weekly' => 'Weekly',
        'monthly' => 'Monthly',
        _ => r,
      };
}
