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
  double fontSize = 16.0;
  bool isStrokePopupVisible = false;

  List<Stroke> strokes = [];
  List<Offset?> currentPoints = [];
  List<_TextNote> textNotes = [];

  Rect? selectedRect;
  Offset? dragStart;
  Offset? dragEnd;

  Color selectedColor = Colors.black;
  double strokeWidth = 2.0;
  bool isEraser = false;

  // undo, redo
  bool canUndo = false;
  List<Stroke> redoStack = [];

  void _setMode({bool drawing = false, bool text = false, bool select = false}) {
    setState(() {
      isDrawingMode = drawing;
      isTextMode = text;
      isSelectMode = select;

      // 선택 영역 모드가 해제되면 선택 박스도 없애기
      if (!select) {
        selectedRect = null;
        showSaveButton = false;
      }
    });
  }


  Future<void> sendToFlaskOCR() async {
    if (_repaintKey.currentContext == null || selectedRect == null) return;

    await WidgetsBinding.instance.endOfFrame;

    final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final pixelRatio = 3.0;
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final buffer = byteData.buffer.asUint8List();
    final fullImage = img.decodeImage(buffer);
    if (fullImage == null) return;

    final cropX = (selectedRect!.left * pixelRatio).clamp(0, fullImage.width - 1).toInt();
    final cropY = (selectedRect!.top * pixelRatio).clamp(0, fullImage.height - 1).toInt();
    final cropWidth = (selectedRect!.width * pixelRatio).clamp(1, fullImage.width - cropX).toInt();
    final cropHeight = (selectedRect!.height * pixelRatio).clamp(1, fullImage.height - cropY).toInt();

    final cropped = img.copyCrop(
      fullImage,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    final imageBytes = Uint8List.fromList(img.encodeJpg(cropped));

    final uri = Uri.parse('http://192.168.219.106:8080/ocr/upload');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: 'note.jpg'));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    final result = jsonDecode(respStr);

    print("Flask 응답: $respStr");

    if (response.statusCode == 200) {
      final text = result['text'] ?? ''; // 서버에서 받은 텍스트

      setState(() {
        textNotes.add(_TextNote(
          position: Offset(selectedRect!.left, selectedRect!.top),
          initialText: text,
        ));
        // 선택 영역 안에 포함된 선들 제거
        strokes = strokes.where((stroke) {
          return !stroke.points.any((point) => point != null && selectedRect!.contains(point!));
        }).toList();
        canUndo = strokes.isNotEmpty;
        selectedRect = null;
        showSaveButton = false;
      });
    } else {
      print("OCR 요청 실패: ${response.statusCode}");
    }
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

  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
          isEraser = false;
        });
      },
      child: Container(
        width: 30,
        height: 30,
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildStrokeWidthButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          isStrokePopupVisible = !isStrokePopupVisible;
        });
      },
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Container(
          height: strokeWidth, // 현재 굵기 반영
          width: 30,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // 상단 모드 선택바
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        // 왼쪽: 로고
                        Row(
                          children: [
                            Image.asset('assets/images/logo.png', height: 20),
                            const SizedBox(width: 12),
                            const Text('노트 이름 설정',
                                style: TextStyle(fontSize: 14, color: Colors.black87)),
                          ],
                        ),

                        const Spacer(),

                        // 중앙: 손글씨 아이콘만 (항상 고정 위치)
                        GestureDetector(
                          onTap: () => _setMode(drawing: true),
                          child: Image.asset(
                            isDrawingMode
                                ? 'assets/images/clicked_pen.png'
                                : 'assets/images/pen.png',
                            height: 28,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // 오른쪽: 손글씨 모드일 때 도구바 + 나머지 아이콘
                        if (isDrawingMode) ...[
                          const SizedBox(width: 16),
                          _buildColorButton(Colors.black),
                          _buildColorButton(Colors.red),
                          _buildColorButton(Colors.blue),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 50,
                            child: _buildStrokeWidthButton(),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = Colors.white;
                                isEraser = true;
                              });
                            },
                            child: Image.asset(
                              isEraser
                                  ? 'assets/images/clicked_eraser.png'
                                  : 'assets/images/eraser.png',
                              height: 28,
                            ),
                          ),
                          IconButton(
                            onPressed: canUndo
                                ? () {
                              setState(() {
                                redoStack.add(strokes.removeLast());
                                canUndo = strokes.isNotEmpty;
                              });
                            }
                                : null,
                            icon: const Icon(Icons.undo),
                          ),
                          IconButton(
                            onPressed: redoStack.isNotEmpty
                                ? () {
                              setState(() {
                                strokes.add(redoStack.removeLast());
                                canUndo = true;
                              });
                            }
                                : null,
                            icon: const Icon(Icons.redo),
                          ),
                        ],

                        if (isTextMode)
                          Row(
                            children: [
                              _buildColorButton(Colors.black),
                              _buildColorButton(Colors.red),
                              _buildColorButton(Colors.blue),
                              const SizedBox(width: 16),
                              const Text('폰트 크기'),
                              SizedBox(
                                width: 120,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Slider(
                                        value: fontSize,
                                        min: 10,
                                        max: 32,
                                        divisions: 11,
                                        label: fontSize.toStringAsFixed(0),
                                        onChanged: (value) {
                                          setState(() {
                                            fontSize = value;
                                          });
                                        },
                                      ),
                                    ),
                                    Text(fontSize.toInt().toString()),
                                  ],
                                ),
                              ),
                            ],
                          ),


                        // 오른쪽 끝: 키보드 + 선택 아이콘
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _setMode(text: true),
                              child: Image.asset(
                                isTextMode
                                    ? 'assets/images/clicked_keyboard.png'
                                    : 'assets/images/keyboard.png',
                                height: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            GestureDetector(
                              onTap: () => _setMode(select: true),
                              child: Image.asset(
                                isSelectMode
                                    ? 'assets/images/clicked_box.png'
                                    : 'assets/images/box.png',
                                height: 28,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  ),
                ),

                // 필기 영역
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.75),
                        ),
                        child: GestureDetector(
                          onTapUp: isTextMode ? _handleTapUp : null,
                          onPanStart: (details) {
                            if (isDrawingMode) {
                              setState(() {
                                currentPoints = [details.localPosition];
                                redoStack.clear();
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
                                currentPoints.add(details.localPosition);
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
                              setState(() {
                                strokes.add(Stroke(
                                  points: List.from(currentPoints),
                                  color: selectedColor,
                                  strokeWidth: strokeWidth,
                                ));
                                currentPoints = [];
                                canUndo = strokes.isNotEmpty;
                              });
                            } else if (isSelectMode && selectedRect != null) {
                              setState(() {
                                showSaveButton = true;
                              });
                            }
                          },
                          child: Stack(
                            children: [
                              // 캔버스
                              Positioned.fill(
                                child: RepaintBoundary(
                                  key: _repaintKey,
                                  child: CustomPaint(
                                    size: Size.infinite,
                                    painter: DrawingPainter(
                                      strokes,
                                      currentPoints,
                                      selectedColor,
                                      strokeWidth,
                                    ),
                                    child: Container(),
                                  ),
                                ),
                              ),

                              // 텍스트 노트들
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

                              // 선택 영역
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

                              // 선택 영역 해제용
                              if (isSelectMode && selectedRect != null)
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTapDown: (details) {
                                      final buttonRect = Rect.fromLTWH(
                                        selectedRect!.left,
                                        selectedRect!.top - 40,
                                        100,
                                        40,
                                      );
                                      if (!selectedRect!.contains(details.localPosition) &&
                                          !buttonRect.contains(details.localPosition)) {
                                        setState(() {
                                          selectedRect = null;
                                          showSaveButton = false;
                                        });
                                      }
                                    },
                                  ),
                                ),

                              // 텍스트 인식 버튼
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
                                        await Future.delayed(const Duration(milliseconds: 100));
                                        await sendToFlaskOCR();
                                        setState(() {
                                          showSaveButton = false;
                                          selectedRect = null;
                                        });
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        child: Text(
                                          '텍스트 인식',
                                          style: TextStyle(color: Colors.white, fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (isStrokePopupVisible)
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTap: () {
                                      setState(() {
                                        isStrokePopupVisible = false;
                                      });
                                    },
                                    child: Container(), // 빈 transparent 레이어
                                  ),
                                ),
                              if (isStrokePopupVisible)
                                Positioned(
                                  top: 5,
                                  right: 50,
                                  child: Material(
                                    elevation: 4,
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: SizedBox(
                                        width: 160,
                                        child: Slider(
                                          value: strokeWidth,
                                          min: 1,
                                          max: 10,
                                          divisions: 9,
                                          label: strokeWidth.toStringAsFixed(1),
                                          onChanged: (value) {
                                            setState(() {
                                              strokeWidth = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextNote(_TextNote note, {required bool enabled}) {
    return SizedBox(
      width: 150,
      child: TextField(
        controller: note.controller,
        maxLines: null,
        readOnly: !enabled,
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(
          fontSize: note.fontSize,
          color: note.color,
        ),
      ),
    );
  }

  void _handleTapUp(TapUpDetails details) {
    if (!isDrawingMode && isTextMode) {
      setState(() {
        textNotes.add(
          _TextNote(
            position: details.localPosition,
            fontSize: fontSize,
            color: selectedColor,
          ),
        );
      });
    }
  }
}

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset?> currentPoints;
  final Color currentColor;
  final double currentStrokeWidth;

  DrawingPainter(this.strokes, this.currentPoints, this.currentColor, this.currentStrokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // 과거 stroke들
    for (var stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < stroke.points.length - 1; i++) {
        if (stroke.points[i] != null && stroke.points[i + 1] != null) {
          canvas.drawLine(stroke.points[i]!, stroke.points[i + 1]!, paint);
        }
      }
    }

    // 지금 그리고 있는 선
    final currentPaint = Paint()
      ..color = currentColor
      ..strokeWidth = currentStrokeWidth
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < currentPoints.length - 1; i++) {
      if (currentPoints[i] != null && currentPoints[i + 1] != null) {
        canvas.drawLine(currentPoints[i]!, currentPoints[i + 1]!, currentPaint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}


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

class _TextNote {
  Offset position;
  TextEditingController controller;
  double fontSize;
  Color color;

  _TextNote({
    required this.position,
    this.fontSize = 16.0,
    this.color = Colors.black,
    String initialText = '',
  }) : controller = TextEditingController(text: initialText);
}
