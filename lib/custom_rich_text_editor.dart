import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

enum EditorBlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  bulletList,
  numberedList,
  image,
  table,
}

class EditorStyleRange {
  final int start;
  final int end;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final String? link;

  const EditorStyleRange({
    required this.start,
    required this.end,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.link,
  });

  EditorStyleRange copyWith({
    int? start,
    int? end,
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    String? link,
    bool clearLink = false,
  }) {
    return EditorStyleRange(
      start: start ?? this.start,
      end: end ?? this.end,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strike: strike ?? this.strike,
      link: clearLink ? null : link ?? this.link,
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
    );
  }

  bool sameStyle(EditorStyleRange other) {
    return bold == other.bold &&
        italic == other.italic &&
        underline == other.underline &&
        strike == other.strike &&
        link == other.link;
  }
}

class EditorBlock {
  final String id;
  EditorBlockType type;
  String text;
  TextAlign alignment;
  String? imagePath;
  List<List<String>>? table;
  List<EditorStyleRange> styles;

  // Kept for compatibility with older document data.
  bool bold;
  bool italic;
  bool underline;
  bool strike;
  String? link;

  EditorBlock({
    String? id,
    this.type = EditorBlockType.paragraph,
    this.text = '',
    this.alignment = TextAlign.left,
    this.imagePath,
    this.table,
    List<EditorStyleRange>? styles,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.link,
  }) : id = id ?? const Uuid().v4(),
       styles = styles ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'text': text,
    'alignment': alignment.name,
    'imagePath': imagePath,
    'table': table,
    'styles': styles.map((e) => e.toJson()).toList(),
    'bold': bold,
    'italic': italic,
    'underline': underline,
    'strike': strike,
    'link': link,
  };

  factory EditorBlock.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String?;

    return EditorBlock(
      id: json['id'],
      type: EditorBlockType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => EditorBlockType.paragraph,
      ),
      text: json['text'] ?? '',
      alignment: TextAlign.values.firstWhere(
        (e) => e.name == json['alignment'],
        orElse: () => TextAlign.left,
      ),
      imagePath: json['imagePath'],
      table: (json['table'] as List?)
          ?.map((row) => List<String>.from(row))
          .toList(),
      styles:
          (json['styles'] as List?)
              ?.map(
                (e) => EditorStyleRange.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList() ??
          [],
      bold: json['bold'] ?? false,
      italic: json['italic'] ?? false,
      underline: json['underline'] ?? false,
      strike: json['strike'] ?? false,
      link: json['link'],
    );
  }
}

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
    return List.generate(value.length, (index) => _styleAt(index));
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

    EditorStyleRange inheritedStyle = const EditorStyleRange(start: 0, end: 0);

    if (oldStyles.isNotEmpty) {
      final inheritedIndex = prefix > 0 ? prefix - 1 : prefix;
      if (inheritedIndex < oldStyles.length) {
        inheritedStyle = oldStyles[inheritedIndex];
      }
    }

    for (var i = prefix; i < newEnd; i++) {
      newStyles.add(inheritedStyle);
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
          current.link == null) {
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

    final start = selection.start;
    final end = selection.end;

    if (start < 0 || end > text.length) return false;

    for (var i = start; i < end; i++) {
      if (!_styleValue(_styleAt(i), style)) {
        return false;
      }
    }

    return true;
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

  void toggleStyle(String style) {
    final selection = value.selection;

    if (!selection.isValid ||
        selection.isCollapsed ||
        selection.start < 0 ||
        selection.end > text.length) {
      return;
    }

    final characterStyles = _expandStyles(text);

    final shouldEnable = !isStyleActive(style);

    for (var i = selection.start; i < selection.end; i++) {
      final old = characterStyles[i];

      characterStyles[i] = _changeStyle(old, style, shouldEnable);
    }

    ranges = _compressStyles(characterStyles);
    notifyListeners();
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
    );
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
      color: range.link != null ? Colors.blue : null,
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (text.isEmpty) {
      return TextSpan(text: text, style: style);
    }

    final baseStyle = style ?? const TextStyle();
    final spans = <TextSpan>[];

    var start = 0;

    while (start < text.length) {
      final currentStyle = _styleAt(start);
      var end = start + 1;

      while (end < text.length && currentStyle.sameStyle(_styleAt(end))) {
        end++;
      }

      spans.add(
        TextSpan(
          text: text.substring(start, end),
          style: _styleFor(currentStyle, baseStyle),
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

class CustomRichTextEditor extends StatefulWidget {
  final String initialText;
  final String hintText;
  final double minHeight;
  final ValueChanged<String>? onChanged;
  final ValueChanged<List<EditorBlock>>? onDocumentChanged;

  const CustomRichTextEditor({
    super.key,
    this.initialText = '',
    this.hintText = 'Write something...',
    this.minHeight = 300,
    this.onChanged,
    this.onDocumentChanged,
  });

  @override
  State<CustomRichTextEditor> createState() => CustomRichTextEditorState();
}

class CustomRichTextEditorState extends State<CustomRichTextEditor> {
  final List<EditorBlock> _blocks = [];
  final Map<String, RichTextController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  final ImagePicker _imagePicker = ImagePicker();

  int _selectedIndex = 0;

  EditorBlock? get _selectedBlock {
    if (_selectedIndex < 0 || _selectedIndex >= _blocks.length) {
      return null;
    }

    return _blocks[_selectedIndex];
  }

  RichTextController? get _selectedController {
    final block = _selectedBlock;

    if (block == null) return null;

    return _controllers[block.id];
  }

  List<EditorBlock> get document => List.unmodifiable(_blocks);

  @override
  void initState() {
    super.initState();

    _blocks.add(EditorBlock(text: widget.initialText));

    _syncControllers();
  }

  void _syncControllers() {
    for (final block in _blocks) {
      if (block.type == EditorBlockType.paragraph ||
          block.type == EditorBlockType.heading1 ||
          block.type == EditorBlockType.heading2 ||
          block.type == EditorBlockType.heading3 ||
          block.type == EditorBlockType.bulletList ||
          block.type == EditorBlockType.numberedList) {
        if (!_controllers.containsKey(block.id)) {
          final initialStyles = List<EditorStyleRange>.from(block.styles);

          if (initialStyles.isEmpty &&
              block.text.isNotEmpty &&
              (block.bold ||
                  block.italic ||
                  block.underline ||
                  block.strike ||
                  block.link != null)) {
            initialStyles.add(
              EditorStyleRange(
                start: 0,
                end: block.text.length,
                bold: block.bold,
                italic: block.italic,
                underline: block.underline,
                strike: block.strike,
                link: block.link,
              ),
            );
          }

          final controller = RichTextController(
            text: block.text,
            ranges: initialStyles,
          );

          controller.addListener(() {
            block.text = controller.text;
            block.styles = List<EditorStyleRange>.from(controller.ranges);

            if (mounted) {
              setState(() {});
            }

            _notifyDocumentChanged();
          });

          _controllers[block.id] = controller;
          _focusNodes[block.id] = FocusNode();
        }
      }
    }

    final validIds = _blocks.map((e) => e.id).toSet();

    for (final id in _controllers.keys.toList()) {
      if (!validIds.contains(id)) {
        _controllers.remove(id)?.dispose();
        _focusNodes.remove(id)?.dispose();
      }
    }
  }

  void _notifyDocumentChanged() {
    widget.onChanged?.call(toPlainText());
    widget.onDocumentChanged?.call(List.unmodifiable(_blocks));
  }

  void _insertBlock(EditorBlock block) {
    setState(() {
      final index = _selectedIndex.clamp(0, _blocks.length - 1);
      _blocks.insert(index + 1, block);
      _selectedIndex = index + 1;
      _syncControllers();
    });

    _notifyDocumentChanged();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _focusNodes[block.id]?.requestFocus();
    });
  }

  void _applyHeading(EditorBlockType type) {
    final block = _selectedBlock;
    final controller = _selectedController;

    if (block == null || controller == null) return;

    final selection = controller.selection;

    if (!selection.isValid || selection.isCollapsed) {
      setState(() => block.type = type);
      _notifyDocumentChanged();
      return;
    }

    final start = selection.start;
    final end = selection.end;

    final beforeText = block.text.substring(0, start);
    final selectedText = block.text.substring(start, end);
    final afterText = block.text.substring(end);

    final newBlocks = <EditorBlock>[];

    if (beforeText.isNotEmpty) {
      newBlocks.add(EditorBlock(text: beforeText));
    }

    final headingBlock = EditorBlock(type: type, text: selectedText);

    newBlocks.add(headingBlock);

    if (afterText.isNotEmpty) {
      newBlocks.add(EditorBlock(text: afterText));
    }

    setState(() {
      _blocks.removeAt(_selectedIndex);
      _blocks.insertAll(_selectedIndex, newBlocks);
      _selectedIndex += beforeText.isNotEmpty ? 1 : 0;
      _syncControllers();
    });

    _notifyDocumentChanged();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newController = _controllers[headingBlock.id];
      newController?.selection = TextSelection.collapsed(
        offset: selectedText.length,
      );
      _focusNodes[headingBlock.id]?.requestFocus();
    });
  }

  void _applyAlignment(TextAlign alignment) {
    final block = _selectedBlock;

    if (block == null) return;

    setState(() {
      block.alignment = alignment;
    });

    _notifyDocumentChanged();
  }

  void _applyList(EditorBlockType type) {
    final block = _selectedBlock;

    if (block == null) return;

    setState(() {
      block.type = type;
    });

    _notifyDocumentChanged();
  }

  void _insertParagraph() {
    _insertBlock(EditorBlock());
  }

  void _insertTable() {
    _insertBlock(
      EditorBlock(
        type: EditorBlockType.table,
        table: List.generate(2, (_) => List.generate(2, (_) => '')),
      ),
    );
  }

  Future<void> _insertImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);

    if (image == null || !mounted) return;

    _insertBlock(
      EditorBlock(type: EditorBlockType.image, imagePath: image.path),
    );
  }

  Future<void> _insertLink() async {
    final controller = _selectedController;

    if (controller == null) return;

    final selection = controller.selection;

    if (!selection.isValid || selection.isCollapsed) {
      return;
    }

    final urlController = TextEditingController();

    final url = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Insert link'),
          content: TextField(
            controller: urlController,
            decoration: const InputDecoration(hintText: 'https://example.com'),
            keyboardType: TextInputType.url,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, urlController.text.trim());
              },
              child: const Text('Insert'),
            ),
          ],
        );
      },
    );

    urlController.dispose();

    if (url == null || url.isEmpty || !mounted) return;

    controller.applyLink(selection.start, selection.end, url);

    controller.selection = selection;

    _notifyDocumentChanged();
  }

  void _removeLink() {
    final controller = _selectedController;

    if (controller == null) return;

    final selection = controller.selection;

    if (!selection.isValid || selection.isCollapsed) return;

    controller.removeLink(selection.start, selection.end);

    _notifyDocumentChanged();
  }

  void _toggleStyle(String style) {
    final controller = _selectedController;

    if (controller == null) return;

    controller.toggleStyle(style);
    _notifyDocumentChanged();
  }

  void _addTableRow(EditorBlock block) {
    setState(() {
      block.table ??= [];
      final columns = block.table!.isEmpty ? 2 : block.table!.first.length;

      block.table!.add(List.generate(columns, (_) => ''));
    });

    _notifyDocumentChanged();
  }

  void _addTableColumn(EditorBlock block) {
    setState(() {
      block.table ??= [];

      for (final row in block.table!) {
        row.add('');
      }
    });

    _notifyDocumentChanged();
  }

  void _deleteTableRow(EditorBlock block) {
    if (block.table == null || block.table!.length <= 1) return;

    setState(() {
      block.table!.removeLast();
    });

    _notifyDocumentChanged();
  }

  void _deleteTableColumn(EditorBlock block) {
    if (block.table == null ||
        block.table!.isEmpty ||
        block.table!.first.length <= 1) {
      return;
    }

    setState(() {
      for (final row in block.table!) {
        row.removeLast();
      }
    });

    _notifyDocumentChanged();
  }

  void _deleteBlock(int index) {
    if (_blocks.length <= 1) return;

    final block = _blocks[index];

    setState(() {
      _blocks.removeAt(index);
      _controllers.remove(block.id)?.dispose();
      _focusNodes.remove(block.id)?.dispose();

      _selectedIndex = (_selectedIndex - 1).clamp(0, _blocks.length - 1);
    });

    _notifyDocumentChanged();
  }

  TextStyle _blockTextStyle(EditorBlock block) {
    switch (block.type) {
      case EditorBlockType.heading1:
        return const TextStyle(fontSize: 28, fontWeight: FontWeight.bold);

      case EditorBlockType.heading2:
        return const TextStyle(fontSize: 23, fontWeight: FontWeight.bold);

      case EditorBlockType.heading3:
        return const TextStyle(fontSize: 19, fontWeight: FontWeight.bold);

      default:
        return const TextStyle(fontSize: 16);
    }
  }

  Widget _toolbarButton({
    required IconData icon,
    required String style,
    required bool active,
  }) {
    return IconButton(
      tooltip: style,
      onPressed: () => _toggleStyle(style),
      style: IconButton.styleFrom(
        backgroundColor: active
            ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
            : Colors.transparent,
        foregroundColor: active ? Theme.of(context).colorScheme.primary : null,
      ),
      icon: Icon(icon),
    );
  }

  Widget _buildToolbar() {
    final controller = _selectedController;
    final block = _selectedBlock;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          DropdownButton<EditorBlockType>(
            value:
                block != null &&
                    [
                      EditorBlockType.paragraph,
                      EditorBlockType.heading1,
                      EditorBlockType.heading2,
                      EditorBlockType.heading3,
                    ].contains(block.type)
                ? block.type
                : EditorBlockType.paragraph,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(
                value: EditorBlockType.paragraph,
                child: Text('Paragraph'),
              ),
              DropdownMenuItem(
                value: EditorBlockType.heading1,
                child: Text('Heading 1'),
              ),
              DropdownMenuItem(
                value: EditorBlockType.heading2,
                child: Text('Heading 2'),
              ),
              DropdownMenuItem(
                value: EditorBlockType.heading3,
                child: Text('Heading 3'),
              ),
            ],
            onChanged: (value) {
              if (value != null) _applyHeading(value);
            },
          ),
          const SizedBox(width: 8),
          _toolbarButton(
            icon: Icons.format_bold,
            style: 'bold',
            active: controller?.isStyleActive('bold') ?? false,
          ),
          _toolbarButton(
            icon: Icons.format_italic,
            style: 'italic',
            active: controller?.isStyleActive('italic') ?? false,
          ),
          _toolbarButton(
            icon: Icons.format_underline,
            style: 'underline',
            active: controller?.isStyleActive('underline') ?? false,
          ),
          _toolbarButton(
            icon: Icons.strikethrough_s,
            style: 'strike',
            active: controller?.isStyleActive('strike') ?? false,
          ),
          IconButton(
            tooltip: 'Align left',
            onPressed: () => _applyAlignment(TextAlign.left),
            icon: const Icon(Icons.format_align_left),
          ),
          IconButton(
            tooltip: 'Align center',
            onPressed: () => _applyAlignment(TextAlign.center),
            icon: const Icon(Icons.format_align_center),
          ),
          IconButton(
            tooltip: 'Align right',
            onPressed: () => _applyAlignment(TextAlign.right),
            icon: const Icon(Icons.format_align_right),
          ),
          IconButton(
            tooltip: 'Justify',
            onPressed: () => _applyAlignment(TextAlign.justify),
            icon: const Icon(Icons.format_align_justify),
          ),
          IconButton(
            tooltip: 'Bullet list',
            onPressed: () => _applyList(EditorBlockType.bulletList),
            icon: const Icon(Icons.format_list_bulleted),
          ),
          IconButton(
            tooltip: 'Numbered list',
            onPressed: () => _applyList(EditorBlockType.numberedList),
            icon: const Icon(Icons.format_list_numbered),
          ),
          IconButton(
            tooltip: 'Insert link',
            onPressed: _insertLink,
            icon: const Icon(Icons.link),
          ),
          IconButton(
            tooltip: 'Remove link',
            onPressed: _removeLink,
            icon: const Icon(Icons.link_off),
          ),
          IconButton(
            tooltip: 'Insert image',
            onPressed: _insertImage,
            icon: const Icon(Icons.image_outlined),
          ),
          IconButton(
            tooltip: 'Insert table',
            onPressed: _insertTable,
            icon: const Icon(Icons.table_chart_outlined),
          ),
          IconButton(
            tooltip: 'New paragraph',
            onPressed: _insertParagraph,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBlock(EditorBlock block, int index) {
    final controller = _controllers[block.id]!;

    Widget editor = TextField(
      controller: controller,
      focusNode: _focusNodes[block.id],
      maxLines: null,
      minLines: 1,
      textAlign: block.alignment,
      style: _blockTextStyle(block),
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );

    if (block.type == EditorBlockType.bulletList) {
      editor = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8, top: 2),
            child: Text('•'),
          ),
          Expanded(child: editor),
        ],
      );
    }

    if (block.type == EditorBlockType.numberedList) {
      editor = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8, top: 2),
            child: Text('1.'),
          ),
          Expanded(child: editor),
        ],
      );
    }

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: editor,
    );
  }

  Widget _buildImage(EditorBlock block, int index) {
    final path = block.imagePath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (path != null && File(path).existsSync())
          Image.file(File(path), height: 180, fit: BoxFit.contain),
        IconButton(
          onPressed: () => _deleteBlock(index),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }

  Widget _buildTable(EditorBlock block) {
    final table = block.table ?? [];

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Add row',
              onPressed: () => _addTableRow(block),
              icon: const Icon(Icons.add_box_outlined),
            ),
            IconButton(
              tooltip: 'Remove row',
              onPressed: () => _deleteTableRow(block),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            IconButton(
              tooltip: 'Add column',
              onPressed: () => _addTableColumn(block),
              icon: const Icon(Icons.view_column_outlined),
            ),
            IconButton(
              tooltip: 'Remove column',
              onPressed: () => _deleteTableColumn(block),
              icon: const Icon(Icons.remove_circle_outline),
            ),
          ],
        ),
        if (table.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade400),
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: List.generate(table.length, (rowIndex) {
                return TableRow(
                  children: List.generate(table[rowIndex].length, (
                    columnIndex,
                  ) {
                    return Padding(
                      padding: const EdgeInsets.all(6),
                      child: SizedBox(
                        width: 120,
                        child: TextFormField(
                          key: ValueKey('${block.id}_${rowIndex}_$columnIndex'),
                          initialValue: table[rowIndex][columnIndex],
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),

                          onChanged: (value) {
                            block.table![rowIndex][columnIndex] = value;
                            _notifyDocumentChanged();
                          },
                        ),
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildBlock(EditorBlock block, int index) {
    Widget content;

    switch (block.type) {
      case EditorBlockType.image:
        content = _buildImage(block, index);
        break;

      case EditorBlockType.table:
        content = _buildTable(block);
        break;

      default:
        content = _buildTextBlock(block, index);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: content),
          // IconButton(
          //   visualDensity: VisualDensity.compact,
          //   tooltip: 'Delete block',
          //   onPressed: () => _deleteBlock(index),
          //   icon: const Icon(Icons.close, size: 17, color: Colors.amber),
          // ),
        ],
      ),
    );
  }

  String toPlainText() {
    final result = <String>[];

    for (final block in _blocks) {
      switch (block.type) {
        case EditorBlockType.image:
          result.add('[Image: ${block.imagePath ?? ''}]');
          break;

        case EditorBlockType.table:
          final rows = block.table ?? [];
          result.add(rows.map((row) => row.join(' | ')).join('\n'));
          break;

        case EditorBlockType.bulletList:
          result.add('• ${block.text}');
          break;

        case EditorBlockType.numberedList:
          result.add('1. ${block.text}');
          break;

        default:
          result.add(block.text);
      }
    }

    return result.join('\n\n');
  }

  Map<String, dynamic> toJson() {
    return {'blocks': _blocks.map((block) => block.toJson()).toList()};
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _inlineHtml(EditorBlock block) {
    final text = block.text;

    if (text.isEmpty) return '';

    final controller = _controllers[block.id];

    final ranges = controller?.ranges ?? block.styles;

    String result = '';

    for (var i = 0; i < text.length;) {
      EditorStyleRange? style;

      for (final range in ranges) {
        if (i >= range.start && i < range.end) {
          style = range;
          break;
        }
      }

      var end = i + 1;

      while (end < text.length) {
        EditorStyleRange? nextStyle;

        for (final range in ranges) {
          if (end >= range.start && end < range.end) {
            nextStyle = range;
            break;
          }
        }

        if (!_sameNullableStyle(style, nextStyle)) break;

        end++;
      }

      var value = _escapeHtml(text.substring(i, end)).replaceAll('\n', '<br>');

      if (style != null) {
        if (style.bold) value = '<strong>$value</strong>';
        if (style.italic) value = '<em>$value</em>';
        if (style.underline) value = '<u>$value</u>';
        if (style.strike) value = '<s>$value</s>';

        if (style.link != null) {
          value = '<a href="${_escapeHtml(style.link!)}">$value</a>';
        }
      }

      result += value;
      i = end;
    }

    return result;
  }

  bool _sameNullableStyle(EditorStyleRange? first, EditorStyleRange? second) {
    if (first == null && second == null) return true;
    if (first == null || second == null) return false;

    return first.sameStyle(second);
  }

  String toHtml() {
    final result = StringBuffer();

    for (final block in _blocks) {
      final alignment = block.alignment.name;

      switch (block.type) {
        case EditorBlockType.heading1:
          result.writeln(
            '<h1 style="text-align:$alignment">${_inlineHtml(block)}</h1>',
          );
          break;

        case EditorBlockType.heading2:
          result.writeln(
            '<h2 style="text-align:$alignment">${_inlineHtml(block)}</h2>',
          );
          break;

        case EditorBlockType.heading3:
          result.writeln(
            '<h3 style="text-align:$alignment">${_inlineHtml(block)}</h3>',
          );
          break;

        case EditorBlockType.bulletList:
          result.writeln('<ul><li>${_inlineHtml(block)}</li></ul>');
          break;

        case EditorBlockType.numberedList:
          result.writeln('<ol><li>${_inlineHtml(block)}</li></ol>');
          break;

        case EditorBlockType.image:
          if (block.imagePath != null) {
            result.writeln('<img src="${_escapeHtml(block.imagePath!)}" />');
          }
          break;

        case EditorBlockType.table:
          result.writeln('<table border="1">');

          for (final row in block.table ?? []) {
            result.writeln('<tr>');

            for (final cell in row) {
              result.writeln('<td>${_escapeHtml(cell)}</td>');
            }

            result.writeln('</tr>');
          }

          result.writeln('</table>');
          break;

        default:
          result.writeln(
            '<p style="text-align:$alignment">${_inlineHtml(block)}</p>',
          );
      }
    }

    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: widget.minHeight),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(),
          Divider(height: 1, color: Colors.grey.shade300),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(
                _blocks.length,
                (index) => _buildBlock(_blocks[index], index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }

    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }

    super.dispose();
  }
}
