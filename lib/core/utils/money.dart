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
  /// Tries the direct pair first, then a single pivot (ideally [via]) so two
  /// stored rates such as `USD/EUR` and `USD/GBP` can produce `EUR/GBP`.
  /// Returns the original amount with `converted: false` when no path exists.
  MoneyAmount convert(
    double amount,
    String from,
    String to, {
    String? via,
  }) {
    final f = from.toUpperCase();
    final t = to.toUpperCase();
    if (f == t) return MoneyAmount(amount, t);

    final directRate = direct(f, t);
    if (directRate != null) {
      return MoneyAmount(amount * directRate, t);
    }

    // Pivot through a shared currency: from → pivot → to.
    final pivots = <String>[
      if (via != null) via.toUpperCase(),
      ..._currenciesIn(f),
    ];
    for (final pivot in pivots.toSet()) {
      if (pivot == f || pivot == t) continue;
      final leg1 = direct(f, pivot);
      final leg2 = direct(pivot, t);
      if (leg1 != null && leg2 != null) {
        return MoneyAmount(amount / leg1 * leg2, t);
      }
    }

    return MoneyAmount(amount, f, converted: false);
  }

  Iterable<String> _currenciesIn(String code) sync* {
    final prefix = '$code/';
    for (final pair in _byPair.keys) {
      if (pair.startsWith(prefix)) yield pair.substring(prefix.length);
    }
  }
}