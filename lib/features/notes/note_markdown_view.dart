import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:qalqul/l10n/l10n.dart';

/// Renders a note body as markdown, themed from the active Material scheme so
/// it matches the rest of the app in both light and dark mode.
///
/// Code spans/blocks are styled to sit next to the inline `=` calculator
/// results that Qalqul writes into notes.
class NoteMarkdownView extends StatelessWidget {
  final String data;
  final bool selectable;

  const NoteMarkdownView({
    super.key,
    required this.data,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final sheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      code: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        backgroundColor: scheme.primary.withValues(alpha: 0.10),
      ),
      codeblockDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      blockquoteDecoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      blockquotePadding: const EdgeInsets.all(10),
      tableBorder: TableBorder.all(color: theme.dividerColor, width: 1),
      h1: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      h2: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      h3: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      listBullet: theme.textTheme.bodyLarge,
    );

    final markdown = MarkdownBody(
      data: data,
      selectable: selectable,
      styleSheet: sheet,
    );

    return SelectionArea(
      child: data.trim().isEmpty
          ? Center(
              child: Text(
                context.l10n.notePreviewEmpty,
                style: theme.textTheme.bodySmall,
              ),
            )
          : markdown,
    );
  }
}