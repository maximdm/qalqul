import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/transaction.dart';
import 'package:qalqul/features/finance/reminder_service.dart';
import 'package:qalqul/features/finance/transactions_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/providers/settings_provider.dart';
import 'package:qalqul/shared/widgets/app_bar.dart';
import 'package:qalqul/shared/widgets/currency_field.dart';
import 'package:qalqul/shared/widgets/date_field.dart';

class TransactionEditorScreen extends ConsumerStatefulWidget {
  final String kind;
  final AppTransaction? transaction;

  /// Overrides for the category and date field labels. When omitted they are
  /// derived from [kind] and the active locale, so the editor is never left
  /// showing an English placeholder.
  final String? categoryLabel;
  final String? dateLabel;

  const TransactionEditorScreen({
    super.key,
    required this.kind,
    this.transaction,
    this.categoryLabel,
    this.dateLabel,
  });

  @override
  ConsumerState<TransactionEditorScreen> createState() =>
      _TransactionEditorScreenState();
}

class _TransactionEditorScreenState extends ConsumerState<TransactionEditorScreen> {
  final _amount = TextEditingController();
  final _category = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date = DateTime.now();
  bool _recurring = false;
  String _recurrence = 'monthly';
  late DateTime _nextDue = DateTime.now().add(const Duration(days: 30));
  late String _currency;

  @override
  void initState() {
    super.initState();
    _currency = widget.transaction?.currency ??
        ref.read(baseCurrencyProvider);
    final t = widget.transaction;
    if (t != null) {
      _amount.text = t.amount.toString();
      _category.text = t.category;
      _note.text = t.note;
      _date = DateTime.fromMillisecondsSinceEpoch(t.date);
      _recurring = t.isRecurring;
      _recurrence = t.recurrence;
      _nextDue = t.nextDue > 0
          ? DateTime.fromMillisecondsSinceEpoch(t.nextDue)
          : _nextDue;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = AppTransaction(
      kind: widget.kind,
      amount: double.tryParse(_amount.text) ?? 0,
      category: _category.text.trim(),
      date: _date.millisecondsSinceEpoch,
      note: _note.text.trim(),
      isRecurring: _recurring,
      recurrence: _recurrence,
      nextDue: _recurring ? _nextDue.millisecondsSinceEpoch : 0,
      currency: _currency,
    );
    final notifier = ref.read(transactionsProvider.notifier);
    if (widget.transaction == null) {
      await notifier.add(t);
    } else {
      await notifier.update(t.copyWith(id: widget.transaction!.id));
    }
    // Turning a transaction into a recurring one is what makes a reminder
    // possible, so that's the moment to ask for the notification permissions.
    if (_recurring) {
      unawaited(ReminderService.requestPermissions());
      unawaited(ReminderService.scheduleDueSoon());
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCredit = widget.kind == 'credit';
    final categoryLabel =
        widget.categoryLabel ?? (isCredit ? l10n.creditLender : l10n.commonCategory);
    final dateLabel =
        widget.dateLabel ?? (isCredit ? l10n.creditDueDate : l10n.commonDate);
    return Scaffold(
      appBar: QalqulAppBar(
        title: widget.transaction == null ? l10n.txAddEntry : l10n.txEditEntry,
        extraActions: [
          TextButton(onPressed: _save, child: Text(l10n.commonSave)),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextField(
                controller: _amount,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: l10n.commonAmount),
              ),
            ),
            CurrencyField(
              value: _currency,
              label: l10n.commonCurrency,
              onChanged: (v) => setState(() => _currency = v),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextField(
                controller: _category,
                decoration: InputDecoration(labelText: categoryLabel),
              ),
            ),
            DateField(
              label: dateLabel,
              value: _date,
              onPick: (d) => setState(() => _date = d),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.txRecurring),
              value: _recurring,
              onChanged: (v) => setState(() => _recurring = v),
            ),
            if (_recurring) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: InputDecorator(
                  decoration: InputDecoration(labelText: l10n.txRepeat),
                  child: DropdownButton<String>(
                    value: _recurrence,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(
                          value: 'daily', child: Text(l10n.txRepeatDaily)),
                      DropdownMenuItem(
                          value: 'weekly', child: Text(l10n.txRepeatWeekly)),
                      DropdownMenuItem(
                          value: 'monthly', child: Text(l10n.txRepeatMonthly)),
                    ],
                    onChanged: (v) => setState(() => _recurrence = v!),
                  ),
                ),
              ),
              DateField(
                label: l10n.txNextDue,
                value: _nextDue,
                onPick: (d) => setState(() => _nextDue = d),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextField(
                controller: _note,
                decoration: InputDecoration(labelText: l10n.commonNote),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}