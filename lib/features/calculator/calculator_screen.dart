import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/note.dart';
import 'package:qalqul/features/calculator/calculator_provider.dart';
import 'package:qalqul/features/notes/note_editor_screen.dart';
import 'package:qalqul/features/notes/notes_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/widgets/app_bar.dart';

const _mainKeys = [
  'C', '⌫', '(', ')',
  '7', '8', '9', '÷',
  '4', '5', '6', '×',
  '1', '2', '3', '−',
  '0', '.', '=', '+',
];

/// A scientific key: [label] is what the user sees, [token] is what gets fed
/// into the expression. Keys whose [token] is empty use [onTap] instead.
class _SciKey {
  const _SciKey(this.label, this.token, {this.onTap});

  final String label;
  final String token;
  final void Function(CalculatorNotifier n)? onTap;
}

/// Only additions over [_mainKeys] live here, so switching SCI on never
/// shadows a digit or an operator that is already on the pad below it.
final List<_SciKey> _sciKeys = [
  const _SciKey('sin', 'sin('),
  const _SciKey('cos', 'cos('),
  const _SciKey('tan', 'tan('),
  const _SciKey('sin⁻¹', 'arcsin('),
  const _SciKey('cos⁻¹', 'arccos('),
  const _SciKey('tan⁻¹', 'arctan('),
  const _SciKey('ln', 'ln('),
  const _SciKey('log', 'log('),
  const _SciKey('√', '√'),
  const _SciKey('ⁿ√', 'nrt('),
  const _SciKey('xʸ', '^'),
  const _SciKey('x²', '^2'),
  const _SciKey('n!', '!'),
  const _SciKey('|x|', 'abs('),
  const _SciKey(',', ','),
  const _SciKey('π', 'π'),
  const _SciKey('e', 'e'),
  const _SciKey('eˣ', 'e('),
  const _SciKey('mod', '%'),
  _SciKey('1/x', '', onTap: (n) => n.reciprocal()),
  _SciKey('±', '', onTap: (n) => n.negate()),
  _SciKey('Ans', '', onTap: (n) => n.insertAnswer())
];

class CalculatorScreen extends ConsumerWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(calculatorProvider);
    final n = ref.read(calculatorProvider.notifier);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: QalqulAppBar(
        title: l10n.calculatorTitle,
        extraActions: [
          IconButton(
            icon: const Icon(Icons.note_add_outlined),
            tooltip: l10n.calculatorSendToNote,
            onPressed: () => _saveToNoteMenu(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Display(state: s),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Tooltip(
                    message: l10n.calculatorDegreesMode,
                    child: ChoiceChip(
                      label: const Text('DEG'),
                      selected: s.degrees,
                      onSelected: (_) => n.toggleDegrees(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: l10n.calculatorScientificMode,
                    child: ChoiceChip(
                      label: const Text('SCI'),
                      selected: s.sci,
                      onSelected: (_) => n.toggleSci(),
                    ),
                  ),
                  const Spacer(),
                  if (s.history.isNotEmpty)
                    TextButton(
                      onPressed: n.clearHistory,
                      child: Text(l10n.calculatorClearHistory),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.calculatorMemory(
                        s.memory != null ? '${s.memory}' : '—',
                      ),
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _memBtn('M+', n.memoryAdd, theme),
                  _memBtn(
                    'M−',
                    s.memory != null ? n.memorySubtract : null,
                    theme,
                  ),
                  _memBtn(
                    'MR',
                    s.memory != null ? n.memoryRecall : null,
                    theme,
                  ),
                  _memBtn('MC', s.memory != null ? n.memoryClear : null, theme),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (s.sci) _sciPad(n, theme),
                          _pad(_mainKeys, n, theme),
                        ],
                      ),
                    ),
                  ),
                  if (s.history.isNotEmpty)
                    SizedBox(
                      height: 148,
                      child: _History(history: s.history, l10n: l10n),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _calcLine(CalculatorState s) {
    if (s.isError) return null;
    if (s.history.isNotEmpty) return s.history.first;
    if (s.expression.isNotEmpty) return s.expression;
    return null;
  }

  void _saveToNoteMenu(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final line = _calcLine(ref.read(calculatorProvider));
    if (line == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.calculatorNothingYet)));
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: Text(l10n.noteFromCalculation),
              onTap: () {
                Navigator.of(sheet).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NoteEditorScreen(
                      initialTitle: l10n.noteCalculationTitle,
                      initialBody: line,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_outlined),
              title: Text(l10n.noteAppendToExisting),
              onTap: () {
                Navigator.of(sheet).pop();
                _appendToNote(context, ref, line);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _appendToNote(
    BuildContext context,
    WidgetRef ref,
    String line,
  ) async {
    // Awaited rather than read: the notes are still loading on a cold start, and
    // treating that as "you have no notes" would send the user to create one.
    final notes = (await ref.read(notesProvider.future)).notes;
    if (!context.mounted) return;
    final l10n = context.l10n;
    if (notes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.noteNoNotesToAppend)));
      return;
    }

    final picked = await showModalBottomSheet<Note>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(
          children: [
            for (final n in notes)
              ListTile(
                title: Text(n.title.isEmpty ? l10n.notesUntitled : n.title),
                subtitle: n.preview.isNotEmpty ? Text(n.preview) : null,
                onTap: () => Navigator.of(sheet).pop(n),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;

    final updated = picked.copyWith(
      body: '${picked.body}\n$line'.trim(),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await ref.read(notesProvider.notifier).save(updated);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.noteAppended(
              picked.title.isEmpty ? l10n.notesUntitled : picked.title,
            ),
          ),
        ),
      );
    }
  }

  Widget _memBtn(String label, VoidCallback? onPressed, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: theme.cardColor,
          disabledBackgroundColor: theme.cardColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: Text(label, style: theme.textTheme.labelMedium),
      ),
    );
  }

  Widget _pad(List<String> keys, CalculatorNotifier n, ThemeData theme) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: keys.map((k) => _key(k, n, theme)).toList(),
    );
  }

  Widget _sciPad(CalculatorNotifier n, ThemeData theme) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.0,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: _sciKeys
          .map(
            (k) => _keyButton(
              label: k.label,
              onPressed: () => k.onTap != null ? k.onTap!(n) : n.input(k.token),
              theme: theme,
              accent: true,
            ),
          )
          .toList(),
    );
  }

  Widget _key(String k, CalculatorNotifier n, ThemeData theme) {
    return _keyButton(
      label: k,
      onPressed: () => n.input(k),
      theme: theme,
      accent: {'÷', '×', '−', '+', '=', 'C', '⌫'}.contains(k),
      // `=` commits the expression, so it gets a circle to stand apart.
      round: k == '=',
    );
  }

  Widget _keyButton({
    required String label,
    required VoidCallback onPressed,
    required ThemeData theme,
    required bool accent,
    bool round = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: accent
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : theme.cardColor,
          shape: round
              ? const CircleBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
        ),
        onPressed: onPressed,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: theme.textTheme.titleMedium),
        ),
      ),
    );
  }
}

class _Display extends StatelessWidget {
  final CalculatorState state;
  const _Display({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            state.expression.isEmpty ? '0' : state.expression,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.right,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!state.isError && state.result != state.expression)
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  tooltip: l10n.calculatorCopyResult,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: state.result));
                  },
                ),
              Text(
                state.isError
                    ? l10n.calculatorError
                    : (state.result == state.expression ? '' : state.result),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: state.isError ? Colors.red : null,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _History extends StatelessWidget {
  final List<String> history;
  final L10n l10n;
  const _History({required this.history, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.calculatorHistory, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(history[i], style: theme.textTheme.bodyMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
