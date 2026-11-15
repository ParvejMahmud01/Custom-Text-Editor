import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:html_text_editor/src/text_editor/editor_enums.dart';

class ShapePreviewPainter extends CustomPainter {
  final Color color;
  final EditorShapeType shape;
  final Color borderColor;
  final double borderWidth;
  final String borderStyle;

  const ShapePreviewPainter({
    required this.color,
    required this.shape,
    this.borderColor = Colors.blue,
    this.borderWidth = 2,
    this.borderStyle = 'solid',
  });

  Path _getPath(Size size) {
    final path = Path();

    switch (shape) {
      case EditorShapeType.diamond:
        path
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(0, size.height / 2)
          ..close();
        break;

      case EditorShapeType.triangle:
        path
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        break;

      case EditorShapeType.star:
        final center = Offset(size.width / 2, size.height / 2);
        final outerRadius = math.min(size.width, size.height) / 2;
        final innerRadius = outerRadius * 0.4;

        for (int i = 0; i < 10; i++) {
          final radius = i.isEven ? outerRadius : innerRadius;
          final angle = -math.pi / 2 + (i * math.pi / 5);

          final point = Offset(
            center.dx + radius * math.cos(angle),
            center.dy + radius * math.sin(angle),
          );

          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }

        path.close();
        break;

      case EditorShapeType.arrow:
        path
          ..moveTo(0, size.height * 0.35)
          ..lineTo(size.width * 0.6, size.height * 0.35)
          ..lineTo(size.width * 0.6, size.height * 0.15)
          ..lineTo(size.width, size.height * 0.5)
          ..lineTo(size.width * 0.6, size.height * 0.85)
          ..lineTo(size.width * 0.6, size.height * 0.65)
          ..lineTo(0, size.height * 0.65)
          ..close();
        break;

      default:
        path.addRect(Offset.zero & size);
    }

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getPath(size);

    // Fill
    if (color != Colors.transparent) {
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);
    }

    // Border
    if (borderWidth > 0 && borderStyle != 'none') {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ShapePreviewPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.shape != shape ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderStyle != borderStyle;
  }
}
