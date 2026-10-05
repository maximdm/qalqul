import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/features/finance/currency_provider.dart';

/// Displays a monetary amount converted into the user's base currency.
///
/// Falls back to the record's own currency when no FX rate connects the two, so
/// a missing rate shows the original amount instead of a wrong conversion.
class MoneyText extends ConsumerWidget {
  final double amount;
  final String? from;
  final bool compact;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool showOriginalWhenConverted;

  const MoneyText(
    this.amount, {
    super.key,
    this.from,
    this.compact = false,
    this.style,
    this.textAlign,
    this.maxLines,
    this.showOriginalWhenConverted = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final source = (from ?? currency.base).toUpperCase();
    final converted = convertWith(currency, amount, from: source);
    final fmt = compact ? formatMoneyCompact : formatMoney;

    // When the source differs from the display currency, show the converted
    // value and keep the original next to it so nothing looks lost.
    if (showOriginalWhenConverted &&
        converted.converted &&
        source != currency.base) {
      return Text(
        '${fmt(converted.amount, currency: currency.base)}'
        ' (${fmt(amount, currency: source)})',
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      converted.converted
          ? fmt(converted.amount, currency: currency.base)
          : fmt(amount, currency: source),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}