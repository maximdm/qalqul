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

  /// Minor units per major unit: 100 for USD, 1 for JPY.
  int get scale => _scaleFor(decimals);

  static int _scaleFor(int decimals) {
    var s = 1;
    for (var i = 0; i < decimals; i++) {
      s *= 10;
    }
    return s;
  }
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

/// Converts a decimal amount into integer minor units for [currency].
///
/// Money is stored and added as integers: `0.1 + 0.2` is `0.30000000000000004`
/// in binary floating point, and a net-worth total that subtracts credit from
/// assets compounds that error every time it is recomputed. Converting once, at
/// the edge, keeps every stored figure exact.
int toMinor(double amount, String currency) =>
    (amount * currencyInfo(currency).scale).round();

/// Converts integer minor units back to a decimal amount.
///
/// Only for the display boundary — charts, percentages, text fields. Arithmetic
/// on money should stay in minor units.
double toDecimal(int minor, String currency) =>
    minor / currencyInfo(currency).scale;

/// Parses a money amount typed by the user into minor units of [currency].
///
/// Returns `null` when the text isn't a number, letting callers keep their own
/// "invalid input" message. A comma is accepted as the decimal separator because
/// that is what a Spanish or German keyboard produces, and the app ships a
/// Spanish translation.
///
/// The digits are scaled with integer arithmetic rather than by multiplying a
/// double: `8.115 * 100` is `811.4999999999999` in binary floating point, which
/// would silently round a typed `8.115` down to `$8.11` instead of `$8.12`.
int? parseMinor(String text, String currency) {
  final match =
      RegExp(r'^([+-]?)([0-9]*)(?:\.([0-9]*))?$').firstMatch(_normalise(text));
  if (match == null) return null;
  final whole = match.group(2) ?? '';
  final fraction = match.group(3) ?? '';
  if (whole.isEmpty && fraction.isEmpty) return null;

  try {
    final digits = '$whole$fraction';
    var minor = int.parse(digits.isEmpty ? '0' : digits);
    final wanted = currencyInfo(currency).decimals;
    if (fraction.length < wanted) {
      minor *= _pow10(wanted - fraction.length);
    } else if (fraction.length > wanted) {
      // Drop the excess digits, rounding half up rather than truncating.
      final divisor = _pow10(fraction.length - wanted);
      final remainder = minor % divisor;
      minor = minor ~/ divisor + (remainder * 2 >= divisor ? 1 : 0);
    }
    return match.group(1) == '-' ? -minor : minor;
  } on FormatException {
    // Absurdly long input; the double path is good enough to reject it.
    final value = double.tryParse(_normalise(text));
    return value == null ? null : toMinor(value, currency);
  }
}

/// Normalises a money input for [parseMinor]: trimmed, with any thousands
/// separators and a comma decimal point resolved.
String _normalise(String text) {
  var s = text.trim().replaceAll(',', '.');
  if (s.contains('.')) {
    // Keep only the last dot as the decimal point, so "1.234,56" style input
    // still parses when the separators arrive in the other order.
    final first = s.indexOf('.');
    s = '${s.substring(0, first).replaceAll('.', '')}'
        '${s.substring(first)}';
  }
  return s;
}

int _pow10(int exponent) {
  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}

/// Renders minor units for an editable text field, without trailing zeros.
///
/// The inverse of [parseMinor]: `$12.50` in, `$12.5` out, rather than the
/// `$12.5` that a raw `toString()` on the double would leave behind.
String minorToEditable(int minor, String currency) {
  final info = currencyInfo(currency);
  if (info.decimals == 0) return minor.toString();
  final text = toDecimal(minor, currency).toStringAsFixed(info.decimals);
  if (!text.contains('.')) return text;
  return text
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

/// Points `intl`'s formatters at [languageTag] (e.g. `es`, `en`).
///
/// Every formatter in the app is built without an explicit locale, so they all
/// resolve through `Intl.defaultLocale`, which `intl` otherwise initialises
/// from the *operating system* language. That leaves a Spanish UI full of
/// `1,234,567.89` and `Mar 4, 2026` on an English machine. Call this whenever
/// the app locale changes, before anything formats.
///
/// Takes a bare language tag rather than a `Locale` to keep this file free of
/// Flutter imports and unit-testable without a binding.
void useNumberLocale(String languageTag) {
  Intl.defaultLocale = languageTag;
}

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

/// An amount held in [currency], as integer minor units.
///
/// [converted] is `false` when the requested conversion could not be resolved
/// with the available rates, in which case [minor] is the untouched original
/// and callers can show it verbatim rather than printing a wrong number.
class MoneyAmount {
  final int minor;
  final String currency;
  final bool converted;

  const MoneyAmount(this.minor, this.currency, {this.converted = true});

  /// Major units, for display and chart geometry only.
  double get decimal => toDecimal(minor, currency);

  String format() => formatMoney(decimal, currency: currency);
}

/// The result of combining amounts that may be held in several currencies.
///
/// [minor] is in [currency] and contains **only** the money that could be
/// converted into it. Anything left out is reported in [unconverted], keyed by
/// its original currency and held in that currency's own minor units, so a
/// partial total is visible instead of being padded with numbers from other
/// currencies.
class MoneyTotal {
  final int minor;
  final String currency;

  /// Source currency → amount that could not be converted into [currency].
  final Map<String, int> unconverted;

  const MoneyTotal(
    this.minor,
    this.currency, {
    this.unconverted = const {},
  });

  /// Major units, for display only.
  double get decimal => toDecimal(minor, currency);

  /// `true` when every contributing amount was convertible.
  bool get isComplete => unconverted.isEmpty;

  /// Subtracts [other] — expected to be in the same currency — carrying over
  /// anything either side could not convert.
  MoneyTotal minus(MoneyTotal other) => MoneyTotal(
        minor - other.minor,
        currency,
        unconverted: {...unconverted, ...other.unconverted},
      );

  /// Currencies that are missing from the total, sorted for stable display.
  List<String> get missingCurrencies => unconverted.keys.toList()..sort();

  bool get isEmpty => minor == 0 && unconverted.isEmpty;

  String format() => formatMoney(decimal, currency: currency);

  /// Single-line summary of what is missing, for tooltips and subtitles.
  String describeMissing() => missingCurrencies
      .map((code) =>
          '${formatMoney(toDecimal(unconverted[code]!, code), currency: code)} $code')
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

  /// Converts [minor] from [from] into [to], both in their own minor units.
  ///
  /// Uses the direct pair when one is stored, otherwise walks the rate graph to
  /// find the fewest-hops path, so a chain such as `EUR/GBP` + `GBP/JPY` still
  /// reaches `EUR/JPY`. [via] is tried first when supplied.
  ///
  /// Returns the original amount with `converted: false` when no path exists.
  /// The result is rounded once, at the end, because an FX rate is only ever an
  /// approximation and the target currency has a coarser grid than the source.
  MoneyAmount convert(
    int minor,
    String from,
    String to, {
    String? via,
  }) {
    final f = from.toUpperCase();
    final t = to.toUpperCase();
    final rate = _searchRate(f, t, via);
    if (rate == null) return MoneyAmount(minor, f, converted: false);
    if (f == t) return MoneyAmount(minor, t);
    final major = toDecimal(minor, f) * rate;
    return MoneyAmount(toMinor(major, t), t);
  }

  /// Combines amounts held in several currencies into a single figure in [to].
  ///
  /// Anything with no conversion path is left out of the total and reported in
  /// [MoneyTotal.unconverted], keyed by its own currency. A total is therefore
  /// never a sum of mismatched units: either a currency converted, or the gap
  /// is visible. The running total is an integer, so no rounding error
  /// accumulates however many records are added.
  MoneyTotal sum(
    Iterable<({int minor, String currency})> entries,
    String to, {
    String? via,
  }) {
    final target = to.toUpperCase();
    var total = 0;
    final missing = <String, int>{};
    for (final e in entries) {
      final converted = convert(e.minor, e.currency, target, via: via);
      if (converted.converted) {
        total += converted.minor;
      } else {
        final code = converted.currency;
        missing[code] = (missing[code] ?? 0) + converted.minor;
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