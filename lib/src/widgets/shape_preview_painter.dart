import 'dart:math' as math;

import 'package:custom_editor/src/text_editor/editor_enums.dart';
import 'package:flutter/material.dart';

class ShapePreviewPainter extends CustomPainter {
  final Color color;
  final EditorShapeType shape;

  const ShapePreviewPainter({required this.color, required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;

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

      default:
        return;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ShapePreviewPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.shape != shape;
  }
}
