import 'dart:math' as math;

import 'package:custom_editor/text_editor/editor_enums.dart';
import 'package:flutter/material.dart';

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

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final hasBorder = borderWidth > 0 && borderColor.a > 0;
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final path = _createPath(size);

    // Draw Fill
    if (fillColor != Colors.transparent && fillColor.a > 0) {
      canvas.drawPath(path, fillPaint);
    }

    // Draw Border
    if (hasBorder) {
      if (borderStyle == BorderStyle.solid) {
        canvas.drawPath(path, borderPaint);
      } else {
        // Dashed border simulation
        canvas.drawPath(path, borderPaint);
      }
    }

    // Draw Text on Shape
    if (text.trim().isNotEmpty) {
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
      )..layout(maxWidth: size.width - (borderWidth * 2) - 16);

      final offset = Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      );

      textPainter.paint(canvas, offset);
    }
  }

  Path _createPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    switch (shapeType) {
      case AppShapeType.square:
        path.addRect(Rect.fromLTWH(0, 0, w, h));
        break;

      case AppShapeType.circle:
        path.addOval(Rect.fromLTWH(0, 0, w, h));
        break;

      case AppShapeType.triangle:
        path.moveTo(w / 2, 0);
        path.lineTo(w, h);
        path.lineTo(0, h);
        path.close();
        break;

      case AppShapeType.horizontalLine:
        path.moveTo(0, h / 2);
        path.lineTo(w, h / 2);
        break;

      case AppShapeType.diamond:
        path.moveTo(w / 2, 0);
        path.lineTo(w, h / 2);
        path.lineTo(w / 2, h);
        path.lineTo(0, h / 2);
        path.close();
        break;

      case AppShapeType.arrowRight:
        path.moveTo(0, h * 0.3);
        path.lineTo(w * 0.6, h * 0.3);
        path.lineTo(w * 0.6, 0);
        path.lineTo(w, h * 0.5);
        path.lineTo(w * 0.6, h);
        path.lineTo(w * 0.6, h * 0.7);
        path.lineTo(0, h * 0.7);
        path.close();
        break;

      case AppShapeType.arrowLeft:
        path.moveTo(w, h * 0.3);
        path.lineTo(w * 0.4, h * 0.3);
        path.lineTo(w * 0.4, 0);
        path.lineTo(0, h * 0.5);
        path.lineTo(w * 0.4, h);
        path.lineTo(w * 0.4, h * 0.7);
        path.lineTo(w, h * 0.7);
        path.close();
        break;

      case AppShapeType.arrowUp:
        path.moveTo(w * 0.3, h);
        path.lineTo(w * 0.3, h * 0.4);
        path.lineTo(0, h * 0.4);
        path.lineTo(w * 0.5, 0);
        path.lineTo(w, h * 0.4);
        path.lineTo(w * 0.7, h * 0.4);
        path.lineTo(w * 0.7, h);
        path.close();
        break;

      case AppShapeType.arrowDown:
        path.moveTo(w * 0.3, 0);
        path.lineTo(w * 0.3, h * 0.6);
        path.lineTo(0, h * 0.6);
        path.lineTo(w * 0.5, h);
        path.lineTo(w, h * 0.6);
        path.lineTo(w * 0.7, h * 0.6);
        path.lineTo(w * 0.7, 0);
        path.close();
        break;

      case AppShapeType.star:
        final cx = w / 2;
        final cy = h / 2;
        final outerRadius = math.min(cx, cy);
        final innerRadius = outerRadius * 0.45;
        const numPoints = 5;
        var rot = math.pi / 2 * 3;
        final step = math.pi / numPoints;

        path.moveTo(cx, cy - outerRadius);
        for (var i = 0; i < numPoints; i++) {
          path.lineTo(
            cx + math.cos(rot) * outerRadius,
            cy + math.sin(rot) * outerRadius,
          );
          rot += step;
          path.lineTo(
            cx + math.cos(rot) * innerRadius,
            cy + math.sin(rot) * innerRadius,
          );
          rot += step;
        }
        path.close();
        break;
    }

    return path;
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
