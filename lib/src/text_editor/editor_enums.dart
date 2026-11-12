import 'package:flutter/material.dart';

enum EditorBlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  bulletList,
  numberedList,
  image,
  table,
  shape,
  horizontalRule,
}

enum EditorShapeType {
  rectangle,
  roundedRectangle,
  circle,
  line,
  arrow,
  diamond,
  triangle,
  star,
}

enum AppShapeType {
  square('Square', Icons.crop_square_rounded),
  circle('Circle', Icons.circle_outlined),
  triangle('Triangle', Icons.change_history_rounded),
  horizontalLine('Horizontal Line', Icons.horizontal_rule_rounded),
  arrowRight('Arrow Right', Icons.arrow_forward_rounded),
  arrowLeft('Arrow Left', Icons.arrow_back_rounded),
  arrowUp('Arrow Up', Icons.arrow_upward_rounded),
  arrowDown('Arrow Down', Icons.arrow_downward_rounded),
  diamond('Diamond', Icons.diamond_outlined),
  star('Star', Icons.star_border_rounded);

  final String label;
  final IconData icon;
  const AppShapeType(this.label, this.icon);
}