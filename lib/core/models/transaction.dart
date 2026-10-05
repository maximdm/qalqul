import 'package:qalqul/core/utils/money.dart';

class AppTransaction {
  final int? id;
  final String kind;
  final double amount;
  final String category;
  final int date;
  final String note;
  final bool isRecurring;
  final String recurrence;
  final int nextDue;
  final String currency;

  const AppTransaction({
    this.id,
    required this.kind,
    required this.amount,
    this.category = '',
    required this.date,
    this.note = '',
    this.isRecurring = false,
    this.recurrence = 'monthly',
    this.nextDue = 0,
    this.currency = defaultCurrency,
  });

  AppTransaction copyWith({
    int? id,
    String? kind,
    double? amount,
    String? category,
    int? date,
    String? note,
    bool? isRecurring,
    String? recurrence,
    int? nextDue,
    String? currency,
  }) {
    return AppTransaction(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrence: recurrence ?? this.recurrence,
      nextDue: nextDue ?? this.nextDue,
      currency: currency ?? this.currency,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'kind': kind,
        'amount': amount,
        'category': category,
        'date': date,
        'note': note,
        'is_recurring': isRecurring ? 1 : 0,
        'recurrence': recurrence,
        'next_due': nextDue,
        'currency': currency,
      };

  factory AppTransaction.fromMap(Map<String, Object?> m) => AppTransaction(
        id: m['id'] as int?,
        kind: m['kind'] as String,
        amount: (m['amount'] as num).toDouble(),
        category: m['category'] as String,
        date: m['date'] as int,
        note: m['note'] as String,
        isRecurring: (m['is_recurring'] as int? ?? 0) == 1,
        recurrence: (m['recurrence'] as String?) ?? 'monthly',
        nextDue: (m['next_due'] as int?) ?? 0,
        currency: (m['currency'] as String?) ?? defaultCurrency,
      );
}
