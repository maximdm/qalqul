import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/features/finance/transactions_repository.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules local notifications for recurring transactions that are due soon.
///
/// Best-effort: any failure (unsupported platform, missing permission) is
/// swallowed so the app never crashes because of notifications.
class ReminderService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  /// Localized strings for the notification copy. Seeded from the device
  /// locale in [init] and replaced by [configure] once the app has resolved
  /// its own locale, so reminders follow the in-app language choice.
  static L10n? _l10n;

  /// Supplies the app's resolved localizations and reschedules, so pending
  /// notifications pick up a locale change.
  static Future<void> configure(L10n l10n) async {
    if (_l10n == l10n) return;
    _l10n = l10n;
    await cancelAll();
    await scheduleDueSoon();
  }

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
      // Best available guess at the language before the app has resolved its
      // own locale; `configure` overrides it from the widget tree.
      _l10n ??= await L10n.delegate.load(
        PlatformDispatcher.instance.locale,
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Drops every pending reminder, so a locale change can reschedule them.
  static Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
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
    final l10n = _l10n;
    if (l10n == null) return;
    final when = DateTime.fromMillisecondsSinceEpoch(t.nextDue);
    final scheduled = tz.TZDateTime.from(
      DateTime(when.year, when.month, when.day, 9, 0),
      tz.local,
    );
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;
    await _plugin.zonedSchedule(
      id: t.id ?? 0,
      title: l10n.reminderDue(
        t.category.isEmpty ? _kindLabel(l10n, t.kind) : t.category,
      ),
      body: l10n.reminderBody(
        _recurrenceLabel(l10n, t.recurrence),
        formatMoney(t.amount, currency: t.currency),
      ),
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'qalqul_reminders',
          l10n.reminderChannelName,
          channelDescription: l10n.reminderChannelDescription,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static String _kindLabel(L10n l10n, String kind) =>
      kind == 'credit' ? l10n.financeTabCredit : l10n.financeTabSpending;

  static String _recurrenceLabel(L10n l10n, String r) => switch (r) {
        'daily' => l10n.txRepeatDaily,
        'weekly' => l10n.txRepeatWeekly,
        'monthly' => l10n.txRepeatMonthly,
        _ => r,
      };
}
