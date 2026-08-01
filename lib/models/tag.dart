class Tag {
  final String name;
  final String phrase;
  List<TagOccurrence> occurrences;

  Tag({
    required this.name,
    required this.phrase,
    List<TagOccurrence>? occurrences,
  }) : occurrences = occurrences ?? [];

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'] as String,
      phrase: json['phrase'] as String,
      occurrences: (json['occurrences'] as List<dynamic>?)
              ?.map((e) => TagOccurrence.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Used for export – does NOT include occurrences
  Map<String, dynamic> toJson() => {
        'name': name,
        'phrase': phrase,
      };

  /// Full version (used internally when saving to disk)
  Map<String, dynamic> toJsonFull() => {
        'name': name,
        'phrase': phrase,
        'occurrences': occurrences.map((e) => e.toJson()).toList(),
      };
}

class TagOccurrence {
  final String book;
  final int chapter;
  final int verse;

  TagOccurrence({
    required this.book,
    required this.chapter,
    required this.verse,
  });

  factory TagOccurrence.fromJson(Map<String, dynamic> json) {
    return TagOccurrence(
      book: json['book'] as String,
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'book': book,
        'chapter': chapter,
        'verse': verse,
      };

  String get reference => '$book $chapter:$verse';
}