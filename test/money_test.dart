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
      final same = rates.convert(10, 'USD', 'usd');
      expect(same.amount, 10);
      expect(same.currency, 'USD');
      expect(same.converted, isTrue);
    });

    test('converts along the direct pair', () {
      final result = rates.convert(100, 'USD', 'EUR');
      expect(result.amount, 50);
      expect(result.currency, 'EUR');
      expect(result.converted, isTrue);
      expect(result.format(), '€50.00');
    });

    test('pivots through a shared currency when no direct pair exists', () {
      // 10 EUR -> 5 USD -> 1.25 GBP, using the USD/EUR and USD/GBP rates.
      final result = rates.convert(10, 'EUR', 'GBP');
      expect(result.converted, isTrue);
      expect(result.amount, closeTo(1.25, 1e-9));
      expect(result.currency, 'GBP');
    });

    test('prefers the requested pivot currency', () {
      final viaUsd = rates.convert(10, 'EUR', 'GBP', via: 'USD');
      final auto = rates.convert(10, 'EUR', 'GBP');
      expect(viaUsd.amount, closeTo(auto.amount, 1e-9));
    });

    test('falls back to the original amount when no path exists', () {
      final sparse = FxRates.fromList(const [
        FxRate(base: 'USD', quote: 'EUR', rate: 0.5, asOf: 0),
      ]);
      final result = sparse.convert(100, 'JPY', 'CHF');
      expect(result.converted, isFalse);
      expect(result.amount, 100);
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
      expect(() => rates.convert(1, 'USD', 'EUR'), returnsNormally);
    });
  });
}