/// A manually entered exchange rate: `1 [base]` buys `[rate] [quote]`.
class FxRate {
  final int? id;
  final String base;
  final String quote;
  final double rate;
  final int asOf;

  const FxRate({
    this.id,
    required this.base,
    required this.quote,
    required this.rate,
    required this.asOf,
  });

  /// Currency pair key used for de-duplication and lookups (`USD/EUR`).
  String get pair => '$base/$quote';

  FxRate copyWith({
    int? id,
    String? base,
    String? quote,
    double? rate,
    int? asOf,
  }) {
    return FxRate(
      id: id ?? this.id,
      base: base ?? this.base,
      quote: quote ?? this.quote,
      rate: rate ?? this.rate,
      asOf: asOf ?? this.asOf,
    );
  }

  /// The inverse rate `1 [quote]` buys `[rate] [base]`, or `null` when [rate] is
  /// zero (which would make the conversion undefined).
  FxRate? get inverse {
    if (rate == 0) return null;
    return FxRate(id: id, base: quote, quote: base, rate: 1 / rate, asOf: asOf);
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'base': base,
        'quote': quote,
        'rate': rate,
        'as_of': asOf,
      };

  factory FxRate.fromMap(Map<String, Object?> m) => FxRate(
        id: m['id'] as int?,
        base: m['base'] as String,
        quote: m['quote'] as String,
        rate: (m['rate'] as num).toDouble(),
        asOf: m['as_of'] as int,
      );
}