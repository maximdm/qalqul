import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/core/db/database_helper.dart';
import 'package:qalqul/core/models/fx_rate.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/features/finance/currency_provider.dart';
import 'package:qalqul/features/finance/fx_rates_repository.dart';
import 'package:qalqul/features/settings/settings_repository.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

void main() {
  setUpAll(() async {
    await DatabaseHelper.useTestDatabase();
  });

  tearDown(() async {
    final db = await DatabaseHelper.instance.database;
    for (final t in ['fx_rates', 'app_settings']) {
      await db.delete(t);
    }
  });

  /// Seeds `app_settings` / `fx_rates`, then builds a container and lets the
  /// notifiers finish their initial load.
  Future<ProviderContainer> container({
    Map<String, String> settings = const {},
    List<FxRate> rates = const [],
  }) async {
    final settingsRepo = SettingsRepository();
    for (final e in settings.entries) {
      await settingsRepo.set(e.key, e.value);
    }
    final fxRepo = FxRatesRepository();
    for (final r in rates) {
      await fxRepo.upsert(r);
    }

    final c = ProviderContainer();
    addTearDown(c.dispose);
    // Both notifiers kick off an async sqflite read in `build()`; warm them up
    // and wait for those reads to land before asserting.
    c.read(settingsProvider);
    c.read(fxRatesProvider);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return c;
  }

  group('baseCurrencyProvider', () {
    test('defaults to USD with no stored setting', () async {
      final c = await container();
      expect(c.read(baseCurrencyProvider), defaultCurrency);
    });

    test('reads the stored code', () async {
      final c = await container(settings: {SettingKeys.baseCurrency: 'GBP'});
      expect(c.read(baseCurrencyProvider), 'GBP');
    });

    test('falls back to USD for unsupported codes', () async {
      final c = await container(settings: {SettingKeys.baseCurrency: 'XYZ'});
      expect(c.read(baseCurrencyProvider), defaultCurrency);
    });
  });

  group('localeProvider', () {
    test('null follows the system locale', () async {
      final c = await container();
      expect(c.read(localeProvider), isNull);
    });

    test('parses a language-only code', () async {
      final c = await container(settings: {SettingKeys.locale: 'es'});
      expect(c.read(localeProvider)?.languageCode, 'es');
    });

    test('parses a region suffix', () async {
      final c = await container(settings: {SettingKeys.locale: 'pt-BR'});
      expect(c.read(localeProvider)?.languageCode, 'pt');
      expect(c.read(localeProvider)?.countryCode, 'BR');
    });
  });

  group('fxTableProvider', () {
    test('is empty when nothing is stored', () async {
      final c = await container();
      expect(c.read(fxTableProvider).isEmpty, isTrue);
    });

    test('exposes stored rates after the initial load', () async {
      final c = await container(rates: const [
        FxRate(base: 'USD', quote: 'EUR', rate: 0.5, asOf: 1),
      ]);
      expect(c.read(fxTableProvider).direct('USD', 'EUR'), 0.5);
    });
  });

  group('convertWith', () {
    final usdTable = FxRates.fromList(const [
      FxRate(base: 'USD', quote: 'EUR', rate: 0.5, asOf: 1),
    ]);

    test('converts into the base currency', () {
      final result = convertWith((base: 'USD', rates: usdTable), 10,
          from: 'EUR');
      expect(result.converted, isTrue);
      expect(result.amount, 20);
      expect(result.currency, 'USD');
    });

    test('defaults the source to the base currency', () {
      final result = convertWith((base: 'EUR', rates: usdTable), 5);
      expect(result.amount, 5);
      expect(result.converted, isTrue);
    });

    test('reports unconverted instead of guessing', () {
      final result =
          convertWith((base: 'JPY', rates: FxRates.empty), 100, from: 'GBP');
      expect(result.converted, isFalse);
      expect(result.amount, 100);
      expect(result.currency, 'GBP');
    });

    test('is a no-op when the base has no rate path back', () {
      final currency = (base: 'ZWL', rates: FxRates.empty);
      expect(convertWith(currency, 42, from: 'USD').amount, 42);
    });
  });

  group('FxRatesNotifier', () {
    test('ignores self-pairs and non-positive rates', () async {
      final c = await container();
      final notifier = c.read(fxRatesProvider.notifier);
      await notifier.upsert(base: 'USD', quote: 'USD', rate: 1);
      await notifier.upsert(base: 'USD', quote: 'EUR', rate: 0);
      expect(c.read(fxRatesProvider), isEmpty);
    });

    test('persists a valid rate, upper-casing codes', () async {
      final c = await container();
      await c
          .read(fxRatesProvider.notifier)
          .upsert(base: 'usd', quote: 'jpy', rate: 150);
      final rates = c.read(fxRatesProvider);
      expect(rates, hasLength(1));
      expect(rates.first.base, 'USD');
      expect(rates.first.quote, 'JPY');
      expect(rates.first.rate, 150);
    });

    test('upsert replaces the rate for an existing pair', () async {
      final c = await container();
      final notifier = c.read(fxRatesProvider.notifier);
      await notifier.upsert(base: 'USD', quote: 'GBP', rate: 0.8);
      await notifier.upsert(base: 'USD', quote: 'GBP', rate: 0.79);
      final rates = c.read(fxRatesProvider);
      expect(rates, hasLength(1));
      expect(rates.first.rate, 0.79);
    });

    test('delete removes the rate', () async {
      final c = await container();
      final notifier = c.read(fxRatesProvider.notifier);
      await notifier.upsert(base: 'USD', quote: 'CHF', rate: 0.9);
      await notifier.delete(c.read(fxRatesProvider).first.id!);
      expect(c.read(fxRatesProvider), isEmpty);
      expect(c.read(fxTableProvider).isEmpty, isTrue);
    });
  });
}
