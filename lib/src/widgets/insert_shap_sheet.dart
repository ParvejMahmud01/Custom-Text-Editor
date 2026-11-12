import 'package:custom_editor/src/text_editor/editor_enums.dart';
import 'package:custom_editor/src/widgets/shap_canvas_painter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InsertShapeSheet extends StatefulWidget {
  final ValueChanged<String> onInsertShape;

  const InsertShapeSheet({super.key, required this.onInsertShape});

  static Future<void> show(
    BuildContext context,
    ValueChanged<String> onInsert,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InsertShapeSheet(
        onInsertShape: (markup) {
          Navigator.pop(ctx);
          onInsert(markup);
        },
      ),
    );
  }

  @override
  State<InsertShapeSheet> createState() => _InsertShapeSheetState();
}

class _InsertShapeSheetState extends State<InsertShapeSheet> {
  AppShapeType _selectedShape = AppShapeType.diamond;
  Color _white = const Color(0xFFE11D48);
  String _shapeText = 'xdsd';
  Color _textColor = const Color(0xFFFFFFFF);
  double _fontSize = 14;
  TextAlign _textAlign = TextAlign.center;
  Color _grey = const Color(0xFF1D4ED8);
  double _borderWidth = 2.0;
  BorderStyle _borderStyle = BorderStyle.solid;

  late final TextEditingController _textController;

  static const List<Color> _palette = [
    Color(0xFFE11D48), // Crimson
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF1E293B), // Dark Slate
  ];

  static const List<Color> _textColorList = [
    Color(0xFFFFFFFF),
    Color(0xFF0F172A),
    Color(0xFFE11D48),
    Color(0xFF1D4ED8),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
  ];

  static const List<Color> _greyList = [
    Color(0xFF1D4ED8),
    Color(0xFFE11D48),
    Color(0xFF10B981),
    Color(0xFF0F172A),
    Color(0xFFCBD5E1),
    Color(0xFF8B5CF6),
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _shapeText);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  static String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  String _getSvgPoints(AppShapeType shape) {
    switch (shape) {
      case AppShapeType.diamond:
        return '50,4 96,50 50,96 4,50';
      case AppShapeType.square:
        return '4,4 96,4 96,96 4,96';
      case AppShapeType.triangle:
        return '50,4 96,96 4,96';
      case AppShapeType.horizontalLine:
        return '4,48 96,48 96,52 4,52';
      case AppShapeType.arrowRight:
        return '4,35 60,35 60,15 96,50 60,85 60,65 4,65';
      case AppShapeType.arrowLeft:
        return '96,35 40,35 40,15 4,50 40,85 40,65 96,65';
      case AppShapeType.arrowUp:
        return '35,96 35,40 15,40 50,4 85,40 65,40 65,96';
      case AppShapeType.arrowDown:
        return '35,4 35,60 15,60 50,96 85,60 65,60 65,4';
      case AppShapeType.star:
        return '50,5 64,36 98,36 70,57 81,91 50,70 19,91 30,57 2,36 36,36';
      case AppShapeType.circle:
        return '50,4 96,50 50,96 4,50';
    }
  }

  String _generateShapeMarkup() {
    final hexFill = _white == Colors.transparent
        ? 'transparent'
        : _colorToHex(_white).toLowerCase();
    final hexBorder = _colorToHex(_grey).toLowerCase();
    final hexText = _colorToHex(_textColor).toLowerCase();
    final alignStr = _textAlign.name;
    final bStyle = _borderStyle == BorderStyle.solid ? 'solid' : 'none';
    final points = _getSvgPoints(_selectedShape);
    final escapedText = _shapeText
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');

    return '<p><span><span data-type="shape" data-shape="${_selectedShape.name}" data-width="180px" data-height="100px" data-fill-color="$hexFill" data-border-color="$hexBorder" data-border-width="${_borderWidth.toInt()}px" data-border-style="$bStyle" data-border-radius="0px" data-margin="8px" data-text-color="$hexText" data-font-size="${_fontSize.toInt()}px" data-font-weight="normal" data-text-align="$alignStr" data-wrap="inline" data-side="left" data-anchor="text" data-x="0" data-y="0" class="rich-shape" style="position: relative; box-sizing: border-box; display: inline-block; vertical-align: middle; width: 180px; height: 100px; max-width: 100%; margin: 4px 8px;"><span class="rich-shape-box" style="position: relative; display: block; width: 100%; height: 100%; box-sizing: border-box;"><svg viewbox="0 0 100 100" preserveaspectratio="none" style="position: absolute; top: 0px; left: 0px; width: 100%; height: 100%; pointer-events: none; overflow: visible;"><polygon points="$points" fill="$hexFill" stroke="$hexBorder" stroke-width="${_borderWidth.toInt()}px" stroke-dasharray="none" stroke-linejoin="round" vector-effect="non-scaling-stroke"></polygon></svg><span class="rich-shape-text" style="position: absolute; inset: 0px; display: flex; align-items: center; justify-content: center; padding: 6px 12px; box-sizing: border-box; overflow: hidden; text-align: $alignStr; color: $hexText; font-size: ${_fontSize.toInt()}px; font-weight: normal; line-height: 1.3; white-space: pre-wrap; word-break: break-word; overflow-wrap: anywhere;">$escapedText</span></span></span></span></p>';
  }

  void _showColorPicker({
    required String title,
    required Color currentColor,
    required List<Color> colors,
    required ValueChanged<Color> onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((color) {
                final isSelected = currentColor.toARGB32() == color.toARGB32();
                return InkWell(
                  onTap: () {
                    onSelect(color);
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.deepPurple : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: 20,
                            color: color == Colors.white
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shapeList = AppShapeType.values;
    final row1Shapes = shapeList.take(5).toList();
    final row2Shapes = shapeList.skip(5).take(5).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Insert Shape',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose a shape, customize colors, border, size, alignment, and add text',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.black,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.grey),

          // Scrollable controls
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. SELECT SHAPE (5 in Row 1, 5 in Row 2)
                  _buildSectionLabel('SELECT SHAPE'),
                  const SizedBox(height: 8),
                  _buildShapeRow(row1Shapes),
                  const SizedBox(height: 8),
                  _buildShapeRow(row2Shapes),
                  const SizedBox(height: 16),

                  // 2. FILL COLOR PALETTE + TRANSPARENT PILL
                  _buildSectionLabel('FILL COLOR'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Hex badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: _white == Colors.transparent
                                    ? Colors.transparent
                                    : _white,
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: _white == Colors.transparent
                                  ? const Icon(
                                      Icons.block,
                                      size: 10,
                                      color: Colors.black,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _white == Colors.transparent
                                  ? 'None'
                                  : _colorToHex(_white).toLowerCase(),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Palette circles
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ..._palette.map((color) {
                                final isSelected =
                                    _white.toARGB32() == color.toARGB32();
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: InkWell(
                                    onTap: () => setState(() => _white = color),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.deepPurple
                                              : Colors.grey,
                                          width: isSelected ? 2.2 : 0.8,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Center(
                                              child: Icon(
                                                Icons.check,
                                                size: 13,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              }),

                              // Transparent Pill Button
                              InkWell(
                                onTap: () =>
                                    setState(() => _white = Colors.transparent),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _white == Colors.transparent
                                        ? Colors.deepPurple
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _white == Colors.transparent
                                          ? Colors.deepPurple
                                          : Colors.grey,
                                      width: _white == Colors.transparent
                                          ? 1.5
                                          : 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    'Transparent',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: _white == Colors.transparent
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: _white == Colors.transparent
                                          ? Colors.deepPurple
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. TEXT ON SHAPE
                  _buildSectionLabel('TEXT ON SHAPE'),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _textController,
                    onChanged: (v) => setState(() => _shapeText = v),
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'e.g. xdsd',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Colors.deepPurple,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 4. TEXT FORMATTING (TEXT COLOR, FONT SIZE, TEXT ALIGNMENT)
                  Row(
                    children: [
                      // TEXT COLOR
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('TEXT COLOR'),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _showColorPicker(
                                title: 'Select Text Color',
                                currentColor: _textColor,
                                colors: _textColorList,
                                onSelect: (c) => setState(() => _textColor = c),
                              ),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: _textColor,
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _colorToHex(_textColor).toLowerCase(),
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // FONT SIZE
                      Expanded(
                        child: _buildDropdownField<double>(
                          label: 'FONT SIZE',
                          value: _fontSize,
                          items: const [10, 12, 14, 16, 18, 20],
                          itemLabel: (v) => '${v.toInt()}px',
                          onChanged: (v) => setState(() => _fontSize = v!),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // TEXT ALIGNMENT
                      Expanded(
                        child: _buildDropdownField<TextAlign>(
                          label: 'ALIGNMENT',
                          value: _textAlign,
                          items: const [
                            TextAlign.left,
                            TextAlign.center,
                            TextAlign.right,
                          ],
                          itemLabel: (v) {
                            switch (v) {
                              case TextAlign.left:
                                return 'Left';
                              case TextAlign.center:
                                return 'Center';
                              case TextAlign.right:
                                return 'Right';
                              default:
                                return 'Center';
                            }
                          },
                          onChanged: (v) => setState(() => _textAlign = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 5. BORDER FORMATTING (BORDER COLOR, BORDER WIDTH, BORDER STYLE)
                  Row(
                    children: [
                      // BORDER COLOR
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionLabel('BORDER COLOR'),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _showColorPicker(
                                title: 'Select Border Color',
                                currentColor: _grey,
                                colors: _greyList,
                                onSelect: (c) => setState(() => _grey = c),
                              ),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: _grey,
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _colorToHex(_grey).toLowerCase(),
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // BORDER WIDTH
                      Expanded(
                        child: _buildDropdownField<double>(
                          label: 'BORDER WIDTH',
                          value: _borderWidth,
                          items: const [0, 1, 2, 3, 4],
                          itemLabel: (v) => '${v.toInt()}px',
                          onChanged: (v) => setState(() => _borderWidth = v!),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // BORDER STYLE
                      Expanded(
                        child: _buildDropdownField<BorderStyle>(
                          label: 'BORDER STYLE',
                          value: _borderStyle,
                          items: const [BorderStyle.solid, BorderStyle.none],
                          itemLabel: (v) =>
                              v == BorderStyle.solid ? 'Solid Line' : 'None',
                          onChanged: (v) => setState(() => _borderStyle = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 6. SHAPE PREVIEW
                  _buildSectionLabel('SHAPE PREVIEW'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 135,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey,
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 180,
                        height: 100,
                        child: CustomPaint(
                          painter: ShapeCanvasPainter(
                            shapeType: _selectedShape,
                            fillColor: _white,
                            borderColor: _grey,
                            borderWidth: _borderWidth,
                            borderStyle: _borderStyle,
                            text: _shapeText,
                            textColor: _textColor,
                            fontSize: _fontSize,
                            textAlign: _textAlign,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Buttons
          const Divider(height: 1, color: Colors.grey),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      final markup = _generateShapeMarkup();
                      widget.onInsertShape(markup);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'INSERT SHAPE INTO TEMPLATE',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

  Widget _buildShapeRow(List<AppShapeType> shapes) {
    return Row(
      children: shapes.map((shape) {
        final isSelected = _selectedShape == shape;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => setState(() => _selectedShape = shape),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.lightBlue : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? Colors.deepPurple : Colors.grey,
                    width: isSelected ? 1.6 : 0.8,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      shape.icon,
                      size: 20,
                      color: isSelected ? Colors.deepPurple : Colors.black,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shape.label,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? Colors.deepPurple : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.unfold_more_rounded,
                size: 16,
                color: Colors.black,
              ),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
