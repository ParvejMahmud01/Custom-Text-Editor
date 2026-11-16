import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:html_text_editor/src/text_editor/editor_enums.dart';

class ShapeCanvasPainter extends CustomPainter {
  final AppShapeType shapeType;
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;
  final BorderStyle borderStyle;
  final String text;
  final Color textColor;
  final double fontSize;
  final TextAlign textAlign;

  const ShapeCanvasPainter({
    required this.shapeType,
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderStyle,
    required this.text,
    required this.textColor,
    required this.fontSize,
    required this.textAlign,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final path = _createPath(size);

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    if (fillColor != Colors.transparent && fillColor.a > 0) {
      canvas.drawPath(path, fillPaint);
    }

    _drawBorder(canvas, path);

    _drawText(canvas, size);
  }

  void _drawBorder(Canvas canvas, Path path) {
    if (borderStyle == BorderStyle.none ||
        borderWidth <= 0 ||
        borderColor.a <= 0) {
      return;
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, borderPaint);
  }

  void _drawText(Canvas canvas, Size size) {
    if (text.trim().isEmpty) return;

    final availableWidth = math.max(0.0, size.width - (borderWidth * 2) - 16);

    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: availableWidth);

    double dx;

    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        dx = 8 + borderWidth;
        break;
      case TextAlign.right:
      case TextAlign.end:
        dx = size.width - textPainter.width - 8 - borderWidth;
        break;
      case TextAlign.center:
      case TextAlign.justify:
        dx = (size.width - textPainter.width) / 2;
        break;
    }

    final dy = (size.height - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(dx, dy));
  }

  Path _createPath(Size size) {
    final width = size.width;
    final height = size.height;
    final centerX = width / 2;
    final centerY = height / 2;

    switch (shapeType) {
      case AppShapeType.square:
        return Path()..addRect(Rect.fromLTWH(0, 0, width, height));

      case AppShapeType.circle:
        return Path()..addOval(Rect.fromLTWH(0, 0, width, height));

      case AppShapeType.triangle:
        return Path()
          ..moveTo(centerX, 0)
          ..lineTo(width, height)
          ..lineTo(0, height)
          ..close();

      case AppShapeType.horizontalLine:
        return Path()
          ..moveTo(0, centerY)
          ..lineTo(width, centerY);

      case AppShapeType.diamond:
        return Path()
          ..moveTo(centerX, 0)
          ..lineTo(width, centerY)
          ..lineTo(centerX, height)
          ..lineTo(0, centerY)
          ..close();

      case AppShapeType.arrowRight:
        return Path()
          ..moveTo(0, height * 0.3)
          ..lineTo(width * 0.65, height * 0.3)
          ..lineTo(width * 0.65, 0)
          ..lineTo(width, centerY)
          ..lineTo(width * 0.65, height)
          ..lineTo(width * 0.65, height * 0.7)
          ..lineTo(0, height * 0.7)
          ..close();

      case AppShapeType.arrowLeft:
        return Path()
          ..moveTo(width, height * 0.3)
          ..lineTo(width * 0.35, height * 0.3)
          ..lineTo(width * 0.35, 0)
          ..lineTo(0, centerY)
          ..lineTo(width * 0.35, height)
          ..lineTo(width * 0.35, height * 0.7)
          ..lineTo(width, height * 0.7)
          ..close();

      case AppShapeType.arrowUp:
        return Path()
          ..moveTo(width * 0.3, height)
          ..lineTo(width * 0.3, height * 0.35)
          ..lineTo(0, height * 0.35)
          ..lineTo(centerX, 0)
          ..lineTo(width, height * 0.35)
          ..lineTo(width * 0.7, height * 0.35)
          ..lineTo(width * 0.7, height)
          ..close();

      case AppShapeType.arrowDown:
        return Path()
          ..moveTo(width * 0.3, 0)
          ..lineTo(width * 0.7, 0)
          ..lineTo(width * 0.7, height * 0.65)
          ..lineTo(width, height * 0.65)
          ..lineTo(centerX, height)
          ..lineTo(0, height * 0.65)
          ..lineTo(width * 0.3, height * 0.65)
          ..close();

      case AppShapeType.star:
        final path = Path();
        const points = 10;
        final outerRadius = math.min(width, height) / 2;
        final innerRadius = outerRadius * 0.4;

        for (int i = 0; i < points; i++) {
          final radius = i.isEven ? outerRadius : innerRadius;
          final angle = -math.pi / 2 + (math.pi / points * i);

          final x = centerX + radius * math.cos(angle);
          final y = centerY + radius * math.sin(angle);

          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }

        path.close();
        return path;
    }
  }

  @override
  bool shouldRepaint(covariant ShapeCanvasPainter oldDelegate) {
    return oldDelegate.shapeType != shapeType ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderStyle != borderStyle ||
        oldDelegate.text != text ||
        oldDelegate.textColor != textColor ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.textAlign != textAlign;
  }
}
