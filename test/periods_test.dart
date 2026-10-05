import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/core/utils/periods.dart' as p;

void main() {
  group('monthWindow', () {
    test('spans the current month', () {
      final w = p.monthWindow(DateTime(2026, 3, 17));
      expect(DateTime.fromMillisecondsSinceEpoch(w.start), DateTime(2026, 3, 1));
      expect(DateTime.fromMillisecondsSinceEpoch(w.end), DateTime(2026, 4, 1));
    });

    test('offsets backwards into the previous month', () {
      final w = p.monthWindow(DateTime(2026, 3, 31), offset: -1);
      expect(DateTime.fromMillisecondsSinceEpoch(w.start), DateTime(2026, 2, 1));
      expect(DateTime.fromMillisecondsSinceEpoch(w.end), DateTime(2026, 3, 1));
    });

    test('offsets forwards across a year boundary', () {
      final w = p.monthWindow(DateTime(2026, 12, 5), offset: 1);
      expect(DateTime.fromMillisecondsSinceEpoch(w.start), DateTime(2027, 1, 1));
      expect(DateTime.fromMillisecondsSinceEpoch(w.end), DateTime(2027, 2, 1));
    });

    test('is half-open at both ends', () {
      final w = p.monthWindow(DateTime(2026, 3, 17));
      expect(p.within(DateTime(2026, 3, 1).millisecondsSinceEpoch, w), isTrue);
      expect(p.within(DateTime(2026, 3, 31, 23, 59).millisecondsSinceEpoch, w),
          isTrue);
      expect(p.within(DateTime(2026, 4, 1).millisecondsSinceEpoch, w), isFalse);
      expect(p.within(DateTime(2026, 2, 28).millisecondsSinceEpoch, w), isFalse);
    });
  });

  group('dayWindow', () {
    test('starts at midnight today and spans [days]', () {
      final w = p.dayWindow(DateTime(2026, 3, 17, 14, 30), days: 7);
      expect(DateTime.fromMillisecondsSinceEpoch(w.start), DateTime(2026, 3, 17));
      expect(DateTime.fromMillisecondsSinceEpoch(w.end), DateTime(2026, 3, 24));
    });

    test('default is a week', () {
      final w = p.dayWindow(DateTime(2026, 3, 17));
      expect(w.end - w.start, const Duration(days: 7).inMilliseconds);
    });
  });

  group('daysBetween', () {
    test('counts whole days ignoring time of day', () {
      expect(p.daysBetween(DateTime(2026, 3, 17), DateTime(2026, 3, 20)), 3);
      expect(p.daysBetween(DateTime(2026, 3, 17, 23), DateTime(2026, 3, 18, 1)),
          1);
    });

    test('is negative when overdue', () {
      expect(p.daysBetween(DateTime(2026, 3, 20), DateTime(2026, 3, 17)), -3);
    });

    test('is zero on the same day', () {
      expect(p.daysBetween(DateTime(2026, 3, 17, 1), DateTime(2026, 3, 17, 23)),
          0);
    });
  });
}