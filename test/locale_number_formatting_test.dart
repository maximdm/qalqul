import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:qalqul/app.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

import 'helpers/fake_data.dart';
import 'helpers/fake_settings.dart';

/// `intl` resolves every locale-less formatter through `Intl.defaultLocale`,
/// which it otherwise takes from the operating system. Setting the app locale
/// there is what keeps the numbers and dates matching the chosen language.
void main() {
  tearDown(() => Intl.defaultLocale = null);

  group('useNumberLocale', () {
    test('money follows the language tag, not the OS', () {
      useNumberLocale('es');
      expect(formatMoney(1234567.89, currency: 'EUR'), '1.234.567,89\xa0€');

      useNumberLocale('en');
      expect(formatMoney(1234567.89, currency: 'EUR'), '€1,234,567.89');
    });

    test('grouping and decimal separators swap together', () {
      useNumberLocale('es');
      final spanish = formatMoney(1234.5, currency: 'USD');
      expect(spanish, contains('.'));
      expect(spanish, contains(','));

      useNumberLocale('en');
      final english = formatMoney(1234.5, currency: 'USD');
      expect(english, contains(','));
      expect(english, contains('.'));
    });

    test('compact currency follows the locale too', () {
      useNumberLocale('es');
      expect(formatMoneyCompact(1234567, currency: 'EUR'),
          isNot(contains('1,234,567')));
    });

    test('currency fraction digits still win over the locale', () {
      useNumberLocale('en');
      // JPY has no minor units; that must survive a locale switch.
      expect(formatMoney(1500, currency: 'JPY'), contains('1,500'));
      expect(formatMoney(1500, currency: 'JPY'), isNot(contains('.')));

      useNumberLocale('es');
      expect(formatMoney(1500, currency: 'JPY'), isNot(contains('.00')));
    });

    test('an unsupported currency still formats rather than throwing', () {
      useNumberLocale('es');
      expect(formatMoney(10, currency: 'ZZZ'), contains('10'));
    });
  });

  // Date formatting needs `DateFormat`'s locale data, which
  // `GlobalMaterialLocalizations` loads as a side effect. Without a real
  // MaterialApp under `L10n.localizationsDelegates` the lookup throws
  // LocaleDataException, so these have to be widget tests.
  group('dates follow the app locale', () {
    Future<void> boot(WidgetTester tester, String tag) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: Locale(tag),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: const SizedBox.shrink(),
        ),
      );
      await tester.pumpAndSettle();
      useNumberLocale(tag);
    }

    testWidgets('en formats dates month-first', (tester) async {
      await boot(tester, 'en');
      expect(DateFormat.yMMMd().format(DateTime(2026, 3, 4)),
          'Mar 4, 2026');
    });

    testWidgets('es formats the same date day-first', (tester) async {
      await boot(tester, 'es');
      final formatted = DateFormat.yMMMd().format(DateTime(2026, 3, 4));
      expect(formatted, '4 mar 2026');
      expect(formatted, isNot(contains('Mar')));
    });
  });

  // The helper alone is not the fix; `QalqulApp` has to call it. Without this
  // the app happily localises its strings while every number stays in the
  // operating system's format.
  group('QalqulApp wires the number locale', () {
    Future<void> bootApp(WidgetTester tester, String language) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...emptyDataProviders(),
            settingsProvider.overrideWith(
              () => FakeSettings({
                SettingKeys.onboardingDone: 'true',
                SettingKeys.locale: language,
              }),
            ),
            settingsReadyProvider.overrideWith(_Ready.new),
          ],
          child: const QalqulApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a Spanish install formats money in Spanish', (tester) async {
      await bootApp(tester, 'es');

      expect(Intl.defaultLocale, 'es');
      expect(formatMoney(1234567.89, currency: 'EUR'), '1.234.567,89\xa0€');
    });

    testWidgets('an English install formats money in English', (tester) async {
      await bootApp(tester, 'en');

      expect(Intl.defaultLocale, 'en');
      expect(formatMoney(1234567.89, currency: 'EUR'), '€1,234,567.89');
    });
  });
}

/// Mirrors the app's own splash gate: settings are already loaded.
class _Ready extends SettingsReady {
  @override
  bool build() => true;
}
