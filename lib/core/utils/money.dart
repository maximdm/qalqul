import 'package:intl/intl.dart';

import 'package:qalqul/core/models/fx_rate.dart';

/// ISO-4217 code used when a record predates multi-currency (or is created by
/// code that doesn't specify one).
const String defaultCurrency = 'USD';

/// Formatting metadata for a currency: symbol, fraction digits and label.
class CurrencyInfo {
  final String code;
  final String symbol;
  final int decimals;
  final String label;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.decimals,
    required this.label,
  });
}

/// Currencies the app can display and store amounts in.
const List<CurrencyInfo> supportedCurrencies = [
  CurrencyInfo(code: 'USD', symbol: r'$', decimals: 2, label: 'US Dollar'),
  CurrencyInfo(code: 'EUR', symbol: '€', decimals: 2, label: 'Euro'),
  CurrencyInfo(code: 'GBP', symbol: '£', decimals: 2, label: 'British Pound'),
  CurrencyInfo(code: 'JPY', symbol: '¥', decimals: 0, label: 'Japanese Yen'),
  CurrencyInfo(code: 'CHF', symbol: 'CHF ', decimals: 2, label: 'Swiss Franc'),
  CurrencyInfo(code: 'CAD', symbol: r'C$', decimals: 2, label: 'Canadian Dollar'),
  CurrencyInfo(code: 'AUD', symbol: r'A$', decimals: 2, label: 'Australian Dollar'),
  CurrencyInfo(code: 'INR', symbol: '₹', decimals: 2, label: 'Indian Rupee'),
  CurrencyInfo(code: 'AED', symbol: 'د.إ', decimals: 2, label: 'UAE Dirham'),
  CurrencyInfo(code: 'SAR', symbol: 'ر.س', decimals: 2, label: 'Saudi Riyal'),
];

CurrencyInfo currencyInfo(String code) => supportedCurrencies.firstWhere(
      (c) => c.code == code,
      orElse: () => CurrencyInfo(
        code: code,
        symbol: '$code ',
        decimals: 2,
        label: code,
      ),
    );

bool isSupportedCurrency(String code) =>
    supportedCurrencies.any((c) => c.code == code);

/// Formats [v] in [currency] using `intl`, honouring the currency's fraction
/// digits (e.g. JPY has none).
String formatMoney(double v, {String currency = defaultCurrency}) {
  final info = currencyInfo(currency);
  return NumberFormat.currency(
    symbol: info.symbol,
    decimalDigits: info.decimals,
  ).format(v);
}

/// Compact variant for tight card layouts (`$1.2K`).
String formatMoneyCompact(double v, {String currency = defaultCurrency}) {
  final info = currencyInfo(currency);
  return NumberFormat.compactCurrency(
    symbol: info.symbol,
    decimalDigits: info.decimals == 0 ? 0 : 1,
  ).format(v);
}

/// An amount expressed in [currency].
///
/// [converted] is `false` when the requested conversion could not be resolved
/// with the available rates, in which case [amount] is the untouched original
/// and callers can show it verbatim rather than printing a wrong number.
class MoneyAmount {
  final double amount;
  final String currency;
  final bool converted;

  const MoneyAmount(this.amount, this.currency, {this.converted = true});

  String format() => formatMoney(amount, currency: currency);
}

/// The result of combining amounts that may be held in several currencies.
///
/// [amount] is expressed in [currency] and contains **only** the money that
/// could be converted into it. Anything left out is reported in [unconverted],
/// keyed by its original currency, so a partial total is visible instead of
/// being padded with numbers from other currencies.
class MoneyTotal {
  final double amount;
  final String currency;

  /// Source currency → amount that could not be converted into [currency].
  final Map<String, double> unconverted;

  const MoneyTotal(
    this.amount,
    this.currency, {
    this.unconverted = const {},
  });

  /// `true` when every contributing amount was convertible.
  bool get isComplete => unconverted.isEmpty;

  /// Subtracts [other] — expected to be in the same currency — carrying over
  /// anything either side could not convert.
  MoneyTotal minus(MoneyTotal other) => MoneyTotal(
        amount - other.amount,
        currency,
        unconverted: {...unconverted, ...other.unconverted},
      );

  /// Currencies that are missing from the total, sorted for stable display.
  List<String> get missingCurrencies => unconverted.keys.toList()..sort();

  bool get isEmpty => amount == 0 && unconverted.isEmpty;

  String format() => formatMoney(amount, currency: currency);

  /// Single-line summary of what is missing, for tooltips and subtitles.
  String describeMissing() => missingCurrencies
      .map((code) =>
          '${formatMoney(unconverted[code]!, currency: code)} $code')
      .join(', ');
}

/// Immutable set of manual FX rates with pair lookup and conversion.
class FxRates {
  final Map<String, double> _byPair;

  /// Builds the lookup table from stored rates, normalising codes to upper case.
  factory FxRates.fromList(Iterable<FxRate> rates) {
    final map = <String, double>{};
    for (final r in rates) {
      final base = r.base.toUpperCase();
      final quote = r.quote.toUpperCase();
      if (base == quote || r.rate <= 0) continue;
      map['$base/$quote'] = r.rate;
      map['$quote/$base'] = 1 / r.rate;
    }
    return FxRates._(Map.unmodifiable(map));
  }

  const FxRates._(this._byPair);

  static const empty = FxRates._({});

  bool get isEmpty => _byPair.isEmpty;

  bool get isNotEmpty => _byPair.isNotEmpty;

  /// Direct rate for `from` → `to`, or `null` when the pair isn't known.
  double? direct(String from, String to) {
    final f = from.toUpperCase();
    final t = to.toUpperCase();
    if (f == t) return 1;
    return _byPair['$f/$t'];
  }

  /// Converts [amount] from [from] into [to].
  ///
  /// Uses the direct pair when one is stored, otherwise walks the rate graph to
  /// find the fewest-hops path, so a chain such as `EUR/GBP` + `GBP/JPY` still
  /// reaches `EUR/JPY`. [via] is tried first when supplied.
  /// Returns the original amount with `converted: false` when no path exists.
  MoneyAmount convert(
    double amount,
    String from,
    String to, {
    String? via,
  }) {
    final f = from.toUpperCase();
    final t = to.toUpperCase();
    final rate = _searchRate(f, t, via);
    if (rate == null) return MoneyAmount(amount, f, converted: false);
    return MoneyAmount(amount * rate, t);
  }

  /// Combines amounts held in several currencies into a single figure in [to].
  ///
  /// Anything with no conversion path is left out of the total and reported in
  /// [MoneyTotal.unconverted], keyed by its own currency. A total is therefore
  /// never a sum of mismatched units: either a currency converted, or the gap
  /// is visible.
  MoneyTotal sum(
    Iterable<({double amount, String currency})> entries,
    String to, {
    String? via,
  }) {
    final target = to.toUpperCase();
    var total = 0.0;
    final missing = <String, double>{};
    for (final e in entries) {
      final converted = convert(e.amount, e.currency, target, via: via);
      if (converted.converted) {
        total += converted.amount;
      } else {
        final code = converted.currency;
        missing[code] = (missing[code] ?? 0) + converted.amount;
      }
    }
    return MoneyTotal(total, target, unconverted: Map.unmodifiable(missing));
  }

  /// Bounds the path search. The supported currency set is small, so four legs
  /// is generous; the cap only stops a pathological rate table from costing
  /// more than it is worth.
  static const _maxHops = 4;

  /// Accumulated rate for `from` → `to`, or `null` when unreachable.
  ///
  /// Breadth-first, so the result is the shortest-hop path. Ties break on
  /// insertion order, which keeps the chosen path deterministic; [preferVia] is
  /// queued ahead of everything else so an explicit pivot still wins.
  double? _searchRate(String from, String to, String? preferVia) {
    if (from == to) return 1;
    final direct = _byPair['$from/$to'];
    if (direct != null) return direct;

    // Each entry is (code, rate from `from`, hops used).
    final queue = <(String, double, int)>[];
    final seen = <String>{from};

    void seed(String code) {
      if (code == from || code == to) return;
      final rate = _byPair['$from/$code'];
      if (rate == null || !seen.add(code)) return;
      queue.add((code, rate, 1));
    }

    if (preferVia != null) seed(preferVia.toUpperCase());
    for (final code in _currenciesIn(from)) {
      seed(code);
    }

    for (var head = 0; head < queue.length; head++) {
      final (code, rate, hops) = queue[head];
      if (code == to) return rate;
      if (hops >= _maxHops) continue;
      for (final next in _currenciesIn(code)) {
        final leg = _byPair['$code/$next'];
        if (leg == null || !seen.add(next)) continue;
        queue.add((next, rate * leg, hops + 1));
      }
    }
    return null;
  }

  Iterable<String> _currenciesIn(String code) sync* {
    final prefix = '$code/';
    for (final pair in _byPair.keys) {
      if (pair.startsWith(prefix)) yield pair.substring(prefix.length);
    }
  }
}