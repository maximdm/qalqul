import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qalqul/core/models/note.dart';
import 'package:qalqul/features/notes/note_expression.dart';
import 'package:qalqul/features/notes/note_markdown_view.dart';
import 'package:qalqul/features/notes/notes_provider.dart';
import 'package:qalqul/l10n/l10n.dart';
import 'package:qalqul/shared/widgets/app_bar.dart';

class _EvaluateIntent extends Intent {
  const _EvaluateIntent();
}

class NoteEditorScreen extends ConsumerStatefulWidget {
  final Note? note;
  final String? initialTitle;
  final String? initialBody;
  const NoteEditorScreen({
    super.key,
    this.note,
    this.initialTitle,
    this.initialBody,
  });

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late bool _markdown;
  bool _previewing = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(
      text: widget.note?.title ?? widget.initialTitle ?? '',
    );
    _body = TextEditingController(
      text: widget.note?.body ?? widget.initialBody ?? '',
    );
    _markdown = widget.note?.isMarkdown ?? false;
    _body.addListener(_onBodyChanged);
  }

  @override
  void dispose() {
    _body.removeListener(_onBodyChanged);
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _evaluate() async {
    final text = _body.text;
    final sel = _body.selection;
    final hasSel =
        sel.isValid && !sel.isCollapsed && sel.end <= text.length;

    late final String targetText;
    late final int replaceStart;
    late final int replaceEnd;

    if (hasSel) {
      targetText = text.substring(sel.start, sel.end);
      replaceStart = sel.start;
      replaceEnd = sel.end;
    } else {
      final cursor = sel.baseOffset < 0 ? text.length : sel.baseOffset;
      final lineStart = text.lastIndexOf('\n', cursor - 1) + 1;
      final lineEnd = text.indexOf('\n', cursor);
      final end = lineEnd < 0 ? text.length : lineEnd;
      targetText = text.substring(lineStart, end);
      replaceStart = lineStart;
      replaceEnd = end;
    }

    final expr = targetText.contains('=')
        ? targetText.substring(targetText.lastIndexOf('=') + 1).trim()
        : targetText.trim();
    if (expr.isEmpty) {
      _toast(context.l10n.noteEvalNoTarget);
      return;
    }

    final value = NoteExpression.evaluate(text, expr);
    if (value == null) {
      _toast(context.l10n.noteEvalFailed);
      return;
    }

    final result = _format(value);
    final replacement = targetText.trim().endsWith('=')
        ? '$targetText$result'
        : '${targetText.replaceFirst(RegExp(r'\s*=\s*-?\d+(\.\d+)?\$'), '')} = $result';
    _body.value = TextEditingValue(
      text: text.replaceRange(replaceStart, replaceEnd, replacement),
      selection: TextSelection.collapsed(offset: replaceStart + replacement.length),
    );
  }

  String _format(double n) {
    if (n == n.roundToDouble()) return n.toInt().toString();
    final fixed = n.toStringAsFixed(10);
    return fixed
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  // Auto-evaluate lines of the form `expr =` as the user types (spreadsheet-style).
  bool _autoEvalScheduled = false;

  void _onBodyChanged() {
    if (!mounted || _autoEvalScheduled) return;
    _autoEvalScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoEvalScheduled = false;
      _applyAutoEval();
    });
  }

  void _applyAutoEval() {
    if (!mounted) return;
    final text = _body.text;
    final sel = _body.selection;
    if (!sel.isValid || sel.baseOffset < 0) return;

    final caret = sel.baseOffset;
    final lineStart = caret <= 0 ? 0 : text.lastIndexOf('\n', caret - 1) + 1;
    final lineEnd = text.indexOf('\n', caret);
    final end = lineEnd < 0 ? text.length : lineEnd;
    final line = text.substring(lineStart, end);

    // Only auto-evaluate when the user just typed `=` (line ends with `=`),
    // so a running expression like `2+2=4+2` is never overwritten mid-edit.
    if (!line.endsWith('=')) return;

    // The running expression is the segment just before the trailing `=`.
    final parts = line.split('=');
    final expr = parts[parts.length - 2].trim();
    if (expr.isEmpty) return;

    final value = NoteExpression.compute(expr) ?? NoteExpression.evaluate(text, expr);
    if (value == null) return;
    final result = _format(value);

    final newLine = '$line$result';
    final newText = text.replaceRange(lineStart, end, newLine);
    final newCaret = caret + result.length;
    _body.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newCaret.clamp(0, newText.length),
      ),
    );
  }

  void _toast(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _save() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = widget.note?.copyWith(
          title: _title.text.trim(),
          body: _body.text,
          isMarkdown: _markdown,
          updatedAt: now,
        ) ??
        Note(
          title: _title.text.trim(),
          body: _body.text,
          isMarkdown: _markdown,
          createdAt: now,
          updatedAt: now,
        );

    if (widget.note == null) {
      await ref.read(notesProvider.notifier).add(updated);
    } else {
      await ref.read(notesProvider.notifier).save(updated);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: QalqulAppBar(
        title: widget.note == null ? l10n.noteNew : l10n.noteEdit,
        extraActions: [
          IconButton(
            icon: const Icon(Icons.functions),
            tooltip: l10n.noteEvaluateTooltip,
            onPressed: _evaluate,
          ),
          IconButton(
            icon: Icon(
              Icons.text_snippet_outlined,
              color: _markdown ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: l10n.noteMarkdownTooltip,
            onPressed: () => setState(() => _markdown = !_markdown),
          ),
          TextButton(onPressed: _save, child: Text(l10n.commonSave)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: InputDecoration(hintText: l10n.noteTitleHint),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 10),
            if (_markdown)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(l10n.noteTabEdit),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(l10n.noteTabPreview),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                    ),
                  ],
                  selected: {_previewing},
                  onSelectionChanged: (s) =>
                      setState(() => _previewing = s.first),
                ),
              ),
            if (_markdown) const SizedBox(height: 10),
            Expanded(
              child: _markdown && _previewing
                  ? NoteMarkdownView(data: _body.text)
                  : Actions(
                      actions: {
                        _EvaluateIntent: CallbackAction<_EvaluateIntent>(
                          onInvoke: (_) {
                            _evaluate();
                            return null;
                          },
                        ),
                      },
                      child: Shortcuts(
                        shortcuts: const {
                          SingleActivator(LogicalKeyboardKey.tab): _EvaluateIntent(),
                        },
                        child: TextField(
                          controller: _body,
                          decoration: InputDecoration(
                            hintText: l10n.noteBodyHint,
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: _markdown
                              ? Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontFamily: 'monospace')
                              : null,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}