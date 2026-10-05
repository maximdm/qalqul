import 'dart:convert';

/// Widget types a user can put on the home dashboard.
///
/// [value] is the persisted `kind` string (keep it stable — it is written to
/// existing rows), [labelKey] is the `l10n` message id for the studio label.
enum UserWidgetKind {
  noteSummary('noteSummary', 'kindNoteSummary'),
  calculator('calculator', 'kindCalculator'),
  financeOverview('financeOverview', 'kindFinanceOverview'),
  spendingChart('spendingChart', 'kindSpendingChart'),
  netWorth('netWorth', 'kindNetWorth'),
  monthSpend('monthSpend', 'kindMonthSpend'),
  portfolioValue('portfolioValue', 'kindPortfolioValue'),
  billsDue('billsDue', 'kindBillsDue');

  const UserWidgetKind(this.value, this.labelKey);
  final String value;
  final String labelKey;

  static UserWidgetKind fromValue(String v) =>
      values.firstWhere((k) => k.value == v, orElse: () => noteSummary);
}

class UserWidget {
  final int? id;
  final String kind;
  final String title;
  final Map<String, dynamic> config;
  final int position;

  const UserWidget({
    this.id,
    required this.kind,
    required this.title,
    this.config = const {},
    this.position = 0,
  });

  /// Visual size: `s` (small), `m` (medium), `l` (large). Unknown values fall
  /// back to `m` so a stale/hand-edited config can't break rendering.
  String get size {
    final v = config['size'];
    return v == 's' || v == 'l' ? v : 'm';
  }

  /// For `billsDue`: how far ahead to look, in days (default 7).
  int get billsWithinDays => _intConfig('withinDays', 7);

  /// For `monthSpend`: which month to show. `0` = current month, `-1` = previous.
  int get monthOffset => _intConfig('monthOffset', 0);

  /// For `monthSpend`: optional spending category to isolate (empty = all).
  String get category => (config['category'] as String?) ?? '';

  int _intConfig(String key, int fallback) {
    final v = config[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  /// Bento grid cell span [crossAxis, mainAxis] derived from [size].
  List<int> get cells {
    switch (size) {
      case 's':
        return const [2, 1];
      case 'l':
        return const [4, 2];
      case 'm':
      default:
        return const [2, 2];
    }
  }

  UserWidget copyWith({
    int? id,
    String? kind,
    String? title,
    Map<String, dynamic>? config,
    int? position,
  }) {
    return UserWidget(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      config: config ?? this.config,
      position: position ?? this.position,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind,
        'title': title,
        'config': jsonEncode(config),
        'position': position,
      };

  factory UserWidget.fromMap(Map<String, dynamic> m) => UserWidget(
        id: m['id'] as int?,
        kind: m['kind'] as String,
        title: m['title'] as String,
        config: m['config'] == null
            ? const {}
            : Map<String, dynamic>.from(
                jsonDecode(m['config'] as String) as Map),
        position: (m['position'] as int?) ?? 0,
      );
}
