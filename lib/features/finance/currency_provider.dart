import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalqul/core/models/fx_rate.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/features/finance/fx_rates_repository.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

final fxRatesProvider =
    AsyncNotifierProvider<FxRatesNotifier, List<FxRate>>(FxRatesNotifier.new);

/// Stored exchange rates, loaded in `build()`.
///
/// Async because the derived rate table is what every money figure on the
/// dashboard depends on: with a synchronous empty list, the first frame
/// rendered every total as unconverted before the rates landed.
class FxRatesNotifier extends AsyncNotifier<List<FxRate>> {
  final _repo = FxRatesRepository();

  @override
  Future<List<FxRate>> build() => _repo.getAll();

  /// Re-reads the table without passing through a loading state, so saving a
  /// rate does not blank the form that saved it.
  Future<void> _reload() async {
    final rates = await _repo.getAll();
    if (!ref.mounted) return;
    state = AsyncData(rates);
  }

  Future<void> upsert({
    required String base,
    required String quote,
    required double rate,
    int? asOf,
  }) async {
    if (base.toUpperCase() == quote.toUpperCase() || rate <= 0) return;
    await _repo.upsert(FxRate(
      base: base,
      quote: quote,
      rate: rate,
      asOf: asOf ?? DateTime.now().millisecondsSinceEpoch,
    ));
    await _reload();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _reload();
  }
}

/// The active rate table, rebuilt from [fxRatesProvider] whenever it changes.
///
/// Deliberately synchronous. It feeds [currencyProvider], which every money
/// widget reads on each build, so threading an `AsyncValue` through it would
/// spread a loading state into every figure on screen. While the rates load the
/// table is empty, which means a multi-currency total briefly reports its
/// amounts as unconverted rather than showing a confidently wrong number.
final fxTableProvider = Provider<FxRates>((ref) {
  final rates = ref.watch(fxRatesProvider);
  return FxRates.fromList(rates.value ?? const []);
});

/// Display currency plus the rates used to reach it.
final currencyProvider = Provider<({String base, FxRates rates})>((ref) {
  final base = ref.watch(baseCurrencyProvider);
  final rates = ref.watch(fxTableProvider);
  return (base: base, rates: rates);
});

/// Converts [minor] from [from] into the user's base currency.
///
/// Falls back to the unconverted amount when no rate path exists, so totals
/// never silently mix currencies. [from] defaults to the base currency.
int toBase(
  WidgetRef ref,
  int minor, {
  String? from,
}) =>
    convertWith(ref.watch(currencyProvider), minor, from: from).minor;

/// Converts and formats [minor] from [from] for display in the base currency.
///
/// When no rate connects [from] to the base currency the original amount is
/// formatted in its own currency instead of showing a wrong number.
String formatInBase(
  WidgetRef ref,
  int minor, {
  String? from,
  bool compact = false,
}) {
  final currency = ref.watch(currencyProvider);
  final converted = convertWith(currency, minor, from: from);
  final code = converted.converted ? currency.base : converted.currency;
  final amount = converted.converted ? converted.minor : minor;
  return compact
      ? formatMoneyCompact(toDecimal(amount, code), currency: code)
      : formatMoney(toDecimal(amount, code), currency: code);
}

/// Pure conversion entry point (no widget dependency) so logic is testable.
MoneyAmount convertWith(
  ({String base, FxRates rates}) currency,
  int minor, {
  String? from,
}) =>
    currency.rates.convert(
      minor,
      (from ?? currency.base).toUpperCase(),
      currency.base,
      via: currency.base,
    );

/// Combines amounts held in several currencies into the base currency.
///
/// Returns a [MoneyTotal], so a caller can tell a complete total from one that
/// is missing currencies it has no rate for. Use this instead of folding
/// [toBase] over records: adding raw numbers together is only valid when every
/// rate resolves.
MoneyTotal sumInBase(
  WidgetRef ref,
  Iterable<({int minor, String currency})> entries,
) {
  final currency = ref.watch(currencyProvider);
  return currency.rates.sum(entries, currency.base, via: currency.base);
}

/// [sumInBase] over a list of domain records, reading each record's own
/// currency. This is the shape every finance screen needs: sum one field of a
/// list of models, converted per record.
MoneyTotal sumRecords<T>(
  WidgetRef ref,
  Iterable<T> items,
  String Function(T) currencyOf,
  int Function(T) amountOf,
) =>
    sumInBase(
      ref,
      items.map((e) => (minor: amountOf(e), currency: currencyOf(e))),
    );