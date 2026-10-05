import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/core/models/fx_rate.dart';
import 'package:qalqul/core/utils/money.dart';

void main() {
  group('currency registry', () {
    test('falls back to a synthetic info for unknown codes', () {
      expect(isSupportedCurrency('usd'), isFalse);
      expect(isSupportedCurrency('USD'), isTrue);

      final unknown = currencyInfo('ZWL');
      expect(unknown.code, 'ZWL');
      expect(unknown.symbol, 'ZWL ');
      expect(unknown.decimals, 2);
    });

    test('JPY is registered without fraction digits', () {
      expect(currencyInfo('JPY').decimals, 0);
      expect(currencyInfo('JPY').scale, 1);
      expect(currencyInfo('USD').scale, 100);
    });
  });

  group('formatMoney', () {
    test('defaults to USD', () {
      expect(formatMoney(1234.5), r'$1,234.50');
    });

    test('honours the currency symbol', () {
      expect(formatMoney(10, currency: 'EUR'), '€10.00');
      expect(formatMoney(10, currency: 'GBP'), '£10.00');
    });

    test('drops decimals for zero-decimal currencies', () {
      expect(formatMoney(1234.5, currency: 'JPY'), '¥1,235');
    });

    test('compacts large values for card layouts', () {
      expect(formatMoneyCompact(1500, currency: 'USD'), r'$1.5K');
    });
  });

  group('minor units', () {
    test('scale is 100 for two-decimal currencies and 1 for JPY', () {
      expect(toMinor(1, 'USD'), 100);
      expect(toMinor(1, 'EUR'), 100);
      expect(toMinor(1, 'JPY'), 1);
    });

    test('decimal and minor are inverses', () {
      for (final code in ['USD', 'EUR', 'GBP']) {
        expect(toDecimal(toMinor(12.34, code), code), closeTo(12.34, 1e-9));
      }
      // JPY has no minor unit, so anything finer than a yen is rounded away.
      expect(toMinor(12.34, 'JPY'), 12);
      expect(toDecimal(toMinor(12.34, 'JPY'), 'JPY'), 12.0);
    });
  });

  group('FxRates', () {
    final rates = FxRates.fromList(const [
      FxRate(base: 'USD', quote: 'EUR', rate: 0.5, asOf: 0),
      FxRate(base: 'USD', quote: 'GBP', rate: 0.25, asOf: 0),
    ]);

    test('empty set converts nothing and reports it', () {
      expect(FxRates.empty.isEmpty, isTrue);
      expect(FxRates.empty.isNotEmpty, isFalse);
    });

    test('direct rate is case-insensitive and invertible', () {
      expect(rates.direct('usd', 'eur'), 0.5);
      expect(rates.direct('EUR', 'USD'), 2.0);
      expect(rates.direct('EUR', 'GBP'), isNull);
    });

    test('same currency is a no-op', () {
      final same = rates.convert(1000, 'USD', 'usd');
      expect(same.minor, 1000);
      expect(same.currency, 'USD');
      expect(same.converted, isTrue);
    });

    test('converts along the direct pair', () {
      final result = rates.convert(10000, 'USD', 'EUR');
      expect(result.minor, 5000);
      expect(result.currency, 'EUR');
      expect(result.converted, isTrue);
      expect(result.format(), '€50.00');
    });

    test('pivots through a shared currency when no direct pair exists', () {
      // 10 EUR -> 20 USD -> 5 GBP, using the USD/EUR and USD/GBP rates.
      // Each hop multiplies: EUR/USD is 2.0 and USD/GBP is 0.25, so the
      // composite rate is 0.5. Dividing the first leg would understate the
      // result by leg1^2 (it used to report 1.25 here).
      final result = rates.convert(1000, 'EUR', 'GBP');
      expect(result.converted, isTrue);
      expect(result.minor, 500);
      expect(result.currency, 'GBP');
    });

    test('pivot conversion is symmetric', () {
      expect(rates.convert(1000, 'EUR', 'GBP').minor, 500);
      expect(rates.convert(1000, 'GBP', 'EUR').minor, 2000);
      // Round-tripping a converted amount must return the original.
      final there = rates.convert(1000, 'EUR', 'GBP');
      final back = rates.convert(there.minor, 'GBP', 'EUR');
      expect(back.minor, 1000);
    });

    test('hops through more than one intermediate currency', () {
      // No pair links JPY to EUR except through USD and GBP.
      final chain = FxRates.fromList(const [
        FxRate(base: 'EUR', quote: 'USD', rate: 2.0, asOf: 0),
        FxRate(base: 'USD', quote: 'GBP', rate: 0.5, asOf: 0),
        FxRate(base: 'GBP', quote: 'JPY', rate: 300.0, asOf: 0),
      ]);
      expect(chain.convert(200, 'EUR', 'JPY').minor, 600);
    });

    test('prefers the requested pivot currency', () {
      final viaUsd = rates.convert(1000, 'EUR', 'GBP', via: 'USD');
      final auto = rates.convert(1000, 'EUR', 'GBP');
      expect(viaUsd.minor, auto.minor);
    });

    test('falls back to the original amount when no path exists', () {
      final sparse = FxRates.fromList(const [
        FxRate(base: 'USD', quote: 'EUR', rate: 0.5, asOf: 0),
      ]);
      final result = sparse.convert(100, 'JPY', 'CHF');
      expect(result.converted, isFalse);
      expect(result.minor, 100);
      expect(result.currency, 'JPY');
    });

    test('ignores self-pairs and non-positive rates', () {
      final broken = FxRates.fromList(const [
        FxRate(base: 'USD', quote: 'USD', rate: 1, asOf: 0),
        FxRate(base: 'GBP', quote: 'CHF', rate: 0, asOf: 0),
      ]);
      expect(broken.isEmpty, isTrue);
      expect(broken.direct('USD', 'GBP'), isNull);
    });

    test('is immutable after construction', () {
      expect(() => rates.direct('USD', 'EUR'), returnsNormally);
      expect(() => rates.convert(100, 'USD', 'EUR'), returnsNormally);
    });
  });

  group('FxRates across currency scales', () {
    // The scale is part of the currency, so a conversion between a
    // two-decimal currency and a zero-decimal one must rescale, not just
    // multiply by the rate.
    final toYen = FxRates.fromList(const [
      FxRate(base: 'USD', quote: 'JPY', rate: 150.0, asOf: 0),
    ]);

    test('USD cents become whole yen', () {
      // $100.00 is 10000 cents; at 150 that is ¥15000, i.e. 15000 minor units
      // because JPY has no minor unit. Multiplying cents by the rate instead
      // would give 1500000, a hundredfold too large.
      final result = toYen.convert(10000, 'USD', 'JPY');
      expect(result.minor, 15000);
      expect(result.currency, 'JPY');
      expect(result.decimal, 15000.0);
    });

    test('whole yen become USD cents', () {
      final result = toYen.convert(15000, 'JPY', 'USD');
      expect(result.minor, 10000);
      expect(result.decimal, 100.0);
    });

    test('a round trip through yen returns the original cents', () {
      final there = toYen.convert(10000, 'USD', 'JPY');
      expect(toYen.convert(there.minor, 'JPY', 'USD').minor, 10000);
    });

    test('rounds once, at the end', () {
      // $0.05 at 149.5 is ¥7.475, which has no exact minor representation.
      final lossy = FxRates.fromList(const [
        FxRate(base: 'USD', quote: 'JPY', rate: 149.5, asOf: 0),
      ]);
      expect(lossy.convert(5, 'USD', 'JPY').minor, 7);
    });
  });

  group('FxRates.sum', () {
    final rates = FxRates.fromList(const [
      FxRate(base: 'USD', quote: 'EUR', rate: 0.5, asOf: 0),
      FxRate(base: 'USD', quote: 'GBP', rate: 0.25, asOf: 0),
    ]);

    test('adds same-currency entries without touching the scale', () {
      final total = rates.sum(
        const [(minor: 1000, currency: 'EUR'), (minor: 250, currency: 'EUR')],
        'EUR',
      );
      expect(total.minor, 1250);
      expect(total.unconverted, isEmpty);
      expect(total.isComplete, isTrue);
    });

    test('accumulates exactly, with no float drift over many entries', () {
      // Ten one-cent entries must total ten cents, not 9.999999999998.
      final total = rates.sum(
        List.generate(10, (_) => (minor: 1, currency: 'USD')),
        'USD',
      );
      expect(total.minor, 10);
      expect(total.decimal, 0.1);
    });

    test('converts each entry out of its own currency', () {
      // $100 + €50 at 0.5 = €100.00.
      final total = rates.sum(
        const [(minor: 10000, currency: 'USD'), (minor: 5000, currency: 'EUR')],
        'EUR',
      );
      expect(total.minor, 10000);
      expect(total.currency, 'EUR');
    });

    test('reports what it could not convert instead of adding it raw', () {
      final total = rates.sum(
        const [(minor: 10000, currency: 'USD'), (minor: 700, currency: 'CHF')],
        'EUR',
      );
      // The CHF entry stays out of the total, in its own minor units.
      expect(total.minor, 5000);
      expect(total.isComplete, isFalse);
      expect(total.unconverted, {'CHF': 700});
    });

    test('an empty set totals zero and is complete', () {
      final total = rates.sum(const [], 'USD');
      expect(total.minor, 0);
      expect(total.isComplete, isTrue);
    });
  });
}
