import 'package:flutter/material.dart';
import 'dart:io';

class Stroke {
  final List<Offset?> points;
  final Color color;
  final double strokeWidth;

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class TextNote {
  Offset position;
  Size size;
  double fontSize;
  Color color;
  TextEditingController controller;
  FocusNode focusNode;
  bool isSelected;
  bool isEditing;
  VoidCallback? onFocusLost;

  TextNote({
    required this.position,
    this.fontSize = 16.0,
    this.color = Colors.black,
    String initialText = '',
    this.size = const Size(150, 50),
    this.isSelected = false,
    this.isEditing = false, // ✅ 추가
    void Function()? onFocusLost,
  })  : controller = TextEditingController(text: initialText),
        focusNode = FocusNode() {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        Future.delayed(Duration(milliseconds: 50), () {
          if (!focusNode.hasFocus) {
            isSelected = false;
            isEditing = false; // ✅ 포커스 잃으면 편집 종료
            if (onFocusLost != null) onFocusLost();
          }
        });
      }
    });
  }
}

class ImageNote {
  Offset position;
  File file;
  Size size;
  bool isSelected;
  final double aspectRatio;

  ImageNote({
    required this.position,
    required this.file,
    required this.size,
    this.isSelected = false,
    required this.aspectRatio,
  });
}

class LineSegment {
  final Offset a;
  final Offset b;

  LineSegment(this.a, this.b);

  double distanceToPoint(Offset p) {
    final ap = p - a;
    final ab = b - a;
    final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
    final ap_ab = ap.dx * ab.dx + ap.dy * ab.dy;
    final t = (ab2 == 0.0) ? 0.0 : (ap_ab / ab2).clamp(0.0, 1.0);
    final closest = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - closest).distance;
  }
}

