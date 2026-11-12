class EditorStyleRange {
  final int start;
  final int end;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final String? link;
  final int? color;
  final int? backgroundColor;

  const EditorStyleRange({
    required this.start,
    required this.end,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.link,
    this.color,
    this.backgroundColor,
  });

  EditorStyleRange copyWith({
    int? start,
    int? end,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    String? link,
    int? color,
    int? backgroundColor,
    bool clearLink = false,
    bool clearColor = false,
    bool clearBackgroundColor = false,
  }) {
    return EditorStyleRange(
      start: start ?? this.start,
      end: end ?? this.end,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strike: strike ?? this.strike,
      link: clearLink ? null : link ?? this.link,
      color: clearColor ? null : color ?? this.color,
      backgroundColor: clearBackgroundColor
          ? null
          : backgroundColor ?? this.backgroundColor,
    );
  }

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'bold': bold,
    'italic': italic,
    'underline': underline,
    'strike': strike,
    'link': link,
    'color': color,
    'backgroundColor': backgroundColor,
  };

  factory EditorStyleRange.fromJson(Map<String, dynamic> json) {
    return EditorStyleRange(
      start: json['start'] ?? 0,
      end: json['end'] ?? 0,
      bold: json['bold'] ?? false,
      italic: json['italic'] ?? false,
      underline: json['underline'] ?? false,
      strike: json['strike'] ?? false,
      link: json['link'],
      color: json['color'],
      backgroundColor: json['backgroundColor'],
    );
  }

  bool sameStyle(EditorStyleRange other) {
    return bold == other.bold &&
        italic == other.italic &&
        underline == other.underline &&
        strike == other.strike &&
        link == other.link &&
        color == other.color &&
        backgroundColor == other.backgroundColor;
  }
}
