import 'dart:ui';

import 'package:custom_editor/text_editor/editor_enums.dart';
import 'package:custom_editor/text_editor/editor_style_range.dart';
import 'package:uuid/uuid.dart';

class EditorBlock {
  final String id;
  EditorBlockType type;
  String text;
  TextAlign alignment;
  String? imagePath;
  List<List<String>>? table;
  List<EditorStyleRange> styles;

  EditorShapeType shapeType;
  int shapeColor;
  double shapeWidth;
  double shapeHeight;
  double fontSize;

  bool bold;
  bool italic;
  bool underline;
  bool strike;
  String? link;
  String? imageAlt;
  final String? imageWidth;
  final String? imageMargin;
  final double? imageRadius;
  final String? imageBorder;
  final String? imageAlignment;
  EditorBlock({
    String? id,
    this.type = EditorBlockType.paragraph,
    this.text = '',
    this.alignment = TextAlign.left,
    this.imagePath,
    this.table,
    List<EditorStyleRange>? styles,
    this.shapeType = EditorShapeType.rectangle,
    this.shapeColor = 0xFF2563EB,
    this.shapeWidth = 180,
    this.shapeHeight = 100,
    this.fontSize = 16,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.link,
    this.imageWidth,
    this.imageMargin,
    this.imageRadius,
    this.imageBorder,
    this.imageAlignment,
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
    'shapeType': shapeType.name,
    'shapeColor': shapeColor,
    'shapeWidth': shapeWidth,
    'shapeHeight': shapeHeight,
    'fontSize': fontSize,
    'bold': bold,
    'italic': italic,
    'underline': underline,
    'strike': strike,
    'link': link,
    'imageAlt': imageAlt,
    'imageWidth': imageWidth,
    'imageMargin': imageMargin,
    'imageRadius': imageRadius,
    'imageBorder': imageBorder,
    'imageAlignment': imageAlignment,
  };

  factory EditorBlock.fromJson(Map<String, dynamic> json) {
    return EditorBlock(
      id: json['id'],
      type: EditorBlockType.values.firstWhere(
        (e) => e.name == json['type'],
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
      shapeType: EditorShapeType.values.firstWhere(
        (e) => e.name == json['shapeType'],
        orElse: () => EditorShapeType.rectangle,
      ),
      shapeColor: json['shapeColor'] ?? 0xFF2563EB,
      shapeWidth: (json['shapeWidth'] ?? 180).toDouble(),
      shapeHeight: (json['shapeHeight'] ?? 100).toDouble(),
      fontSize: (json['fontSize'] ?? 16).toDouble(),
      bold: json['bold'] ?? false,
      italic: json['italic'] ?? false,
      underline: json['underline'] ?? false,
      strike: json['strike'] ?? false,
      link: json['link'],
      imageWidth: json['imageWidth'],
      imageMargin: json['imageMargin'],
      imageRadius: (json['imageRadius'] as num?)?.toDouble(),
      imageBorder: json['imageBorder'],
      imageAlignment: json['imageAlignment'],
    );
  }
}
