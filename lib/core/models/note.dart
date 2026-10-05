import 'package:qalqul/core/utils/markdown.dart';

class Note {
  final int? id;
  final String title;
  final String body;
  final bool isFavorite;
  final bool isMarkdown;
  final int createdAt;
  final int updatedAt;

  const Note({
    this.id,
    required this.title,
    required this.body,
    this.isFavorite = false,
    this.isMarkdown = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Note copyWith({
    int? id,
    String? title,
    String? body,
    bool? isFavorite,
    bool? isMarkdown,
    int? createdAt,
    int? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      isFavorite: isFavorite ?? this.isFavorite,
      isMarkdown: isMarkdown ?? this.isMarkdown,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'is_favorite': isFavorite ? 1 : 0,
        'is_markdown': isMarkdown ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Note.fromMap(Map<String, Object?> m) => Note(
        id: m['id'] as int?,
        title: m['title'] as String,
        body: m['body'] as String,
        isFavorite: (m['is_favorite'] as int? ?? 0) == 1,
        isMarkdown: (m['is_markdown'] as int? ?? 0) == 1,
        createdAt: m['created_at'] as int,
        updatedAt: m['updated_at'] as int,
      );

  /// Full plain-text body. Markdown syntax is stripped when the note is
  /// flagged as markdown, so list previews and search snippets show and match
  /// words instead of raw `**` or `#`.
  String get plainBody => isMarkdown ? stripMarkdown(body) : body;

  /// Plain-text one-liner for list rows, truncated for display only.
  String get preview {
    final trimmed = plainBody.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.length > 80 ? '${trimmed.substring(0, 80)}…' : trimmed;
  }

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.id == id &&
      other.title == title &&
      other.body == body &&
      other.isFavorite == isFavorite &&
      other.isMarkdown == isMarkdown &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, title, body, isFavorite, isMarkdown, createdAt, updatedAt);
}
