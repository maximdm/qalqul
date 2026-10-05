/// Calendar-period helpers shared by the finance widgets and screens.
library;

/// Start/end epoch milliseconds for the month [offset] months away from
/// [now] (`0` = this month, `-1` = last month).
///
/// Returns half-open bounds: `start <= ts < end`.
({int start, int end}) monthWindow(DateTime now, {int offset = 0}) {
  final first = DateTime(now.year, now.month + offset, 1);
  final next = DateTime(now.year, now.month + offset + 1, 1);
  return (
    start: first.millisecondsSinceEpoch,
    end: next.millisecondsSinceEpoch,
  );
}

({int start, int end}) dayWindow(DateTime now, {int days = 7}) {
  final start = DateTime(now.year, now.month, now.day);
  return (
    start: start.millisecondsSinceEpoch,
    end: start.add(Duration(days: days)).millisecondsSinceEpoch,
  );
}

bool within(int timestamp, ({int start, int end}) window) =>
    timestamp >= window.start && timestamp < window.end;

/// Whole days from [from] to [to], rounded toward zero (negative when overdue).
int daysBetween(DateTime from, DateTime to) {
  final a = DateTime(from.year, from.month, from.day);
  final b = DateTime(to.year, to.month, to.day);
  return b.difference(a).inDays;
}