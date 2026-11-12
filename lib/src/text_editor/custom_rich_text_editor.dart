// ignore_for_file: unused_element

import 'dart:convert';
import 'dart:io';

import 'package:custom_editor/src/text_editor/editor_block.dart';
import 'package:custom_editor/src/text_editor/editor_enums.dart';
import 'package:custom_editor/src/text_editor/editor_style_range.dart';
import 'package:custom_editor/src/text_editor/insert_link_dialog.dart';
import 'package:custom_editor/src/text_editor/rich_text_controller.dart';
import 'package:custom_editor/src/widgets/import_image_shape_sheet.dart';
import 'package:custom_editor/src/widgets/insert_shap_sheet.dart';
import 'package:custom_editor/src/widgets/shape_preview_painter.dart';
import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

class CustomRichTextEditor extends StatefulWidget {
  final String initialText;
  final String hintText;
  final double minHeight;
  final ValueChanged<String>? onChanged;
  final ValueChanged<List<EditorBlock>>? onDocumentChanged;
  final TextEditingController controller;
  final ValueChanged<String> onInsertMarkup;
  const CustomRichTextEditor({
    super.key,
    this.initialText = '',
    this.hintText = 'Write something...',
    this.minHeight = 300,
    this.onChanged,
    this.onDocumentChanged,
    required this.controller,
    required this.onInsertMarkup,
  });

  @override
  State<CustomRichTextEditor> createState() => CustomRichTextEditorState();
}

class CustomRichTextEditorState extends State<CustomRichTextEditor> {
  final List<EditorBlock> _blocks = [];
  final Map<String, RichTextController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  int _selectedIndex = 0;

  static const List<Color> _palette = [
    Color(0xFF1B365D),
    Color(0xFF2563EB),
    Color(0xFFDC2626),
    Color(0xFF16A34A),
    Color(0xFF9333EA),
    Color(0xFFF59E0B),
    Color(0xFF111827),
    Color(0xFF64748B),
    Color(0xFFFEF08A),
    Color(0xFFFECACA),
    Color(0xFFBFDBFE),
    Color(0xFFBBF7D0),
  ];

  EditorBlock? get _selectedBlock {
    if (_selectedIndex < 0 || _selectedIndex >= _blocks.length) {
      return null;
    }
    return _blocks[_selectedIndex];
  }

  RichTextController? get _selectedController {
    final block = _selectedBlock;
    return block == null ? null : _controllers[block.id];
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
      if (_isTextBlock(block.type) && !_controllers.containsKey(block.id)) {
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

          if (mounted && _selectedIndex == _blocks.indexOf(block)) {
            setState(() {});
          }

          _notifyDocumentChanged();
        });

        _controllers[block.id] = controller;
        _focusNodes[block.id] = FocusNode();
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

  bool _isTextBlock(EditorBlockType type) {
    return [
      EditorBlockType.paragraph,
      EditorBlockType.heading1,
      EditorBlockType.heading2,
      EditorBlockType.heading3,
      EditorBlockType.bulletList,
      EditorBlockType.numberedList,
    ].contains(type);
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
      _controllers[headingBlock.id]?.selection = TextSelection.collapsed(
        offset: selectedText.length,
      );
      _focusNodes[headingBlock.id]?.requestFocus();
    });
  }

  void _applyAlignment(TextAlign alignment) {
    final block = _selectedBlock;
    if (block == null || !_isTextBlock(block.type)) return;

    setState(() {
      block.alignment = alignment;
    });

    _notifyDocumentChanged();
  }

  void _applyList(EditorBlockType type) {
    final controller = _selectedController;
    final block = _selectedBlock;

    if (controller == null || block == null) return;
    if (!_isTextBlock(block.type)) return;

    final selection = controller.selection;
    final text = controller.text;

    if (!selection.isValid || selection.isCollapsed) {
      setState(() {
        block.type = type;
      });

      _notifyDocumentChanged();
      return;
    }

    final start = selection.start <= 0
        ? 0
        : text.lastIndexOf('\n', selection.start - 1) + 1;

    final nextNewLine = text.indexOf('\n', selection.end);
    final end = nextNewLine == -1 ? text.length : nextNewLine;

    final selectedText = text.substring(start, end);
    final lines = selectedText.split('\n');

    final selectedIndex = _blocks.indexOf(block);

    final newBlocks = <EditorBlock>[];

    for (final line in lines) {
      final newBlock = EditorBlock(
        id: const Uuid().v4(),
        type: type,
        text: line,
      );

      newBlocks.add(newBlock);

      _controllers[newBlock.id] = RichTextController();
      _controllers[newBlock.id]!.text = line;

      _focusNodes[newBlock.id] = FocusNode();
    }

    final remainingText = text.replaceRange(start, end, '');

    setState(() {
      block.text = remainingText;
      controller.text = remainingText;

      _blocks.insertAll(selectedIndex + 1, newBlocks);

      _selectedIndex = selectedIndex + 1;
    });

    _notifyDocumentChanged();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (newBlocks.isNotEmpty) {
        _focusNodes[newBlocks.first.id]?.requestFocus();
      }
    });
  }

  void _insertNextListBlock(EditorBlock block, int index) {
    final newBlock = EditorBlock(
      id: const Uuid().v4(),
      type: block.type,
      text: '',
    );

    setState(() {
      _blocks.insert(index + 1, newBlock);

      _controllers[newBlock.id] = RichTextController();
      _focusNodes[newBlock.id] = FocusNode();

      _selectedIndex = index + 1;
    });

    _notifyDocumentChanged();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[newBlock.id]?.requestFocus();
    });
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

  void _wrapSelection(String prefix, [String suffix = '']) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;

    if (!selection.isValid || selection.isCollapsed) {
      final insert = '$prefix$suffix';
      final newText = text + insert;
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: text.length + prefix.length,
      );
      widget.onInsertMarkup(newText);
      return;
    }

    final selectedText = text.substring(selection.start, selection.end);
    final replacement = '$prefix$selectedText$suffix';
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      replacement,
    );
    widget.controller.text = newText;
    widget.controller.selection = TextSelection(
      baseOffset: selection.start + prefix.length,
      extentOffset: selection.start + prefix.length + selectedText.length,
    );
    widget.onInsertMarkup(newText);
  }

  Future<void> _insertImage() async {
    await ImportPositionImageSheet.show(context, (markup) {
      String? getAttribute(String name) {
        return RegExp('$name="([^"]*)"').firstMatch(markup)?.group(1);
      }

      final src = getAttribute('src');
      if (src == null) return;

      _insertBlock(
        EditorBlock(
          type: EditorBlockType.image,
          imagePath: src.replaceAll('&amp;', '&').replaceAll('&quot;', '"'),
          imageWidth: getAttribute('data-image-width'),
          imageMargin: getAttribute('data-image-margin'),
          imageRadius: double.tryParse(
            (getAttribute('data-image-radius') ?? '0px').replaceAll('px', ''),
          ),
          imageBorder: getAttribute('data-image-border'),
          imageAlignment: getAttribute('data-image-alignment'),
        ),
      );
    });
  }

  Future<void> _insertShape() async {
    await InsertShapeSheet.show(context, (markup) {
      final shapeMatch = RegExp(r'data-shape="([^"]+)"').firstMatch(markup);
      final fillMatch = RegExp(r'data-fill-color="([^"]+)"').firstMatch(markup);
      final borderMatch = RegExp(r'data-border-color="([^"]+)"')
          .firstMatch(markup);
      final widthMatch = RegExp(r'data-width="([^"]+)"').firstMatch(markup);
      final heightMatch = RegExp(r'data-height="([^"]+)"').firstMatch(markup);

      if (shapeMatch == null) return;

      final shapeType = switch (shapeMatch.group(1)) {
        'square' => EditorShapeType.rectangle,
        'diamond' => EditorShapeType.diamond,
        'triangle' => EditorShapeType.triangle,
        'star' => EditorShapeType.star,
        'circle' => EditorShapeType.circle,
        'horizontalLine' => EditorShapeType.line,
        'arrowRight' ||
        'arrowLeft' ||
        'arrowUp' ||
        'arrowDown' => EditorShapeType.arrow,
        _ => EditorShapeType.rectangle,
      };

      final fillColor = fillMatch?.group(1) ?? '#E11D48';
      final borderColor = borderMatch?.group(1) ?? '#1D4ED8';

      final colorHex = fillColor == 'transparent' ? borderColor : fillColor;

      final colorValue = int.tryParse(
        colorHex.replaceFirst('#', ''),
        radix: 16,
      );

      _insertBlock(
        EditorBlock(
          type: EditorBlockType.shape,
          shapeType: shapeType,
          shapeColor: 0xFF000000 | (colorValue ?? 0xFFE11D48),
          shapeWidth:
              double.tryParse(
                widthMatch?.group(1)?.replaceAll('px', '') ?? '',
              ) ??
              180,
          shapeHeight:
              double.tryParse(
                heightMatch?.group(1)?.replaceAll('px', '') ?? '',
              ) ??
              100,
        ),
      );
    });
  }

  Future<Color?> _chooseShapeColor() {
    return showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shape Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _palette.map((color) {
            return InkWell(
              onTap: () => Navigator.pop(context, color),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _shapePreview(EditorShapeType type) {
    const color = Color(0xFF2563EB);

    switch (type) {
      case EditorShapeType.rectangle:
        return Container(
          width: 45,
          height: 28,
          decoration: BoxDecoration(border: Border.all(color: color, width: 2)),
        );

      case EditorShapeType.roundedRectangle:
        return Container(
          width: 45,
          height: 28,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        );

      case EditorShapeType.circle:
        return Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
        );

      case EditorShapeType.line:
        return Container(width: 50, height: 2, color: color);

      case EditorShapeType.arrow:
        return const Icon(Icons.arrow_forward, color: color, size: 32);

      case EditorShapeType.diamond:
      case EditorShapeType.triangle:
      case EditorShapeType.star:
        return CustomPaint(
          size: const Size(40, 35),
          painter: ShapePreviewPainter(color: color, shape: type),
        );
    }
  }

  String _shapeName(EditorShapeType type) {
    switch (type) {
      case EditorShapeType.rectangle:
        return 'Rectangle';
      case EditorShapeType.roundedRectangle:
        return 'Rounded Rectangle';
      case EditorShapeType.circle:
        return 'Circle';
      case EditorShapeType.line:
        return 'Line';
      case EditorShapeType.arrow:
        return 'Arrow';
      case EditorShapeType.diamond:
        return 'Diamond';
      case EditorShapeType.triangle:
        return 'Triangle';
      case EditorShapeType.star:
        return 'Star';
    }
  }

  Future<void> _insertLink() async {
    final controller = _selectedController;
    if (controller == null) return;

    final selection = controller.selection;

    if (!selection.isValid ||
        selection.isCollapsed ||
        selection.end > controller.text.length) {
      return;
    }

    final url = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return InsertLinkDialog();
      },
    );

    if (!mounted || url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);

    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a valid URL')));
      return;
    }

    controller.applyLink(selection.start, selection.end, uri.toString());
    controller.selection = selection;
    _notifyDocumentChanged();
  }

  void _removeLink() {
    final controller = _selectedController;
    if (controller == null) return;

    final selection = controller.selection;

    if (!selection.isValid ||
        selection.isCollapsed ||
        selection.end > controller.text.length) {
      return;
    }

    controller.removeLink(selection.start, selection.end);
    _notifyDocumentChanged();
  }

  final Set<String> _activeStyles = {};

  void _toggleStyle(String style) {
    final controller = _selectedController;
    if (controller == null) return;

    final selection = controller.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final enable = !controller.isStyleActive(style);

      controller.toggleStyle(style);

      setState(() {
        if (enable) {
          controller.typingStyles.add(style);
          _activeStyles.add(style);
        } else {
          controller.typingStyles.remove(style);
          _activeStyles.remove(style);
        }
      });
    } else {
      controller.toggleTypingStyle(style);

      setState(() {
        if (controller.typingStyles.contains(style)) {
          _activeStyles.add(style);
        } else {
          _activeStyles.remove(style);
        }
      });
    }

    _notifyDocumentChanged();
  }

  void _applyTextColor({required bool highlight}) {
    final controller = _selectedController;
    if (controller == null) return;

    final selection = controller.selection;

    if (!selection.isValid || selection.isCollapsed) return;

    showDialog<Color>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(highlight ? 'Highlight Color' : 'Text Color'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _palette.map((color) {
            return InkWell(
              onTap: () => Navigator.pop(context, color),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade400),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ).then((color) {
      if (color == null || !mounted) return;
      controller.applyColor(color.toARGB32(), highlight: highlight);
      _notifyDocumentChanged();
    });
  }

  final List<String> _fontSizes = [
    '12px',
    '14px',
    '16px',
    '18px',
    '20px',
    '24px',
    '28px',
    '32px',
  ];

  String _selectedFontSize = '16px';

  void _changeFontSize(String? value) {
    if (value == null) return;

    final block = _selectedBlock;
    if (block == null || !_isTextBlock(block.type)) return;

    setState(() {
      _selectedFontSize = value;
      block.fontSize = double.parse(value.replaceAll('px', ''));
    });

    _notifyDocumentChanged();
  }

  void _addTableRow() {
    final block = _selectedBlock;
    if (block?.type != EditorBlockType.table) return;

    setState(() {
      block!.table ??= [];
      final columns = block.table!.isEmpty ? 2 : block.table!.first.length;
      block.table!.add(List.generate(columns, (_) => ''));
    });

    _notifyDocumentChanged();
  }

  void _addTableColumn() {
    final block = _selectedBlock;
    if (block?.type != EditorBlockType.table) return;

    setState(() {
      block!.table ??= [];
      if (block.table!.isEmpty) {
        block.table!.add(['', '']);
      } else {
        for (final row in block.table!) {
          row.add('');
        }
      }
    });

    _notifyDocumentChanged();
  }

  void _deleteTableRow() {
    final block = _selectedBlock;
    if (block?.type != EditorBlockType.table ||
        block!.table == null ||
        block.table!.length <= 1) {
      return;
    }

    setState(() => block.table!.removeLast());
    _notifyDocumentChanged();
  }

  void _deleteTableColumn() {
    final block = _selectedBlock;

    if (block?.type != EditorBlockType.table ||
        block!.table == null ||
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

  void _deleteSelectedBlock() {
    _deleteBlock(_selectedIndex);
  }

  void _deleteBlock(int index) {
    if (_blocks.length <= 1 || index < 0 || index >= _blocks.length) {
      return;
    }

    final block = _blocks[index];

    setState(() {
      _blocks.removeAt(index);
      _controllers.remove(block.id)?.dispose();
      _focusNodes.remove(block.id)?.dispose();
      _selectedIndex = _selectedIndex.clamp(0, _blocks.length - 1);
    });

    _notifyDocumentChanged();
  }

  void _insertHorizontalRule() {
    _insertBlock(EditorBlock(type: EditorBlockType.horizontalRule));
  }

  TextStyle _blockTextStyle(EditorBlock block) {
    switch (block.type) {
      case EditorBlockType.heading1:
        return TextStyle(
          fontSize: block.fontSize == 16 ? 28 : block.fontSize,
          fontWeight: FontWeight.bold,
        );
      case EditorBlockType.heading2:
        return TextStyle(
          fontSize: block.fontSize == 16 ? 23 : block.fontSize,
          fontWeight: FontWeight.bold,
        );
      case EditorBlockType.heading3:
        return TextStyle(
          fontSize: block.fontSize == 16 ? 19 : block.fontSize,
          fontWeight: FontWeight.bold,
        );
      default:
        return TextStyle(fontSize: block.fontSize);
    }
  }

  Widget _buildPill({
    required Widget child,
    required VoidCallback onTap,
    String? tooltip,
    Color? color,
    bool active = false,
  }) {
    final foregroundColor = active
        ? Colors.white
        : color ?? const Color(0xFF334155);

    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0D9488) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? const Color(0xFF0D9488) : Colors.grey.shade300,
              width: 0.8,
            ),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foregroundColor,
            ),
            child: IconTheme(
              data: IconThemeData(size: 16, color: foregroundColor),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  Widget _textPill(
    String label,
    VoidCallback onTap, {
    String? tooltip,
    bool bold = false,
    bool italic = false,
    bool underline = false,
    bool active = false,
    Color? color,
  }) {
    return _buildPill(
      tooltip: tooltip ?? label,
      color: active ? const Color(0xFF2563EB) : color,
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          decoration: underline
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
      ),
    );
  }

  Widget _iconPill(
    IconData icon,
    VoidCallback onTap, {
    String? tooltip,
    Color? color,
    bool active = false,
  }) {
    return _buildPill(
      tooltip: tooltip,
      color: color,
      active: active,
      onTap: onTap,
      child: Icon(icon),
    );
  }

  Widget _smallPill(
    String label,
    VoidCallback onTap, {
    String? tooltip,
    Color? color,
  }) {
    return _buildPill(
      tooltip: tooltip,
      color: color,
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 18,
      width: 1,
      color: Colors.grey.shade300,
    );
  }

  Widget _colorPill(String label, Color color, VoidCallback onTap) {
    return _buildPill(
      tooltip: label,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 5),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final controller = _selectedController;
    final block = _selectedBlock;

    final isTable = block?.type == EditorBlockType.table;

    final headingValue =
        block != null &&
            [
              EditorBlockType.paragraph,
              EditorBlockType.heading1,
              EditorBlockType.heading2,
              EditorBlockType.heading3,
            ].contains(block.type)
        ? block.type
        : EditorBlockType.paragraph;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ROW 1: PRIMARY FORMATTING TOOLBAR
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<EditorBlockType>(
                      value: headingValue,
                      isDense: true,
                      icon: const Icon(Icons.unfold_more_rounded, size: 15),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
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
                  ),
                ),
                _verticalDivider(),
                _textPill(
                  'B',
                  () => _toggleStyle('bold'),
                  tooltip: 'Bold',
                  bold: true,
                  active:
                      controller != null &&
                      (controller.selection.isValid &&
                              !controller.selection.isCollapsed
                          ? controller.isStyleActive('bold')
                          : controller.typingStyles.contains('bold')),
                ),
                _textPill(
                  'I',
                  () => _toggleStyle('italic'),
                  tooltip: 'Italic',
                  italic: true,
                  active:
                      controller != null &&
                      (controller.selection.isValid &&
                              !controller.selection.isCollapsed
                          ? controller.isStyleActive('italic')
                          : controller.typingStyles.contains('boitalicld')),
                ),
                _textPill(
                  'U',
                  () => _toggleStyle('underline'),
                  tooltip: 'Underline',
                  underline: true,

                  active:
                      controller != null &&
                      (controller.selection.isValid &&
                              !controller.selection.isCollapsed
                          ? controller.isStyleActive('underline')
                          : controller.typingStyles.contains('underline')),
                ),
                _textPill(
                  'S',
                  () => _toggleStyle('strike'),
                  tooltip: 'Strikethrough',

                  active:
                      controller != null &&
                      (controller.selection.isValid &&
                              !controller.selection.isCollapsed
                          ? controller.isStyleActive('strike')
                          : controller.typingStyles.contains('strike')),
                ),
                _verticalDivider(),
                _iconPill(
                  Icons.format_list_bulleted_rounded,
                  () => _applyList(EditorBlockType.bulletList),
                  tooltip: 'Bullet List',
                ),
                _iconPill(
                  Icons.format_list_numbered_rounded,
                  () => _applyList(EditorBlockType.numberedList),
                  tooltip: 'Numbered List',
                ),
                _verticalDivider(),
                _iconPill(
                  Icons.format_align_left_rounded,
                  () => _applyAlignment(TextAlign.left),
                  tooltip: 'Align Left',
                  active: _selectedBlock?.alignment == TextAlign.left,
                ),
                _iconPill(
                  Icons.format_align_center_rounded,
                  () => _applyAlignment(TextAlign.center),
                  tooltip: 'Align Center',
                  active: _selectedBlock?.alignment == TextAlign.center,
                ),
                _iconPill(
                  Icons.format_align_right_rounded,
                  () => _applyAlignment(TextAlign.right),
                  tooltip: 'Align Right',
                  active: _selectedBlock?.alignment == TextAlign.right,
                ),
                _iconPill(
                  Icons.format_align_justify_rounded,
                  () => _applyAlignment(TextAlign.justify),
                  tooltip: 'Justify',
                  active: _selectedBlock?.alignment == TextAlign.justify,
                ),
                _verticalDivider(),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: _fontSizes.contains(_selectedFontSize)
                        ? _selectedFontSize
                        : '16px',
                    items: _fontSizes.map((size) {
                      return DropdownMenuItem<String>(
                        value: size,
                        child: Text(size),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      final index = _selectedIndex;
                      if (index < 0 || index >= _blocks.length) return;

                      setState(() {
                        _selectedFontSize = value;
                        _blocks[index].fontSize = double.parse(
                          value.replaceAll('px', ''),
                        );
                      });

                      _notifyDocumentChanged();
                    },
                  ),
                ),
                _verticalDivider(),
                _iconPill(
                  Icons.link_rounded,
                  _insertLink,
                  tooltip: 'Insert Link',
                ),
                // _iconPill(
                //   Icons.link_off_rounded,
                //   _removeLink,
                //   tooltip: 'Remove Link',
                // ),
                _iconPill(
                  Icons.image_outlined,
                  _insertImage,
                  tooltip: 'Insert Image',
                  color: const Color(0xFF2563EB),
                ),
                _iconPill(
                  Icons.diamond_outlined,
                  _insertShape,
                  tooltip: 'Insert Shape',
                  color: const Color(0xFFE11D48),
                ),
                _iconPill(
                  Icons.table_chart_outlined,
                  _insertTable,
                  tooltip: 'Insert Table',
                  color: const Color(0xFF2563EB),
                ),
                _iconPill(
                  Icons.add,
                  _insertParagraph,
                  tooltip: 'New Paragraph',
                ),
              ],
            ),
          ),

          const SizedBox(height: 7),

          //! ROW 2: TABLE AND STYLING TOOLBAR
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // _smallPill(
                //   '+Col',
                //   _addTableColumn,
                //   tooltip: 'Add Table Column',
                // ),
                // _smallPill(
                //   '-Col',
                //   _deleteTableColumn,
                //   tooltip: 'Remove Table Column',
                // ),
                // _smallPill('+Row', _addTableRow, tooltip: 'Add Table Row'),
                // _smallPill(
                //   '-Row',
                //   _deleteTableRow,
                //   tooltip: 'Remove Table Row',
                // ),
                // _smallPill(
                //   'Del',
                //   _deleteSelectedBlock,
                //   tooltip: 'Delete Selected Block',
                //   color: Colors.red,
                // ),
                // _verticalDivider(),
                // _smallPill(
                //   '—',
                //   _insertHorizontalRule,
                //   tooltip: 'Insert Horizontal Divider',
                // ),
                _colorPill(
                  'Text Color',
                  const Color(0xFF1B365D),
                  () => _applyTextColor(highlight: false),
                ),
                _colorPill(
                  'Highlight',
                  const Color(0xFFFEF08A),
                  () => _applyTextColor(highlight: true),
                ),
                if (isTable)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      'Table selected',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextBlock(EditorBlock block, int index) {
    final controller = _controllers[block.id]!;

    Widget editor = TextFormField(
      controller: controller,
      focusNode: _focusNodes[block.id],
      maxLines: null,
      minLines: 1,
      expands: false,
      textAlign: block.alignment,
      textAlignVertical: TextAlignVertical.top,
      style: _blockTextStyle(block),
      decoration: InputDecoration(
        hintText: widget.hintText,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (_) {
        _notifyDocumentChanged();
      },
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );

    if (block.type == EditorBlockType.bulletList ||
        block.type == EditorBlockType.numberedList) {
      final number =
          _blocks
              .take(index)
              .where((b) => b.type == EditorBlockType.numberedList)
              .length +
          1;

      editor = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                block.type == EditorBlockType.bulletList ? '•' : '$number.',
                style: _blockTextStyle(block),
              ),
            ),
          ),
          Expanded(child: editor),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(width: double.infinity, child: editor),
    );
  }

  Widget _buildImage(EditorBlock block, int index) {
    final source = block.imagePath ?? '';

    if (source.isEmpty) {
      return const Icon(Icons.broken_image);
    }

    final isNetworkImage =
        source.startsWith('http://') || source.startsWith('https://');

    final width = double.tryParse(
      (block.imageWidth ?? '100%').replaceAll('px', '').replaceAll('%', ''),
    );

    final isPercentage = block.imageWidth?.contains('%') ?? true;

    final image = isNetworkImage
        ? Image.network(
            source,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
          )
        : Image.file(
            File(source),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
          );

    final borderColor =
        block.imageBorder != null &&
            block.imageBorder!.isNotEmpty &&
            block.imageBorder != 'none'
        ? _parseImageBorderColor(block.imageBorder!)
        : null;

    final imageWidget = Container(
      width: isPercentage ? double.infinity : width,
      margin: EdgeInsets.all(
        double.tryParse(
              (block.imageMargin ?? '0px')
                  .replaceAll('px', '')
                  .replaceAll('px', ''),
            ) ??
            0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(block.imageRadius ?? 0),
        border: borderColor != null
            ? Border.all(color: borderColor, width: 1.5)
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(block.imageRadius ?? 0),
        child: image,
      ),
    );

    Alignment alignment;

    switch (block.imageAlignment) {
      case 'center':
        alignment = Alignment.center;
        break;
      case 'right':
        alignment = Alignment.centerRight;
        break;
      default:
        alignment = Alignment.centerLeft;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Container(
              width: double.infinity,
              alignment: alignment,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                // border: Border.all(
                //   color: _selectedIndex == index ? Colors.blue : Colors.transparent,
                // ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: imageWidget,
            ),
            Positioned(
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                child: IconButton(
                  tooltip: 'Delete image',
                  onPressed: () => _deleteBlock(index),
                  icon: const Icon(Icons.close, color: Colors.red, size: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color? _parseImageBorderColor(String border) {
    final match = RegExp(r'#[0-9a-fA-F]{6}').firstMatch(border);

    if (match == null) return Colors.grey;

    return Color(
      0xFF000000 |
          (int.tryParse(match.group(0)!.replaceFirst('#', ''), radix: 16) ??
              0xFF000000),
    );
  }

  String _getShapeSvgPoints(EditorShapeType type) {
    switch (type) {
      case EditorShapeType.diamond:
        return '50,4 96,50 50,96 4,50';

      case EditorShapeType.triangle:
        return '50,4 96,96 4,96';

      case EditorShapeType.star:
        return '50,5 64,36 98,36 70,57 81,91 50,70 19,91 30,57 2,36 36,36';

      default:
        return '';
    }
  }

  Widget _buildShape(EditorBlock block, int index) {
    final color = Color(block.shapeColor);

    Widget shape;

    switch (block.shapeType) {
      case EditorShapeType.rectangle:
        shape = Container(
          width: block.shapeWidth,
          height: block.shapeHeight,
          decoration: BoxDecoration(border: Border.all(color: color, width: 2)),
        );
        break;

      case EditorShapeType.roundedRectangle:
        shape = Container(
          width: block.shapeWidth,
          height: block.shapeHeight,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
        );
        break;

      case EditorShapeType.circle:
        final size = block.shapeWidth < block.shapeHeight
            ? block.shapeWidth
            : block.shapeHeight;

        shape = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
        );
        break;

      case EditorShapeType.line:
        shape = Container(width: block.shapeWidth, height: 2, color: color);
        break;

      case EditorShapeType.arrow:
        shape = Icon(
          Icons.arrow_forward,
          size: block.shapeHeight,
          color: color,
        );
        break;

      case EditorShapeType.diamond:
      case EditorShapeType.triangle:
      case EditorShapeType.star:
        shape = CustomPaint(
          size: Size(block.shapeWidth, block.shapeHeight),
          painter: ShapePreviewPainter(color: color, shape: block.shapeType),
        );
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // border: Border.all(
            //   color: _selectedIndex == index ? Colors.blue : Colors.transparent,
            // ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: shape,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Change shape color',
              onPressed: () async {
                final newColor = await _chooseShapeColor();
                if (newColor == null || !mounted) return;

                setState(() {
                  block.shapeColor = newColor.toARGB32();
                });

                _notifyDocumentChanged();
              },
              icon: const Icon(Icons.palette_outlined, size: 19),
            ),
            IconButton(
              tooltip: 'Delete shape',
              onPressed: () => _deleteBlock(index),
              icon: const Icon(
                Icons.delete_outline,
                size: 19,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTable(EditorBlock block) {
    final table = block.table ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              tooltip: 'Delete table',
              icon: const Icon(Icons.close, size: 16, color: Colors.red),
              onPressed: () {
                setState(() {
                  _blocks.removeWhere((item) => item.id == block.id);
                  _selectedIndex = -1;
                });

                _notifyDocumentChanged();
              },
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
                          decoration: const InputDecoration(
                            hintText: 'Enter text',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () {
                            final index = _blocks.indexOf(block);
                            if (index >= 0 && _selectedIndex != index) {
                              setState(() => _selectedIndex = index);
                            }
                          },
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

      case EditorBlockType.shape:
        content = _buildShape(block, index);
        break;

      case EditorBlockType.horizontalRule:
        content = Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          height: 1,
          color: Colors.grey.shade400,
        );
        break;

      default:
        content = _buildTextBlock(block, index);
    }

    return InkWell(
      onTap: () {
        if (_selectedIndex != index) {
          setState(() => _selectedIndex = index);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          // border:
          //     _selectedIndex == index &&
          //         block.type != EditorBlockType.horizontalRule
          //     ? Border.all(color: Colors.blue.withOpacity(0.25))
          //     : null,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: content,
        ),
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

        case EditorBlockType.shape:
          result.add('[Shape: ${block.shapeType.name}]');
          break;

        case EditorBlockType.horizontalRule:
          result.add('--------------------');
          break;

        case EditorBlockType.table:
          result.add(
            (block.table ?? []).map((row) => row.join(' | ')).join('\n'),
          );
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

  String toJsonString() => jsonEncode(toJson());

  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _colorToHex(int color) {
    return '#${color.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  String _inlineHtml(EditorBlock block) {
    final text = block.text;
    if (text.isEmpty) return '';

    final controller = _controllers[block.id];
    final ranges = controller?.ranges ?? block.styles;

    final result = StringBuffer();

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

        if (style.color != null || style.backgroundColor != null) {
          final styles = <String>[];

          if (style.color != null) {
            styles.add('color:${_colorToHex(style.color!)}');
          }

          if (style.backgroundColor != null) {
            styles.add(
              'background-color:${_colorToHex(style.backgroundColor!)}',
            );
          }

          value = '<span style="${styles.join(';')}">$value</span>';
        }

        if (style.link != null) {
          value = '<a href="${_escapeHtml(style.link!)}">$value</a>';
        }
      }

      result.write(value);
      i = end;
    }

    return result.toString();
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
      final content = _inlineHtml(block);

      switch (block.type) {
        case EditorBlockType.heading1:
          result.writeln(
            '<h1 style="text-align:$alignment;font-size:${block.fontSize}px">$content</h1>',
          );
          break;

        case EditorBlockType.heading2:
          result.writeln(
            '<h2 style="text-align:$alignment;font-size:${block.fontSize}px">$content</h2>',
          );
          break;

        case EditorBlockType.heading3:
          result.writeln(
            '<h3 style="text-align:$alignment;font-size:${block.fontSize}px">$content</h3>',
          );
          break;

        case EditorBlockType.bulletList:
          result.writeln('<ul><li>$content</li></ul>');
          break;

        case EditorBlockType.numberedList:
          result.writeln('<ol><li>$content</li></ol>');
          break;

        case EditorBlockType.image:
          if (block.imagePath != null) {
            result.writeln('<img src="${_escapeHtml(block.imagePath!)}" />');
          }
          break;

        case EditorBlockType.shape:
          final color = _colorToHex(block.shapeColor);

          switch (block.shapeType) {
            case EditorShapeType.rectangle:
              result.writeln(
                '<div style="width:${block.shapeWidth}px;height:${block.shapeHeight}px;border:2px solid $color"></div>',
              );
              break;
            case EditorShapeType.roundedRectangle:
              result.writeln(
                '<div style="width:${block.shapeWidth}px;height:${block.shapeHeight}px;border:2px solid $color;border-radius:14px"></div>',
              );
              break;
            case EditorShapeType.circle:
              final size = block.shapeWidth < block.shapeHeight
                  ? block.shapeWidth
                  : block.shapeHeight;
              result.writeln(
                '<div style="width:${size}px;height:${size}px;border:2px solid $color;border-radius:50%"></div>',
              );
              break;
            case EditorShapeType.line:
              result.writeln(
                '<hr style="width:${block.shapeWidth}px;border:1px solid $color" />',
              );
              break;
            case EditorShapeType.arrow:
              result.writeln(
                '<span style="color:$color;font-size:${block.shapeHeight}px">&#8594;</span>',
              );
              break;
            case EditorShapeType.diamond:
            case EditorShapeType.triangle:
            case EditorShapeType.star:
              final points = _getShapeSvgPoints(block.shapeType);

              result.writeln(
                '<svg width="${block.shapeWidth}" height="${block.shapeHeight}" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><polygon points="$points" fill="none" stroke="$color" stroke-width="2" stroke-linejoin="round"/></svg>',
              );
              break;
          }
          break;

        case EditorBlockType.horizontalRule:
          result.writeln('<hr />');
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
            '<p style="text-align:$alignment;font-size:${block.fontSize}px">$content</p>',
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
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(),
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
