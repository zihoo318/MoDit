/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class NoteScreen extends StatefulWidget {
  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  bool isDrawingMode = false;
  bool isTextMode = false;
  bool isSelectMode = false;
  bool showSaveButton = false;
  final GlobalKey _repaintKey = GlobalKey();
  int imageCount = 1;

  List<Offset?> points = [];
  List<_TextNote> textNotes = [];

  Rect? selectedRect;
  Offset? dragStart;
  Offset? dragEnd;

  void _setMode({bool drawing = false, bool text = false, bool select = false}) {
    setState(() {
      isDrawingMode = drawing;
      isTextMode = text;
      isSelectMode = select;
    });
  }

  Future<void> sendToFlaskOCR() async {
    if (_repaintKey.currentContext == null || selectedRect == null) return;

    await WidgetsBinding.instance.endOfFrame;

    final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final buffer = byteData.buffer.asUint8List();
    final fullImage = img.decodeImage(buffer);
    if (fullImage == null) return;

    final cropped = img.copyCrop(
      fullImage,
      x: selectedRect!.left.toInt(),
      y: selectedRect!.top.toInt(),
      width: selectedRect!.width.toInt(),
      height: selectedRect!.height.toInt(),
    );

    final imageBytes = Uint8List.fromList(img.encodeJpg(cropped));

    final uri = Uri.parse('http://192.168.123.89:8080/ocr/upload');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: 'note.jpg'));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    final result = jsonDecode(respStr);
    print("Flask 응답: $respStr");
    if (response.statusCode == 200) {
      final text = result['text']; // ← Flask가 리턴하는 key
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('OCR 결과'),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('확인'),
            )
          ],
        ),
      );
    } else {
      print("OCR 요청 실패: ${response.statusCode}");
    }

    setState(() {
      showSaveButton = false;
      selectedRect = null;
    });
  }


  //선택 영역 캡쳐
  Future<Uint8List?> captureSelectedArea() async {
    if (_repaintKey.currentContext == null || selectedRect == null) return null;

    await WidgetsBinding.instance.endOfFrame;

    final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 5.0); // 또는 6.0까지
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final fullImage = img.decodeImage(byteData.buffer.asUint8List());
    if (fullImage == null) return null;

    final cropped = img.copyCrop(
      fullImage,
      x: selectedRect!.left.toInt(),
      y: selectedRect!.top.toInt(),
      width: selectedRect!.width.toInt(),
      height: selectedRect!.height.toInt(),
    );

    return Uint8List.fromList(img.encodeJpg(cropped));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('모딧 노트'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: '손글씨 모드',
            onPressed: () => _setMode(drawing: true),
            color: isDrawingMode ? Colors.blue : null,
          ),
          IconButton(
            icon: Icon(Icons.text_fields),
            tooltip: '텍스트 입력 모드',
            onPressed: () => _setMode(text: true),
            color: isTextMode ? Colors.blue : null,
          ),
          IconButton(
            icon: Icon(Icons.crop_square),
            tooltip: '영역 선택 모드',
            onPressed: () => _setMode(select: true),
            color: isSelectMode ? Colors.blue : null,
          ),
        ],
      ),
      body: GestureDetector(
          onTapUp: isTextMode ? _handleTapUp : null,
          onPanStart: (details) {
            if (isDrawingMode) {
              setState(() {
                points.add(details.localPosition);
              });
            } else if (isSelectMode) {
              setState(() {
                dragStart = details.localPosition;
                selectedRect = null;
              });
            }
          },
          onPanUpdate: (details) {
            if (isDrawingMode) {
              setState(() {
                points.add(details.localPosition);
              });
            } else if (isSelectMode && dragStart != null) {
              setState(() {
                dragEnd = details.localPosition;
                selectedRect = Rect.fromPoints(dragStart!, dragEnd!);
                showSaveButton = false;
              });
            }
          },
          onPanEnd: (_) {
            if (isDrawingMode) {
              points.add(null);
            } else if (isSelectMode && selectedRect != null) {
              setState(() {
                showSaveButton = true;
              });
            }
          },
          child: SizedBox.expand(
            child: Stack(
              children: [
            /// ✅ 손글씨 전용 캡처 영역
            Positioned.fill(
            child: RepaintBoundary(
            key: _repaintKey,
              child: CustomPaint(
                size: Size.infinite,
                painter: DrawingPainter(points),
                child: Container(), // 캡처 강제용
              ),
            ),
          ),

          /// 👇 텍스트는 캡처에서 제외
          ...textNotes.map((note) => Positioned(
      left: note.position.dx,
      top: note.position.dy,
      child: isTextMode
          ? Draggable(
        feedback: Material(
          color: Colors.transparent,
          child: _buildTextNote(note, enabled: true),
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          setState(() {
            note.position = details.offset;
          });
        },
        child: _buildTextNote(note, enabled: true),
      )
          : _buildTextNote(note, enabled: false),
    )),

    /// 선택 영역
    if (selectedRect != null)
    Positioned(
    left: selectedRect!.left,
    top: selectedRect!.top,
    child: Container(
    width: selectedRect!.width,
    height: selectedRect!.height,
    decoration: BoxDecoration(
    border: Border.all(color: Colors.blue, width: 2),
    color: Colors.transparent,
    ),
    ),
    ),

    /// 텍스트 인식 버튼
    if (showSaveButton && selectedRect != null)
    Positioned(
    left: selectedRect!.left,
    top: selectedRect!.top - 40,
    child: Material(
    elevation: 2,
    color: Colors.black87,
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
    onTap: () async {
    await Future.delayed(Duration(milliseconds: 100));
    await sendToFlaskOCR();
    setState(() {
    showSaveButton = false;
    selectedRect = null;
    });
    },
    child: Padding(
    padding:
    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Text(
    '텍스트 인식',
    style: TextStyle(color: Colors.white, fontSize: 14),
    ),
    ),
    ),
    ),
    ),
    ],
    ),
    ),
    ),
    );
  }



  Widget _buildTextNote(_TextNote note, {required bool enabled}) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: note.controller,
        maxLines: null,
        readOnly: !enabled,           // 읽기 전용 여부만 조절
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(
          fontSize: 16,
          color: Colors.black,        // 텍스트 색 고정
        ),
      ),
    );
  }



  void _handleTapUp(TapUpDetails details) {
    if (!isDrawingMode && isTextMode) {
      setState(() {
        textNotes.add(_TextNote(position: details.localPosition));
      });
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class _TextNote {
  Offset position;
  TextEditingController controller;

  _TextNote({required this.position}) : controller = TextEditingController();
}
 */
