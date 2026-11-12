import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ImportPositionImageSheet extends StatefulWidget {
  final ValueChanged<String> onInsertImage;

  const ImportPositionImageSheet({super.key, required this.onInsertImage});

  static Future<void> show(
    BuildContext context,
    ValueChanged<String> onInsert,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ImportPositionImageSheet(
        onInsertImage: (markup) {
          Navigator.pop(ctx);
          onInsert(markup);
        },
      ),
    );
  }

  @override
  State<ImportPositionImageSheet> createState() =>
      _ImportPositionImageSheetState();
}

class _ImportPositionImageSheetState extends State<ImportPositionImageSheet> {
  int _selectedTab = 0;

  File? _pickedFile;

  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _altController = TextEditingController(
    text: 'Official Company Seal',
  );

  String _alignment = 'Inline with Text';
  String _imageSize = 'Small (150px)';
  String _spacing = 'None (0px)';
  String _corners = 'Square (0px)';
  String _border = 'None';

  @override
  void dispose() {
    _urlController.dispose();
    _altController.dispose();
    super.dispose();
  }

  void _insertImage() {
    final source = _imageSource;

    if (source == null || source.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    widget.onInsertImage(_generateImageMarkup());
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _pickedFile = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  String? get _imageSource {
    if (_selectedTab == 0) {
      return _pickedFile?.path;
    }

    final url = _urlController.text.trim();
    return url.isEmpty ? null : url;
  }

  double get _imageWidth {
    if (_imageSize.contains('300px')) return 300;
    if (_imageSize.contains('500px')) return 500;
    return 150;
  }

  double get _imageRadius {
    if (_corners.contains('4px')) return 4;
    if (_corners.contains('8px')) return 8;
    if (_corners.contains('Pill')) return 999;
    return 0;
  }

  double get _imageSpacing {
    if (_spacing.contains('8px')) return 8;
    if (_spacing.contains('16px')) return 16;
    if (_spacing.contains('24px')) return 24;
    return 0;
  }

  Border? get _imageBorder {
    if (_border == '1px Solid') {
      return Border.all(color: const Color(0xFFCBD5E1), width: 1);
    }

    if (_border == '2px Solid') {
      return Border.all(color: const Color(0xFF1B365D), width: 2);
    }

    if (_border == 'Dashed') {
      return Border.all(color: const Color(0xFF64748B), width: 1);
    }

    return null;
  }

  String get _widthCss {
    if (_imageSize.contains('300px')) return '300px';
    if (_imageSize.contains('500px')) return '500px';
    if (_imageSize.contains('Full Width')) return '100%';
    return '150px';
  }

  String get _spacingCss {
    if (_spacing.contains('8px')) return '8px';
    if (_spacing.contains('16px')) return '16px';
    if (_spacing.contains('24px')) return '24px';
    return '0px';
  }

  String get _radiusCss {
    if (_corners.contains('4px')) return '4px';
    if (_corners.contains('8px')) return '8px';
    if (_corners.contains('Pill')) return '999px';
    return '0px';
  }

  String get _borderCss {
    if (_border == '1px Solid') return '1px solid #CBD5E1';
    if (_border == '2px Solid') return '2px solid #1B365D';
    if (_border == 'Dashed') return '1px dashed #64748B';
    return 'none';
  }

  String _generateImageMarkup() {
    final source = _imageSource;

    if (source == null || source.isEmpty) return '';

    final alt = _altController.text.trim();

    return '''
<img
  src="${_escapeAttribute(source)}"
  alt="${_escapeAttribute(alt)}"
  data-image-width="$_widthCss"
  data-image-margin="$_spacingCss"
  data-image-radius="$_radiusCss"
  data-image-border="$_borderCss"
  data-image-alignment="$_alignment"
  style="width:$_widthCss;max-width:100%;margin:$_spacingCss;border-radius:$_radiusCss;border:$_borderCss;display:block;"
/>
''';
  }

  String _escapeAttribute(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('"', '&quot;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  Widget _buildImagePreview() {
    final source = _imageSource;

    if (source == null || source.isEmpty) {
      return Container(
        height: 150,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_outlined, size: 36, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              'Image preview will appear here',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.black),
            ),
          ],
        ),
      );
    }

    final isFullWidth = _imageSize == 'Full Width';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final imageWidth = isFullWidth
              ? availableWidth
              : _imageWidth.clamp(1.0, availableWidth);

          Alignment alignment;

          switch (_alignment) {
            case 'Center Block':
            case 'Full Width':
              alignment = Alignment.center;
              break;
            case 'Right Align':
              alignment = Alignment.centerRight;
              break;
            default:
              alignment = Alignment.centerLeft;
          }

          Widget image;

          if (_selectedTab == 0) {
            image = Image.file(
              File(source),
              width: imageWidth,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) {
                return const SizedBox(
                  height: 150,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                );
              },
            );
          } else {
            image = Image.network(
              source,
              width: imageWidth,
              height: 200,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return const SizedBox(
                  height: 150,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (_, _, _) {
                return const SizedBox(
                  height: 150,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                );
              },
            );
          }

          return Padding(
            padding: EdgeInsets.all(_imageSpacing),
            child: Align(
              alignment: alignment,
              child: Container(
                width: imageWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_imageRadius),
                  border: _imageBorder,
                ),
                clipBehavior: Clip.antiAlias,
                child: image,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import & Position Image',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Upload an image or paste a web URL with layout and styling options',
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

          const Divider(height: 1, color: Colors.black),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTabButton(
                        index: 0,
                        icon: Icons.upload_file_rounded,
                        label: 'File Upload',
                      ),
                      const SizedBox(width: 8),
                      _buildTabButton(
                        index: 1,
                        icon: Icons.link_rounded,
                        label: 'Image URL',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_selectedTab == 0) ...[
                    _buildSectionLabel('SELECT IMAGE FILE'),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _pickedFile != null
                                ? Colors.black
                                : Colors.black,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_file_rounded,
                              size: 20,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _pickedFile != null
                                    ? _pickedFile!.path.split('/').last
                                    : 'Choose file',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: _pickedFile != null
                                      ? Colors.black
                                      : Colors.grey,
                                  fontWeight: _pickedFile != null
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.file_upload_outlined,
                              size: 18,
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    _buildSectionLabel('IMAGE WEB URL'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _urlController,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'https://example.com/company_seal.png',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: Colors.grey,
                        ),
                        prefixIcon: const Icon(
                          Icons.link,
                          size: 18,
                          color: Colors.black,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.black,
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'ALIGNMENT & TEXT WRAP',
                          value: _alignment,
                          items: const [
                            'Inline with Text',
                            'Left Align',
                            'Right Align',
                            'Center Block',
                            'Full Width',
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _alignment = v);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          label: 'IMAGE SIZE / WIDTH',
                          value: _imageSize,
                          items: const [
                            'Small (150px)',
                            'Medium (300px)',
                            'Large (500px)',
                            'Full Width',
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _imageSize = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          label: 'SPACING',
                          value: _spacing,
                          items: const [
                            'None (0px)',
                            'Small (8px)',
                            'Medium (16px)',
                            'Large (24px)',
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _spacing = v);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDropdown(
                          label: 'CORNERS',
                          value: _corners,
                          items: const [
                            'Square (0px)',
                            'Rounded (4px)',
                            'Rounded (8px)',
                            'Pill',
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _corners = v);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDropdown(
                          label: 'BORDER',
                          value: _border,
                          items: const [
                            'None',
                            '1px Solid',
                            '2px Solid',
                            'Dashed',
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _border = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  _buildSectionLabel('ALT TEXT / DESCRIPTION (OPTIONAL)'),
                  const SizedBox(height: 6),

                  TextField(
                    controller: _altController,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. Official Company Seal',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: Colors.grey,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.black,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionLabel('IMAGE PREVIEW'),
                  const SizedBox(height: 8),
                  _buildImagePreview(),

                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Colors.black),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.black),
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
                    onPressed: _insertImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'INSERT IMAGE INTO TEMPLATE',
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

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedTab == index;

    return InkWell(
      onTap: () {
        setState(() => _selectedTab = index);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.black,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : Colors.black,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Colors.black,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel(label),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black, width: 0.9),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              style: GoogleFonts.inter(fontSize: 11.5, color: Colors.black),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
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
