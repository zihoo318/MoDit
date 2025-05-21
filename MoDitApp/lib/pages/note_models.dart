// note_screen에서 데이터 모델 분리
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
  TextEditingController controller;
  FocusNode focusNode;
  double fontSize;
  Color color;
  Size size;
  bool isSelected;

  TextNote({
    required this.position,
    this.fontSize = 16.0,
    this.color = Colors.black,
    String initialText = '',
    this.size = const Size(150, 50),
    this.isSelected = false,
    void Function()? onFocusLost,
  })  : controller = TextEditingController(text: initialText),
        focusNode = FocusNode() {
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        Future.delayed(Duration(milliseconds: 50), () {
          if (!focusNode.hasFocus) {
            isSelected = false;
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
