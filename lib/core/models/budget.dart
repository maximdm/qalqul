import 'package:qalqul/core/utils/money.dart';

class Budget {
  final int? id;
  final String name;

  /// Target and saved totals, in minor units of [currency].
  final int targetMinor;
  final int savedMinor;
  final int deadline;
  final String category;
  final String currency;

  const Budget({
    this.id,
    required this.name,
    required this.targetMinor,
    this.savedMinor = 0,
    required this.deadline,
    this.category = '',
    this.currency = defaultCurrency,
  });

  Budget copyWith({
    int? id,
    String? name,
    int? targetMinor,
    int? savedMinor,
    int? deadline,
    String? category,
    String? currency,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      targetMinor: targetMinor ?? this.targetMinor,
      savedMinor: savedMinor ?? this.savedMinor,
      deadline: deadline ?? this.deadline,
      category: category ?? this.category,
      currency: currency ?? this.currency,
    );
  }

  /// Fraction of the target reached, 0..1.
  double get progress =>
      targetMinor > 0 ? (savedMinor / targetMinor).clamp(0, 1) : 0;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'target_minor': targetMinor,
        'saved_minor': savedMinor,
        'deadline': deadline,
        'category': category,
        'currency': currency,
      };

  factory Budget.fromMap(Map<String, Object?> m) => Budget(
        id: m['id'] as int?,
        name: m['name'] as String,
        targetMinor: (m['target_minor'] as num).toInt(),
        savedMinor: (m['saved_minor'] as num).toInt(),
        deadline: m['deadline'] as int,
        category: m['category'] as String,
        currency: (m['currency'] as String?) ?? defaultCurrency,
      );
}
