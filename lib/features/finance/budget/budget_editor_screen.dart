import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/budget.dart';
import 'package:qalqul/core/utils/money.dart';
import 'package:qalqul/features/finance/budgets_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';
import 'package:qalqul/shared/widgets/app_bar.dart';
import 'package:qalqul/shared/widgets/currency_field.dart';
import 'package:qalqul/shared/widgets/date_field.dart';

class BudgetEditorScreen extends ConsumerStatefulWidget {
  final Budget? budget;
  const BudgetEditorScreen({super.key, this.budget});

  @override
  ConsumerState<BudgetEditorScreen> createState() => _BudgetEditorScreenState();
}

class _BudgetEditorScreenState extends ConsumerState<BudgetEditorScreen> {
  final _name = TextEditingController();
  final _target = TextEditingController();
  final _saved = TextEditingController();
  final _category = TextEditingController();
  late DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  late String _currency;

  @override
  void initState() {
    super.initState();
    _currency = widget.budget?.currency ?? ref.read(baseCurrencyProvider);
    final b = widget.budget;
    if (b != null) {
      _name.text = b.name;
      _target.text = minorToEditable(b.targetMinor, _currency);
      _saved.text = minorToEditable(b.savedMinor, _currency);
      _category.text = b.category;
      _deadline = DateTime.fromMillisecondsSinceEpoch(b.deadline);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    _category.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final b = Budget(
      name: _name.text.trim().isEmpty ? l10n.budgetDefaultName : _name.text.trim(),
      targetMinor: parseMinor(_target.text, _currency) ?? 0,
      savedMinor: parseMinor(_saved.text, _currency) ?? 0,
      deadline: _deadline.millisecondsSinceEpoch,
      category: _category.text.trim(),
      currency: _currency,
    );
    final notifier = ref.read(budgetsProvider.notifier);
    if (widget.budget == null) {
      await notifier.add(b);
    } else {
      await notifier.save(b.copyWith(id: widget.budget!.id));
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: QalqulAppBar(
        title: widget.budget == null ? l10n.budgetAdd : l10n.budgetEdit,
        extraActions: [
          TextButton(onPressed: _save, child: Text(l10n.commonSave)),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _field(l10n.commonName, _name),
              _field(l10n.budgetTargetField, _target, number: true),
              _field(l10n.budgetSavedField, _saved, number: true),
              _field(l10n.commonCategory, _category),
              CurrencyField(
                value: _currency,
                label: l10n.commonCurrency,
                onChanged: (v) => setState(() => _currency = v),
              ),
              DateField(
                label: l10n.commonDeadline,
                value: _deadline,
                onPick: (d) => setState(() => _deadline = d),
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
