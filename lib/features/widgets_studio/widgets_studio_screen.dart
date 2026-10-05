import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/user_widget.dart';
import 'package:qalqul/features/widgets_studio/user_widgets_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/widgets/app_bar.dart';
import 'package:qalqul/shared/widgets/empty_state.dart';
import 'package:qalqul/shared/widgets/load_state_views.dart';

class WidgetsStudioScreen extends ConsumerWidget {
  const WidgetsStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final widgets = ref.watch(userWidgetsProvider);

    return Scaffold(
      appBar: QalqulAppBar(title: l10n.widgetsStudioTitle),
      floatingActionButton: FloatingActionButton(
        heroTag: 'widgetsStudioFAB',
        onPressed: () => _showEditor(context, ref),
        child: const Icon(Icons.add),
      ),
      body: widgets.when(
        loading: () => const LoadingView(),
        error: (error, _) => const LoadErrorView(),
        data: (items) => _list(context, ref, items),
      ),
    );
  }

  Widget _list(
      BuildContext context, WidgetRef ref, List<UserWidget> widgets) {
    final l10n = context.l10n;
    return widgets.isEmpty
        ? EmptyState(
            icon: Icons.dashboard_customize_outlined,
            title: l10n.widgetsStudioEmpty,
          )
        : ReorderableListView(
            padding: const EdgeInsets.all(12),
            onReorderItem: (key, to) {
              final id = key is ValueKey ? (key as ValueKey).value : null;
              final from = widgets.indexWhere((w) => w.id == id);
              if (from >= 0) {
                ref.read(userWidgetsProvider.notifier).reorder(from, to);
              }
            },
            children: [
              for (final w in widgets)
                  Card(
                    key: ValueKey(w.id),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle),
                      title: Text(w.title),
                      subtitle: Text(
                        '${l10n.kindLabel(UserWidgetKind.fromValue(w.kind))} · '
                        '${_sizeLabel(l10n, w.size)}',
                      ),
                      onTap: () => _showEditor(context, ref, widget: w),
                      onLongPress: () =>
                          ref.read(userWidgetsProvider.notifier).delete(w.id!),
                    ),
                  ),
            ],
          );
  }

  String _sizeLabel(L10n l10n, String size) => switch (size) {
        's' => l10n.widgetsSizeSmall,
        'l' => l10n.widgetsSizeLarge,
        _ => l10n.widgetsSizeMedium,
      };

  Future<void> _showEditor(BuildContext context, WidgetRef ref,
      {UserWidget? widget}) async {
    final l10n = context.l10n;
    var kind = UserWidgetKind.fromValue(widget?.kind ?? 'noteSummary');
    var title = widget?.title ?? '';
    var size = widget?.size ?? 'm';
    var withinDays = widget?.billsWithinDays ?? 7;
    var monthOffset = widget?.monthOffset ?? 0;
    var category = widget?.category ?? '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, set) => AlertDialog(
            title: Text(widget == null ? l10n.widgetsNew : l10n.widgetsEdit),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InputDecorator(
                    decoration:
                        InputDecoration(labelText: l10n.widgetsType),
                    child: DropdownButton<UserWidgetKind>(
                      value: kind,
                      isExpanded: true,
                      items: [
                        for (final k in UserWidgetKind.values)
                          DropdownMenuItem(
                            value: k,
                            child: Text(l10n.kindLabel(k)),
                          ),
                      ],
                      onChanged: (v) => set(() => kind = v!),
                    ),
                  ),
                  TextField(
                    onChanged: (v) => title = v,
                    decoration:
                        InputDecoration(labelText: l10n.widgetsTitleField),
                    controller: TextEditingController(text: widget?.title),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration:
                        InputDecoration(labelText: l10n.widgetsSize),
                    child: DropdownButton<String>(
                      value: size,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(
                            value: 's', child: Text(l10n.widgetsSizeSmall)),
                        DropdownMenuItem(
                            value: 'm', child: Text(l10n.widgetsSizeMedium)),
                        DropdownMenuItem(
                            value: 'l', child: Text(l10n.widgetsSizeLarge)),
                      ],
                      onChanged: (v) => set(() => size = v!),
                    ),
                  ),
                  if (kind == UserWidgetKind.billsDue) ...[
                    const SizedBox(height: 8),
                    _numberField(
                      key: const ValueKey('withinDays'),
                      label: l10n.widgetLookaheadLabel,
                      value: withinDays,
                      onChanged: (v) => set(() => withinDays = v),
                    ),
                  ],
                  if (kind == UserWidgetKind.monthSpend) ...[
                    const SizedBox(height: 8),
                    _numberField(
                      key: const ValueKey('monthOffset'),
                      label: l10n.widgetMonthOffsetLabel,
                      value: monthOffset,
                      onChanged: (v) => set(() => monthOffset = v),
                    ),
                    TextField(
                      decoration:
                          InputDecoration(labelText: l10n.commonCategory),
                      onChanged: (v) => set(() => category = v),
                      controller: TextEditingController(text: category),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: () {
                  final kindLabel = l10n.kindLabel(kind);
                  final config = <String, dynamic>{
                    ...widget?.config ?? const <String, dynamic>{},
                    'size': size,
                    if (kind == UserWidgetKind.billsDue)
                      'withinDays': withinDays,
                    if (kind == UserWidgetKind.monthSpend) ...{
                      'monthOffset': monthOffset,
                      'category': category.trim(),
                    },
                  };
                  final w = (widget ?? const UserWidget(kind: '', title: ''))
                      .copyWith(
                    kind: kind.value,
                    title: title.trim().isEmpty ? kindLabel : title.trim(),
                    config: config,
                  );
                  final notifier = ref.read(userWidgetsProvider.notifier);
                  if (widget == null) {
                    notifier.add(w);
                  } else {
                    notifier.save(w);
                  }
                  Navigator.of(ctx).pop();
                },
                child: Text(l10n.commonSave),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _numberField({
    required Key key,
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return TextField(
      key: key,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      controller: TextEditingController(text: value.toString()),
      onChanged: (v) => onChanged(int.tryParse(v.trim()) ?? 0),
    );
  }
}