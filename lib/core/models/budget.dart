import 'package:qalqul/core/utils/money.dart';

class Budget {
  final int? id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final int deadline;
  final String category;
  final String currency;

  const Budget({
    this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0,
    required this.deadline,
    this.category = '',
    this.currency = defaultCurrency,
  });

  Budget copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? savedAmount,
    int? deadline,
    String? category,
    String? currency,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      deadline: deadline ?? this.deadline,
      category: category ?? this.category,
      currency: currency ?? this.currency,
    );
  }

  double get progress =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0, 1) : 0;

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'target_amount': targetAmount,
        'saved_amount': savedAmount,
        'deadline': deadline,
        'category': category,
        'currency': currency,
      };

  factory Budget.fromMap(Map<String, Object?> m) => Budget(
        id: m['id'] as int?,
        name: m['name'] as String,
        targetAmount: (m['target_amount'] as num).toDouble(),
        savedAmount: (m['saved_amount'] as num).toDouble(),
        deadline: m['deadline'] as int,
        category: m['category'] as String,
        currency: (m['currency'] as String?) ?? defaultCurrency,
      );
}
