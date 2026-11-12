import 'package:custom_editor/src/text_editor/editor_style_range.dart';
import 'package:flutter/material.dart';

class RichTextController extends TextEditingController {
  List<EditorStyleRange> ranges;
  late String _previousText;

  RichTextController({String text = '', List<EditorStyleRange>? ranges})
    : ranges = ranges ?? [],
      super(text: text) {
    _previousText = text;
    addListener(_handleTextChange);
    _normalizeRanges();
  }
  void syncTypingStyleWithSelection() {
    final selection = value.selection;

    if (!selection.isValid || text.isEmpty) return;

    final index = selection.isCollapsed
        ? (selection.baseOffset > 0 ? selection.baseOffset - 1 : 0)
        : selection.start;

    if (index < 0 || index >= text.length) return;

    final current = _styleAt(index);

    typingStyles.clear();

    if (current.bold) typingStyles.add('bold');
    if (current.italic) typingStyles.add('italic');
    if (current.underline) typingStyles.add('underline');
    if (current.strike) typingStyles.add('strike');

    notifyListeners();
  }

  final Set<String> typingStyles = {};
  void toggleTypingStyle(String style) {
    if (!typingStyles.add(style)) {
      typingStyles.remove(style);
    }

    notifyListeners();
  }

  void _handleTextChange() {
    if (text != _previousText) {
      _adjustRanges(_previousText, text);
      _previousText = text;
    }
  }

  EditorStyleRange _styleAt(int index) {
    for (final range in ranges) {
      if (index >= range.start && index < range.end) {
        return range;
      }
    }
    return const EditorStyleRange(start: 0, end: 0);
  }

  List<EditorStyleRange> _expandStyles(String value) {
    return List.generate(value.length, _styleAt);
  }

  void _adjustRanges(String oldText, String newText) {
    var prefix = 0;

    while (prefix < oldText.length &&
        prefix < newText.length &&
        oldText[prefix] == newText[prefix]) {
      prefix++;
    }

    var suffix = 0;

    while (suffix < oldText.length - prefix &&
        suffix < newText.length - prefix &&
        oldText[oldText.length - 1 - suffix] ==
            newText[newText.length - 1 - suffix]) {
      suffix++;
    }

    final oldEnd = oldText.length - suffix;
    final newEnd = newText.length - suffix;
    final oldStyles = _expandStyles(oldText);
    final newStyles = <EditorStyleRange>[];

    for (var i = 0; i < prefix; i++) {
      newStyles.add(oldStyles[i]);
    }

    var inherited = const EditorStyleRange(start: 0, end: 0);

    if (prefix > 0 && oldStyles.isNotEmpty) {
      inherited = oldStyles[prefix - 1];
    }

    for (final style in typingStyles) {
      inherited = _changeStyle(inherited, style, true);
    }

    for (final style in ['bold', 'italic', 'underline', 'strike']) {
      if (!typingStyles.contains(style) && prefix > 0 && oldStyles.isNotEmpty) {
        inherited = _changeStyle(inherited, style, false);
      }
    }

    for (var i = prefix; i < newEnd; i++) {
      newStyles.add(inherited);
    }

    for (var i = oldEnd; i < oldText.length; i++) {
      newStyles.add(oldStyles[i]);
    }

    ranges = _compressStyles(newStyles);
  }

  List<EditorStyleRange> _compressStyles(
    List<EditorStyleRange> characterStyles,
  ) {
    final result = <EditorStyleRange>[];

    for (var i = 0; i < characterStyles.length; i++) {
      final current = characterStyles[i];

      if (!current.bold &&
          !current.italic &&
          !current.underline &&
          !current.strike &&
          current.link == null &&
          current.color == null &&
          current.backgroundColor == null) {
        continue;
      }

      if (result.isNotEmpty) {
        final previous = result.last;

        if (previous.end == i && previous.sameStyle(current)) {
          result[result.length - 1] = previous.copyWith(end: i + 1);
          continue;
        }
      }

      result.add(
        EditorStyleRange(
          start: i,
          end: i + 1,
          bold: current.bold,
          italic: current.italic,
          underline: current.underline,
          strike: current.strike,
          link: current.link,
          color: current.color,
          backgroundColor: current.backgroundColor,
        ),
      );
    }

    return result;
  }

  void _normalizeRanges() {
    ranges =
        ranges
            .where(
              (range) =>
                  range.start >= 0 &&
                  range.end > range.start &&
                  range.end <= text.length,
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
  }

  bool _styleValue(EditorStyleRange range, String style) {
    switch (style) {
      case 'bold':
        return range.bold;
      case 'italic':
        return range.italic;
      case 'underline':
        return range.underline;
      case 'strike':
        return range.strike;
      default:
        return false;
    }
  }

  bool isStyleActive(String style) {
    final selection = value.selection;

    if (text.isEmpty) return false;

    if (selection.isCollapsed) {
      final index = selection.baseOffset > 0
          ? selection.baseOffset - 1
          : selection.baseOffset;

      if (index < 0 || index >= text.length) return false;
      return _styleValue(_styleAt(index), style);
    }

    if (!selection.isValid || selection.end > text.length) return false;

    for (var i = selection.start; i < selection.end; i++) {
      if (!_styleValue(_styleAt(i), style)) return false;
    }

    return true;
  }

  EditorStyleRange _changeStyle(
    EditorStyleRange old,
    String style,
    bool enabled,
  ) {
    return EditorStyleRange(
      start: old.start,
      end: old.end,
      bold: style == 'bold' ? enabled : old.bold,
      italic: style == 'italic' ? enabled : old.italic,
      underline: style == 'underline' ? enabled : old.underline,
      strike: style == 'strike' ? enabled : old.strike,
      link: old.link,
      color: old.color,
      backgroundColor: old.backgroundColor,
    );
  }

  void toggleStyle(String style) {
    final selection = value.selection;

    if (!selection.isValid ||
        selection.isCollapsed ||
        selection.start < 0 ||
        selection.end > text.length) {
      return;
    }

    final characterStyles = _expandStyles(text);
    final enable = !isStyleActive(style);

    for (var i = selection.start; i < selection.end; i++) {
      characterStyles[i] = _changeStyle(characterStyles[i], style, enable);
    }

    ranges = _compressStyles(characterStyles);
    notifyListeners();
  }

  void applyColor(int? color, {bool highlight = false}) {
    final selection = value.selection;

    if (!selection.isValid ||
        selection.isCollapsed ||
        selection.end > text.length) {
      return;
    }

    final characterStyles = _expandStyles(text);

    for (var i = selection.start; i < selection.end; i++) {
      final old = characterStyles[i];

      characterStyles[i] = EditorStyleRange(
        start: old.start,
        end: old.end,
        bold: old.bold,
        italic: old.italic,
        underline: old.underline,
        strike: old.strike,
        link: old.link,
        color: highlight ? old.color : color,
        backgroundColor: highlight ? color : old.backgroundColor,
      );
    }

    ranges = _compressStyles(characterStyles);
    notifyListeners();
  }

  void applyLink(int start, int end, String url) {
    if (start < 0 || end > text.length || start >= end) return;

    final characterStyles = _expandStyles(text);

    for (var i = start; i < end; i++) {
      final old = characterStyles[i];

      characterStyles[i] = EditorStyleRange(
        start: old.start,
        end: old.end,
        bold: old.bold,
        italic: old.italic,
        underline: true,
        strike: old.strike,
        link: url,
        color: old.color,
        backgroundColor: old.backgroundColor,
      );
    }

    ranges = _compressStyles(characterStyles);
    notifyListeners();
  }

  void removeLink(int start, int end) {
    if (start < 0 || end > text.length || start >= end) return;

    final characterStyles = _expandStyles(text);

    for (var i = start; i < end; i++) {
      final old = characterStyles[i];

      characterStyles[i] = EditorStyleRange(
        start: old.start,
        end: old.end,
        bold: old.bold,
        italic: old.italic,
        underline: old.link == null ? old.underline : false,
        strike: old.strike,
        color: old.color,
        backgroundColor: old.backgroundColor,
      );
    }

    ranges = _compressStyles(characterStyles);
    notifyListeners();
  }

  TextStyle _styleFor(EditorStyleRange range, TextStyle base) {
    return base.copyWith(
      fontWeight: range.bold ? FontWeight.bold : null,
      fontStyle: range.italic ? FontStyle.italic : null,
      decoration: TextDecoration.combine([
        if (range.underline) TextDecoration.underline,
        if (range.strike) TextDecoration.lineThrough,
      ]),
      color: range.color != null
          ? Color(range.color!)
          : range.link != null
          ? Colors.blue
          : null,
      backgroundColor: range.backgroundColor != null
          ? Color(range.backgroundColor!)
          : null,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty) return TextSpan(text: text, style: style);

    final baseStyle = style ?? const TextStyle();
    final spans = <TextSpan>[];
    var start = 0;

    while (start < text.length) {
      final current = _styleAt(start);
      var end = start + 1;

      while (end < text.length && current.sameStyle(_styleAt(end))) {
        end++;
      }

      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: _styleFor(current, baseStyle),
        ),
      );

      start = end;
    }

    return TextSpan(style: baseStyle, children: spans);
  }

  @override
  void dispose() {
    removeListener(_handleTextChange);
    super.dispose();
  }
}
