import 'package:qalqul/core/utils/money.dart';

class Investment {
  final int? id;
  final String name;
  final double principal;
  final double currentValue;
  final int asOf;
  final String currency;

  const Investment({
    this.id,
    required this.name,
    required this.principal,
    required this.currentValue,
    required this.asOf,
    this.currency = defaultCurrency,
  });

  Investment copyWith({
    int? id,
    String? name,
    double? principal,
    double? currentValue,
    int? asOf,
    String? currency,
  }) {
    return Investment(
      id: id ?? this.id,
      name: name ?? this.name,
      principal: principal ?? this.principal,
      currentValue: currentValue ?? this.currentValue,
      asOf: asOf ?? this.asOf,
      currency: currency ?? this.currency,
    );
  }

  double get returnAmount => currentValue - principal;

  double get returnPct => principal > 0 ? returnAmount / principal * 100 : 0;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'principal': principal,
        'current_value': currentValue,
        'as_of': asOf,
        'currency': currency,
      };

  factory Investment.fromMap(Map<String, Object?> m) => Investment(
        id: m['id'] as int?,
        name: m['name'] as String,
        principal: (m['principal'] as num).toDouble(),
        currentValue: (m['current_value'] as num).toDouble(),
        asOf: m['as_of'] as int,
        currency: (m['currency'] as String?) ?? defaultCurrency,
      );
}
