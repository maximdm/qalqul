import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/investment.dart';
import 'package:qalqul/features/finance/investments_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';
import 'package:qalqul/shared/widgets/app_bar.dart';
import 'package:qalqul/shared/widgets/currency_field.dart';
import 'package:qalqul/shared/widgets/date_field.dart';

class InvestmentEditorScreen extends ConsumerStatefulWidget {
  final Investment? investment;
  const InvestmentEditorScreen({super.key, this.investment});

  @override
  ConsumerState<InvestmentEditorScreen> createState() =>
      _InvestmentEditorScreenState();
}

class _InvestmentEditorScreenState extends ConsumerState<InvestmentEditorScreen> {
  final _name = TextEditingController();
  final _principal = TextEditingController();
  final _value = TextEditingController();
  late DateTime _asOf = DateTime.now();
  late String _currency;

  @override
  void initState() {
    super.initState();
    _currency = widget.investment?.currency ?? ref.read(baseCurrencyProvider);
    final i = widget.investment;
    if (i != null) {
      _name.text = i.name;
      _principal.text = i.principal.toString();
      _value.text = i.currentValue.toString();
      _asOf = DateTime.fromMillisecondsSinceEpoch(i.asOf);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _principal.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final inv = Investment(
      name: _name.text.trim().isEmpty ? l10n.investmentsDefaultName : _name.text.trim(),
      principal: double.tryParse(_principal.text) ?? 0,
      currentValue: double.tryParse(_value.text) ?? 0,
      asOf: _asOf.millisecondsSinceEpoch,
      currency: _currency,
    );
    final notifier = ref.read(investmentsProvider.notifier);
    if (widget.investment == null) {
      await notifier.add(inv);
    } else {
      await notifier.update(inv.copyWith(id: widget.investment!.id));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: QalqulAppBar(
        title:
            widget.investment == null ? l10n.investmentsAdd : l10n.investmentsEdit,
        extraActions: [
          TextButton(onPressed: _save, child: Text(l10n.commonSave)),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _field(l10n.investmentsName, _name),
              _field(l10n.investmentsPrincipalField, _principal, number: true),
              _field(l10n.investmentsCurrentValue, _value, number: true),
              CurrencyField(
                value: _currency,
                label: l10n.commonCurrency,
                onChanged: (v) => setState(() => _currency = v),
              ),
              DateField(
                label: l10n.investmentsAsOf,
                value: _asOf,
                onPick: (d) => setState(() => _asOf = d),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController c, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        keyboardType:
            number ? TextInputType.numberWithOptions(decimal: true) : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
