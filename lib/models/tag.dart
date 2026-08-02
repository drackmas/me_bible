class Tag {
  final String name;          // What is shown to the user
  final String phrase;        // Main search phrase
  final List<String> variants; // Extra phrases that should also match
  List<TagOccurrence> occurrences;

  Tag({
    required this.name,
    required this.phrase,
    List<String>? variants,
    List<TagOccurrence>? occurrences,
  })  : variants = variants ?? [],
        occurrences = occurrences ?? [];

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'] as String,
      phrase: json['phrase'] as String,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      occurrences: (json['occurrences'] as List<dynamic>?)
              ?.map((e) => TagOccurrence.fromJson(e))
              .toList() ??
          [],
    );
  }

  /// Clean version used for export (no occurrences)
  Map<String, dynamic> toJson() => {
        'name': name,
        'phrase': phrase,
        'variants': variants,
      };

  /// Full version used for local storage
  Map<String, dynamic> toJsonFull() => {
        'name': name,
        'phrase': phrase,
        'variants': variants,
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