import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/features/finance/currency_provider.dart';
import 'package:qalqul/l10n/l10n.dart';

/// Displays a monetary amount converted into the user's base currency.
///
/// Falls back to the record's own currency when no FX rate connects the two, so
/// a missing rate shows the original amount instead of a wrong conversion.
class MoneyText extends ConsumerWidget {
  final int minor;
  final String? from;
  final bool compact;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool showOriginalWhenConverted;

  const MoneyText(
    this.minor, {
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
    final converted = convertWith(currency, minor, from: source);
    final fmt = compact ? formatMoneyCompact : formatMoney;

    // When the source differs from the display currency, show the converted
    // value and keep the original next to it so nothing looks lost.
    if (showOriginalWhenConverted &&
        converted.converted &&
        source != currency.base) {
      return Text(
        '${fmt(converted.decimal, currency: currency.base)}'
        ' (${fmt(toDecimal(minor, source), currency: source)})',
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      converted.converted
          ? fmt(converted.decimal, currency: currency.base)
          : fmt(toDecimal(minor, source), currency: source),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Displays a total combined from several currencies ([MoneyTotal]).
///
/// When every contributing amount converted, this is just the formatted figure.
/// When some currency had no rate path, the figure is flagged: the total is
/// still correct as far as it goes, and the tooltip says exactly what is
/// missing, so a partial total is never mistaken for a complete one.
class MoneyTotalText extends StatelessWidget {
  final MoneyTotal total;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final bool compact;

  const MoneyTotalText(
    this.total, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = compact
        ? formatMoneyCompact(total.decimal, currency: total.currency)
        : formatMoney(total.decimal, currency: total.currency);
    final label = Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
    if (total.isComplete) return label;

    final l10n = context.l10n;
    return Tooltip(
      message: '${l10n.moneyPartialTotal}\n'
          '${l10n.moneyPartialTotalBody(total.describeMissing())}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: label),
          const SizedBox(width: 4),
          Icon(
            Icons.warning_amber_rounded,
            size: (style?.fontSize ?? 14) + 2,
            color: theme.colorScheme.error,
            semanticLabel: l10n.moneyMissingRates(
              total.missingCurrencies.join(', '),
            ),
          ),
        ],
      ),
    );
  }
}