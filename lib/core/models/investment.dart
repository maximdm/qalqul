import 'package:qalqul/core/utils/money.dart';

class Investment {
  final int? id;
  final String name;

  /// Cost basis and current market value, in minor units of [currency].
  final int principalMinor;
  final int currentValueMinor;
  final int asOf;
  final String currency;

  const Investment({
    this.id,
    required this.name,
    required this.principalMinor,
    required this.currentValueMinor,
    required this.asOf,
    this.currency = defaultCurrency,
  });

  Investment copyWith({
    int? id,
    String? name,
    int? principalMinor,
    int? currentValueMinor,
    int? asOf,
    String? currency,
  }) {
    return Investment(
      id: id ?? this.id,
      name: name ?? this.name,
      principalMinor: principalMinor ?? this.principalMinor,
      currentValueMinor: currentValueMinor ?? this.currentValueMinor,
      asOf: asOf ?? this.asOf,
      currency: currency ?? this.currency,
    );
  }

  /// Gain in minor units of the holding's own currency.
  int get returnMinor => currentValueMinor - principalMinor;

  /// Percentage gain. Both terms share a currency, so the ratio is exact even
  /// though it is computed in floating point.
  double get returnPct =>
      principalMinor > 0 ? returnMinor / principalMinor * 100 : 0;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'principal_minor': principalMinor,
        'current_value_minor': currentValueMinor,
        'as_of': asOf,
        'currency': currency,
      };

  factory Investment.fromMap(Map<String, Object?> m) => Investment(
        id: m['id'] as int?,
        name: m['name'] as String,
        principalMinor: (m['principal_minor'] as num).toInt(),
        currentValueMinor: (m['current_value_minor'] as num).toInt(),
        asOf: m['as_of'] as int,
        currency: (m['currency'] as String?) ?? defaultCurrency,
      );
}
