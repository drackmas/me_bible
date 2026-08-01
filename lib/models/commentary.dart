class Highlight {
  final String text;
  final String color;

  Highlight({
    required this.text,
    this.color = 'yellow',
  });

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      text: json['text'] as String,
      color: json['color'] as String? ?? 'yellow',
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'color': color,
      };
}

class HashTag {
  final String text; // without the # symbol
  final String color; // "red" or "green"

  HashTag({
    required this.text,
    required this.color,
  });

  factory HashTag.fromJson(Map<String, dynamic> json) {
    return HashTag(
      text: json['text'] as String,
      color: json['color'] as String? ?? 'green',
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'color': color,
      };
}

class Commentary {
  final int chapter;
  final int verse;
  String text;
  List<Highlight> highlights;
  List<HashTag> hashtags;
  DateTime updatedAt;

  Commentary({
    required this.chapter,
    required this.verse,
    required this.text,
    List<Highlight>? highlights,
    List<HashTag>? hashtags,
    DateTime? updatedAt,
  })  : highlights = highlights ?? [],
        hashtags = hashtags ?? [],
        updatedAt = updatedAt ?? DateTime.now();

  factory Commentary.fromJson(Map<String, dynamic> json) {
    return Commentary(
      chapter: json['chapter'] as int,
      verse: json['verse'] as int,
      text: json['text'] as String? ?? '',
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => Highlight.fromJson(e))
              .toList() ??
          [],
      hashtags: (json['hashtags'] as List<dynamic>?)
              ?.map((e) => HashTag.fromJson(e))
              .toList() ??
          [],
      updatedAt: DateTime.parse(
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'chapter': chapter,
        'verse': verse,
        'text': text,
        'highlights': highlights.map((h) => h.toJson()).toList(),
        'hashtags': hashtags.map((h) => h.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
