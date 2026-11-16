import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:html_text_editor/src/text_editor/editor_enums.dart';

class ShapePreviewPainter extends CustomPainter {
  final Color color;
  final EditorShapeType shape;
  final Color borderColor;
  final double borderWidth;
  final String borderStyle;
  final String arrowDirection;

  const ShapePreviewPainter({
    required this.color,
    required this.shape,
    required this.borderColor,
    required this.borderWidth,
    required this.borderStyle,
    this.arrowDirection = 'right',
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final path = _createPath(size);

    if (color.a > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    if (borderWidth <= 0 || borderColor.a <= 0 || borderStyle == 'none') {
      return;
    }

    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    _drawBorder(canvas, path, paint);
  }

  Path _createPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    switch (shape) {
      case EditorShapeType.rectangle:
        path.addRect(Rect.fromLTWH(0, 0, w, h));
        break;

      case EditorShapeType.roundedRectangle:
        path.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, w, h),
            const Radius.circular(12),
          ),
        );
        break;

      case EditorShapeType.circle:
        path.addOval(Rect.fromLTWH(0, 0, w, h));
        break;

      case EditorShapeType.diamond:
        path.moveTo(w / 2, 0);
        path.lineTo(w, h / 2);
        path.lineTo(w / 2, h);
        path.lineTo(0, h / 2);
        path.close();
        break;

      case EditorShapeType.triangle:
        path.moveTo(w / 2, 0);
        path.lineTo(w, h);
        path.lineTo(0, h);
        path.close();
        break;

      case EditorShapeType.star:
        final cx = w / 2;
        final cy = h / 2;
        final outerRadius = math.min(cx, cy);
        final innerRadius = outerRadius * 0.45;

        var rotation = -math.pi / 2;
        const points = 5;

        for (var i = 0; i < points * 2; i++) {
          final radius = i.isEven ? outerRadius : innerRadius;
          final x = cx + math.cos(rotation) * radius;
          final y = cy + math.sin(rotation) * radius;

          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }

          rotation += math.pi / points;
        }

        path.close();
        break;

      case EditorShapeType.line:
        path.moveTo(0, h / 2);
        path.lineTo(w, h / 2);
        break;

      case EditorShapeType.arrow:
        _createArrowPath(path, size);
        break;
    }

    return path;
  }

  void _createArrowPath(Path path, Size size) {
    final w = size.width;
    final h = size.height;

    switch (arrowDirection) {
      case 'left':
        path
          ..moveTo(w, h * 0.3)
          ..lineTo(w * 0.4, h * 0.3)
          ..lineTo(w * 0.4, 0)
          ..lineTo(0, h * 0.5)
          ..lineTo(w * 0.4, h)
          ..lineTo(w * 0.4, h * 0.7)
          ..lineTo(w, h * 0.7)
          ..close();
        break;

      case 'up':
        path
          ..moveTo(w * 0.3, h)
          ..lineTo(w * 0.3, h * 0.4)
          ..lineTo(0, h * 0.4)
          ..lineTo(w * 0.5, 0)
          ..lineTo(w, h * 0.4)
          ..lineTo(w * 0.7, h * 0.4)
          ..lineTo(w * 0.7, h)
          ..close();
        break;

      case 'down':
        path
          ..moveTo(w * 0.3, 0)
          ..lineTo(w * 0.3, h * 0.6)
          ..lineTo(0, h * 0.6)
          ..lineTo(w * 0.5, h)
          ..lineTo(w, h * 0.6)
          ..lineTo(w * 0.7, h * 0.6)
          ..lineTo(w * 0.7, 0)
          ..close();
        break;

      default:
        path
          ..moveTo(0, h * 0.3)
          ..lineTo(w * 0.6, h * 0.3)
          ..lineTo(w * 0.6, 0)
          ..lineTo(w, h * 0.5)
          ..lineTo(w * 0.6, h)
          ..lineTo(w * 0.6, h * 0.7)
          ..lineTo(0, h * 0.7)
          ..close();
    }
  }

  void _drawBorder(Canvas canvas, Path path, Paint paint) {
    if (borderStyle == 'solid') {
      canvas.drawPath(path, paint);
      return;
    }

    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      final length = metric.length;

      double dashLength;
      double gapLength;

      if (borderStyle == 'dotted') {
        dashLength = 0.1;
        gapLength = borderWidth * 2.5;
      } else {
        dashLength = borderWidth * 4;
        gapLength = borderWidth * 2.5;
      }

      double distance = 0;

      while (distance < length) {
        final end = math.min(distance + dashLength, length);

        final segment = metric.extractPath(distance, end);

        canvas.drawPath(
          segment,
          paint
            ..strokeCap = borderStyle == 'dotted'
                ? StrokeCap.round
                : StrokeCap.butt,
        );

        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant ShapePreviewPainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderStyle != borderStyle ||
        oldDelegate.arrowDirection != arrowDirection;
  }
}
