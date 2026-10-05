import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalqul/core/models/fx_rate.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/features/finance/fx_rates_repository.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

final fxRatesProvider =
    NotifierProvider<FxRatesNotifier, List<FxRate>>(FxRatesNotifier.new);

class FxRatesNotifier extends Notifier<List<FxRate>> {
  final _repo = FxRatesRepository();

  @override
  List<FxRate> build() {
    _load();
    return const [];
  }

  Future<void> _load() async {
    final rates = await _repo.getAll();
    if (!ref.mounted) return;
    state = rates;
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
    await _load();
  }

  Future<void> delete(int id) async {
    await _repo.delete(id);
    await _load();
  }
}

/// The active rate table, rebuilt from [fxRatesProvider] whenever it changes.
final fxTableProvider = Provider<FxRates>((ref) {
  final rates = ref.watch(fxRatesProvider);
  return FxRates.fromList(rates);
});

/// Display currency plus the rates used to reach it.
final currencyProvider = Provider<({String base, FxRates rates})>((ref) {
  final base = ref.watch(baseCurrencyProvider);
  final rates = ref.watch(fxTableProvider);
  return (base: base, rates: rates);
});

/// Converts [amount] from [from] into the user's base currency.
///
/// Falls back to the unconverted amount when no rate path exists, so totals
/// never silently mix currencies. [from] defaults to the base currency.
double toBase(
  WidgetRef ref,
  double amount, {
  String? from,
}) =>
    convertWith(ref.watch(currencyProvider), amount, from: from).amount;

/// Converts and formats [amount] from [from] for display in the base currency.
///
/// When no rate connects [from] to the base currency the original amount is
/// formatted in its own currency instead of showing a wrong number.
String formatInBase(
  WidgetRef ref,
  double amount, {
  String? from,
  bool compact = false,
}) {
  final currency = ref.watch(currencyProvider);
  final converted = convertWith(currency, amount, from: from);
  if (!converted.converted) {
    return compact
        ? formatMoneyCompact(amount, currency: converted.currency)
        : formatMoney(amount, currency: converted.currency);
  }
  return compact
      ? formatMoneyCompact(converted.amount, currency: converted.currency)
      : formatMoney(converted.amount, currency: converted.currency);
}

/// Pure conversion entry point (no widget dependency) so logic is testable.
MoneyAmount convertWith(
  ({String base, FxRates rates}) currency,
  double amount, {
  String? from,
}) =>
    currency.rates.convert(
      amount,
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
  Iterable<({double amount, String currency})> entries,
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
  double Function(T) amountOf,
) =>
    sumInBase(
      ref,
      items.map((e) => (amount: amountOf(e), currency: currencyOf(e))),
    );