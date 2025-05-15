import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class NoteScreen extends StatefulWidget {
  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> with SingleTickerProviderStateMixin {
  bool isDrawingMode = false;
  bool isTextMode = false;
  bool isSelectMode = false;
  bool showSaveButton = false;
  final GlobalKey _repaintKey = GlobalKey();
  int imageCount = 1;
  double fontSize = 16.0;
  bool isStrokePopupVisible = false;
  late final Ticker _ticker;

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

  final GlobalKey _stackKey = GlobalKey();

  // 노트 이름 설정을 위한 변수
  TextEditingController _noteTitleController = TextEditingController();
  bool _isEditingTitle = false; // 사용자가 텍스트 수정할 때 사용

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    })..start(); // 매 프레임마다 재렌더링 요청
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _handleStylusMove(PointerMoveEvent event) {
    if (event.kind == ui.PointerDeviceKind.stylus) {
      currentPoints.add(event.localPosition);
    }
  }

  void _handleStylusDown(PointerDownEvent event) {
    if (event.kind == ui.PointerDeviceKind.stylus) {
      currentPoints = [event.localPosition];
      redoStack.clear();
    }
  }

  void _handleStylusUp(PointerUpEvent event) {
    if (event.kind == ui.PointerDeviceKind.stylus) {
      strokes.add(Stroke(
        points: List.from(currentPoints),
        color: selectedColor,
        strokeWidth: strokeWidth,
      ));
      currentPoints.clear();
      canUndo = strokes.isNotEmpty;
    }
  }

  void _setMode(
      {bool drawing = false, bool text = false, bool select = false}) {
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

  // 노트 이름 설정을 위한 함수
  void _toggleNoteTitleEditing() {
    setState(() {
      _isEditingTitle = !_isEditingTitle;
    });
  }

  // 노트 이름 저장 함수
  void _saveNoteTitle() {
    setState(() {
      _isEditingTitle = false;
    });
    // 여기에서 설정된 제목으로 동작을 구현할 수 있습니다.
    print("노트 이름이 변경되었습니다: ${_noteTitleController.text}");
  }

  Widget _buildNoteTitle() {
    return GestureDetector(
      onTap: _toggleNoteTitleEditing, // 텍스트를 클릭하면 수정모드로 전환
      child: _isEditingTitle
          ? SizedBox(
        width: 160, // 너비 고정
        child: TextField(
          controller: _noteTitleController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '노트 제목을 입력하세요',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 4),
          ),
          onSubmitted: (_) => _saveNoteTitle(),
          style: const TextStyle(fontSize: 17, color: Colors.black87),
        ),
      )
          : SizedBox(
        width: 160, // 텍스트도 같은 너비
        child: Text(
          _noteTitleController.text.isEmpty
              ? '노트 이름 설정'
              : _noteTitleController.text,
          style: const TextStyle(fontSize: 17, color: Colors.black87),
          overflow: TextOverflow.ellipsis, // 길면 ...
        ),
      ),
    );
  }


  Future<void> sendToFlaskOCR() async {
    if (_repaintKey.currentContext == null || selectedRect == null) return;

    await WidgetsBinding.instance.endOfFrame;

    final boundary = _repaintKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    final pixelRatio = 3.0;
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final buffer = byteData.buffer.asUint8List();
    final fullImage = img.decodeImage(buffer);
    if (fullImage == null) return;

    final cropX = (selectedRect!.left * pixelRatio).clamp(
        0, fullImage.width - 1).toInt();
    final cropY = (selectedRect!.top * pixelRatio).clamp(
        0, fullImage.height - 1).toInt();
    final cropWidth = (selectedRect!.width * pixelRatio).clamp(
        1, fullImage.width - cropX).toInt();
    final cropHeight = (selectedRect!.height * pixelRatio).clamp(
        1, fullImage.height - cropY).toInt();

    final cropped = img.copyCrop(
      fullImage,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    final imageBytes = Uint8List.fromList(img.encodeJpg(cropped));

    final uri = Uri.parse('http://192.168.219.111:8080/ocr/upload');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes(
          'image', imageBytes, filename: 'note.jpg'));

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
          return !stroke.points.any((point) =>
          point != null && selectedRect!.contains(point!));
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

    final boundary = _repaintKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
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

  Widget _buildNoteBox(_TextNote note) {
    return Stack(
      clipBehavior: Clip.none, // 버튼이 Stack 밖으로 나가도 표시되도록
      children: [
        // 텍스트 필드 컨테이너
        Container(
          width: note.size.width,
          height: note.size.height,
          decoration: note.isSelected
              ? BoxDecoration(
            border: Border.all(color: Colors.blue, width: 1.5),
          )
              : null,
          child: TextField(
            controller: note.controller,
            focusNode: note.focusNode,
            maxLines: null,
            enabled: !isDrawingMode,
            onTap: () {
              setState(() {
                for (var n in textNotes) n.isSelected = false;
                note.isSelected = true;
                note.focusNode.requestFocus();
              });
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.all(4),
            ),
            style: TextStyle(fontSize: note.fontSize, color: note.color),
          ),
        ),

        // 삭제 버튼
        if (note.isSelected)
          Positioned(
            top: -12, // 버튼을 약간 위로 이동
            left: -12, // 버튼을 약간 왼쪽으로 이동
            child: GestureDetector(
              behavior: HitTestBehavior.opaque, // 터치 영역 명확히
              onTap: () {
                setState(() {
                  textNotes.remove(note);
                });
              },
              child: Container(
                width: 30, // 터치 영역 확대
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue),
                ),
                child: const Icon(Icons.close, size: 18),
              ),
            ),
          ),

        // 크기 조절 핸들
        if (note.isSelected)
          Positioned(
            bottom: -12, // 버튼을 약간 아래로 이동
            right: -12, // 버튼을 약간 오른쪽으로 이동
            child: GestureDetector(
              behavior: HitTestBehavior.opaque, // 터치 영역 명확히
              onPanUpdate: (details) {
                setState(() {
                  final newWidth = note.size.width + details.delta.dx;
                  final newHeight = note.size.height + details.delta.dy;
                  note.size = Size(
                    newWidth.clamp(60, 500),
                    newHeight.clamp(30, 500),
                  );
                });
              },
              child: Container(
                width: 30, // 터치 영역 확대
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue),
                ),
                child: const Icon(Icons.open_in_full, size: 18),
              ),
            ),
          ),
      ],
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
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
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context); // 뒤로가기 동작
                                },
                                child: Image.asset('assets/images/back_button.png', height: 20),
                              ),
                              const SizedBox(width: 12),
                              _buildNoteTitle(),
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
                      child: GestureDetector( // ✅ GestureDetector 추가
                        onTapUp: _handleTapUp, // ✅ onTapUp 콜백 연결
                        behavior: HitTestBehavior.translucent, // ✅ 투명 영역도 터치 이벤트 받도록 설정
                        child: Stack(
                          key: _stackKey,
                          children: [
                            // ① 손글씨 캔버스
                            Positioned.fill(
                              child: RepaintBoundary(
                                key: _repaintKey,
                                child: CustomPaint(
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

                            // 손글씨 입력 영역
                            if (isDrawingMode)
                              Positioned.fill(
                                  child: Listener(
                                    onPointerDown: _handleStylusDown,
                                    onPointerMove: _handleStylusMove,
                                    onPointerUp: _handleStylusUp,
                                    behavior: HitTestBehavior.translucent,
                                    child: Container(),
                                  )
                              ),


                            // ③ 선택 영역 제스처
                            if (isSelectMode)
                              Positioned.fill(
                                child: GestureDetector(
                                  onPanStart: (details) {
                                    setState(() {
                                      dragStart = details.localPosition;
                                      selectedRect = null;
                                    });
                                  },
                                  onPanUpdate: (details) {
                                    setState(() {
                                      dragEnd = details.localPosition;
                                      selectedRect = Rect.fromPoints(dragStart!, dragEnd!);
                                      showSaveButton = false;
                                    });
                                  },
                                  onPanEnd: (_) {
                                    setState(() {
                                      showSaveButton = selectedRect != null;
                                    });
                                  },
                                  behavior: HitTestBehavior.translucent,
                                ),
                              ),

                            // ✅ 3. 텍스트 노트들
                            ...textNotes.map((note) => Positioned(
                              left: note.position.dx,
                              top: note.position.dy,
                              child: isDrawingMode
                                  ? _buildNoteBox(note) // 수정도 못하고 고정
                                  : Draggable(
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: _buildNoteBox(note),
                                ),
                                childWhenDragging: Container(
                                  width: note.size.width,
                                  height: note.size.height,
                                ),
                                onDragEnd: (details) {
                                  final RenderBox box =
                                  _stackKey.currentContext!.findRenderObject() as RenderBox;
                                  final Offset newPosition = box.globalToLocal(details.offset);
                                  setState(() {
                                    note.position = newPosition;
                                  });
                                },
                                child: _buildNoteBox(note),
                              ),
                            )),

                            // ✅ 텍스트 외부 클릭 시 선택 해제용
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: () {
                                  bool anyNoteSelected = textNotes.any((note) => note.isSelected);
                                  setState(() {
                                    for (var note in textNotes) {
                                      note.isSelected = false;
                                      note.focusNode.unfocus();
                                    }
                                  });
                                  if (isTextMode && anyNoteSelected) {
                                    // 선택 해제만 하고 새 텍스트 생성은 _handleTapUp에서 처리
                                  }
                                },
                              ),
                            ),

                            // ✅ 선택 영역
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
                                  child: Container(),
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
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTapUp(TapUpDetails details) {
    if (!isDrawingMode && isTextMode) {
      final tappedPosition = details.localPosition;

      // Check if the tap is inside any existing note
      bool tappedInsideNote = false;
      for (var note in textNotes) {
        final rect = Rect.fromLTWH(
          note.position.dx,
          note.position.dy,
          note.size.width,
          note.size.height,
        );
        if (rect.contains(tappedPosition)) {
          tappedInsideNote = true;
          break;
        }
      }

      // Only create a new note if the tap is outside all notes
      if (!tappedInsideNote) {
        late _TextNote newNote;
        newNote = _TextNote(
          position: tappedPosition,
          fontSize: fontSize,
          color: selectedColor,
          onFocusLost: () {
            setState(() {
              newNote.isSelected = false;
            });
          },
        );

        setState(() {
          for (var n in textNotes) n.isSelected = false;
          newNote.isSelected = true;
          textNotes.add(newNote);
        });

        Future.delayed(const Duration(milliseconds: 50), () {
          newNote.focusNode.requestFocus();
        });
      }
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

    for (var stroke in strokes) {
      _drawSmoothStroke(canvas, stroke.points, stroke.color, stroke.strokeWidth);
    }

    _drawSmoothStroke(canvas, currentPoints, currentColor, currentStrokeWidth);
  }

  void _drawSmoothStroke(Canvas canvas, List<Offset?> points, Color color, double strokeWidth) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final filtered = points.whereType<Offset>().toList();

    if (filtered.length < 2) {
      if (filtered.isNotEmpty) {
        canvas.drawCircle(filtered.first, strokeWidth / 2, paint);
      }
      return;
    }

    path.moveTo(filtered[0].dx, filtered[0].dy);

    for (int i = 1; i < filtered.length - 2; i++) {
      final p0 = filtered[i - 1];
      final p1 = filtered[i];
      final p2 = filtered[i + 1];
      final p3 = filtered[i + 2];

      final controlPoint1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final controlPoint2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );

      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        p2.dx,
        p2.dy,
      );
    }

    // 마지막 선 연결
    path.lineTo(filtered.last.dx, filtered.last.dy);

    canvas.drawPath(path, paint);
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
  FocusNode focusNode;
  double fontSize;
  Color color;
  Size size;
  bool isSelected;

  _TextNote({
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
        isSelected = false; // 선택 해제만
        if (onFocusLost != null) onFocusLost();
      }
    });
  }
}