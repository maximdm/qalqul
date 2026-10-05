/// Lightweight markdown → plain-text helpers used for note list previews and
/// search snippets. Deliberately not a full markdown parser: it only has to
/// remove the syntax a preview line would otherwise show verbatim.
library;

final _inlineCode = RegExp(r'`([^`]*)`');
final _image = RegExp(r'!\[([^\]]*)\]\([^)]*\)');
final _link = RegExp(r'\[([^\]]*)\]\([^)]*\)');
final _htmlTag = RegExp(r'</?[a-zA-Z][^>]*>');
final _emphasis = RegExp(r'(\*\*\*|\*\*|\*|___|__|_|~~)');
final _headingPrefix = RegExp(r'^\s{0,3}#{1,6}\s*');
final _quoteOrListPrefix = RegExp(r'^\s{0,3}(>|(?:[-*+]|\d+[.)])\s)');
final _setextUnderline = RegExp(r'^\s{0,3}(=+|-{3,})\s*$');
final _thematicBreak = RegExp(r'^\s{0,3}([-*_]\s*){3,}$');
final _whitespaceRun = RegExp(r'[ \t]+');
final _blankLines = RegExp(r'\n{2,}');

/// Strips markdown syntax, keeping the readable text.
String stripMarkdown(String input) {
  final withoutBlocks = input
      .split('\n')
      .where((line) => !_thematicBreak.hasMatch(line))
      .where((line) => !_setextUnderline.hasMatch(line))
      .map(
        (line) => line
            .replaceFirst(_headingPrefix, '')
            .replaceFirst(_quoteOrListPrefix, ''),
      )
      .join('\n');

  final withoutImages = withoutBlocks.replaceAllMapped(_image, (m) {
    final alt = m.group(1) ?? '';
    return alt.isEmpty ? '' : alt;
  });
  final withoutLinks = withoutImages.replaceAllMapped(
    _link,
    (m) => m.group(1) ?? '',
  );
  final withoutCode = withoutLinks.replaceAllMapped(
    _inlineCode,
    (m) => m.group(1) ?? '',
  );
  final withoutHtml = withoutCode.replaceAll(_htmlTag, '');

  return withoutHtml
      .replaceAll(_emphasis, '')
      .replaceAll(_whitespaceRun, ' ')
      .replaceAll(_blankLines, '\n')
      .trim();
}

/// True when [input] contains at least one markdown block-level marker, used to
/// hint that a note could be rendered as markdown.
bool looksLikeMarkdown(String input) =>
    RegExp(r'^\s{0,3}(#{1,6}\s|[-*+]\s|\d+[.)]\s|>\s)', multiLine: true)
        .hasMatch(input) ||
    RegExp(r'(\*\*|__|`|\[[^\]]*\]\([^)]*\))').hasMatch(input);