import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';

/// Dropdown for picking the currency a finance record is stored in.
class CurrencyField extends ConsumerWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final String label;

  const CurrencyField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Currency',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(baseCurrencyProvider);
    // Keep the current value selectable even if it isn't in the built-in list
    // (e.g. a currency added by a future version).
    final codes = <String>{
      ...supportedCurrencies.map((c) => c.code),
      value,
    }.toList()
      ..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: DropdownButton<String>(
          value: codes.contains(value) ? value : codes.first,
          isExpanded: true,
          items: [
            for (final code in codes)
              DropdownMenuItem(
                value: code,
                child: Text(
                  '$code · ${currencyInfo(code).label}'
                  '${code == base ? '  ★' : ''}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}