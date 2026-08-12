class Bookmark {
  final String id;
  String name;
  List<BookmarkVerse> verses;

  Bookmark({
    required this.id,
    required this.name,
    List<BookmarkVerse>? verses,
  }) : verses = verses ?? [];

  factory Bookmark.fromJson(Map<String, dynamic> json) {
    return Bookmark(
      id: json['id'] as String,
      name: json['name'] as String,
      verses: (json['verses'] as List<dynamic>?)
              ?.map((e) => BookmarkVerse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'verses': verses.map((v) => v.toJson()).toList(),
      };
}

class BookmarkVerse {
  final String book;
  final int chapter;
  final int verse;

  BookmarkVerse({
    required this.book,
    required this.chapter,
    required this.verse,
  });

  factory BookmarkVerse.fromJson(Map<String, dynamic> json) {
    return BookmarkVerse(
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookmarkVerse &&
          book == other.book &&
          chapter == other.chapter &&
          verse == other.verse;

  @override
  int get hashCode => Object.hash(book, chapter, verse);
}
