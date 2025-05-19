import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'flask_api.dart';
import 'package:firebase_database/firebase_database.dart';
import 'loading_overlay.dart'; // 추가



class NoteScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic>? existingNoteData;
  const NoteScreen({
    required this.currentUserEmail,
    this.existingNoteData,
    Key? key,
  }) : super(key: key);
  @override
  _NoteScreenState createState() => _NoteScreenState();
}


class _NoteScreenState extends State<NoteScreen> with SingleTickerProviderStateMixin {
  // 모드
  bool isDrawingMode = false;
  bool isTextMode = false;
  bool isImageMode = false;
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

  // 이미지 기능 추가
  List<_ImageNote> imageNotes = [];

  final GlobalKey _stackKey = GlobalKey();

  // 제목 커서 사라지게 하기 위한 변수
  final FocusNode _titleFocusNode = FocusNode();

  // 노트 이름 설정을 위한 변수
  TextEditingController _noteTitleController = TextEditingController();
  bool _isEditingTitle = false; // 사용자가 텍스트 수정할 때 사용

  bool isSaving = false;

  bool isNoteMenuVisible = false;
  Offset? noteMenuPosition;


  @override
  void initState() {
    super.initState();
    _ticker = createTicker((_) {
      if (mounted) setState(() {});
    })..start(); // 매 프레임마다 재렌더링 요청

    if (widget.existingNoteData != null)
      print('💡 기존 노트 데이터: ${widget.existingNoteData}');

    if (widget.existingNoteData != null) {
      _noteTitleController.text = widget.existingNoteData!['title'] ?? '';

      final data = widget.existingNoteData!['data'];
      if (data != null) {
        // ✅ null-safe 처리 추가
        final strokesData = data['strokes'] as List?;
        final textsData = data['texts'] as List?;
        final imagesData = data['images'] as List?;

        // 🔁 strokes 복원
        if (strokesData != null) {
          strokes = strokesData.map((s) {
            final points = (s['points'] as List)
                .map((p) => Offset(p['x'] * 1.0, p['y'] * 1.0))
                .toList();
            final color = Color(int.parse(s['color'].substring(1), radix: 16));
            return Stroke(points: points, color: color, strokeWidth: s['width'] * 1.0);
          }).toList();
        }

        // 🔁 textNotes 복원
        if (textsData != null) {
          textNotes = textsData.map<_TextNote>((t) {
            return _TextNote(
              position: Offset(t['x'] * 1.0, t['y'] * 1.0),
              fontSize: t['fontSize'] * 1.0,
              color: Color(int.parse(t['color'].substring(1), radix: 16)),
              initialText: t['text'],
              size: Size(t['width'] * 1.0, t['height'] * 1.0),
            );
          }).toList();
        }

        // 🔁 imageNotes 복원
        if (imagesData != null) {
          imageNotes = imagesData.map<_ImageNote>((i) {
            return _ImageNote(
              position: Offset(i['x'] * 1.0, i['y'] * 1.0),
              file: File(i['filePath']),
              size: Size(i['width'] * 1.0, i['height'] * 1.0),
            );
          }).toList();
        }
      }
    }
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

  void _setMode({
    bool drawing = false,
    bool text = false,
    bool image = false,
    bool select = false,
  }) {
    setState(() {
      isDrawingMode = drawing;
      isTextMode = text;
      isImageMode = image;
      isSelectMode = select;

      // 빈 텍스트 필드 자동 삭제
      if (!text) {
        textNotes.removeWhere((note) =>
        note.controller.text.trim().isEmpty &&
            !note.focusNode.hasFocus);
      }

      if (!select) {
        selectedRect = null;
        showSaveButton = false;
      }
    });

    // 이미지 모드 진입 시 갤러리 열기
    if (image) {
      _pickImage();
    }
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
    _titleFocusNode.unfocus();
    print("노트 이름이 변경되었습니다: ${_noteTitleController.text}");
  }

  Widget _buildNoteTitle() {
    return GestureDetector(
      onTap: _toggleNoteTitleEditing, // 텍스트를 클릭하면 수정모드로 전환
      child: _isEditingTitle
          ? SizedBox(
        width: 240, // 너비 고정
        child: TextField(
          controller: _noteTitleController,
          focusNode: _titleFocusNode,
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
        width: 240, // 텍스트도 같은 너비
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

  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      imageNotes.add(_ImageNote(
        position: const Offset(100, 100),
        file: File(image.path),
      ));
    });
  }


  Future<void> sendToFlaskOCR() async {
    if (_repaintKey.currentContext == null || selectedRect == null) return;

    print("[🖼️] 선택된 영역 캡처 시작");

    await WidgetsBinding.instance.endOfFrame;

    final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final pixelRatio = 3.0;
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      print("[⚠️] 이미지 캡처 실패 - byteData null");
      return;
    }

    final buffer = byteData.buffer.asUint8List();
    final fullImage = img.decodeImage(buffer);
    if (fullImage == null) {
      print("[⚠️] 이미지 디코딩 실패");
      return;
    }

    final cropX = (selectedRect!.left * pixelRatio).clamp(0, fullImage.width - 1).toInt();
    final cropY = (selectedRect!.top * pixelRatio).clamp(0, fullImage.height - 1).toInt();
    final cropWidth = (selectedRect!.width * pixelRatio).clamp(1, fullImage.width - cropX).toInt();
    final cropHeight = (selectedRect!.height * pixelRatio).clamp(1, fullImage.height - cropY).toInt();

    print("[✂️] 선택 영역 자르기: x=$cropX, y=$cropY, w=$cropWidth, h=$cropHeight");

    final cropped = img.copyCrop(fullImage, x: cropX, y: cropY, width: cropWidth, height: cropHeight);
    final imageBytes = Uint8List.fromList(img.encodeJpg(cropped));

    print("[🚀] Flask 서버로 전송 시작");

    final uri = Uri.parse('http://192.168.219.110:8080/ocr/upload');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: 'note.jpg'));

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      print("[📨] Flask 응답 상태코드: ${response.statusCode}");
      print("[📨] Flask 응답 내용: $respStr");

      final result = jsonDecode(respStr);
      if (response.statusCode == 200) {
        final text = result['text'] ?? '';
        print("[✅] 텍스트 추출 완료: $text");

        setState(() {
          textNotes.add(_TextNote(
            position: Offset(selectedRect!.left, selectedRect!.top),
            initialText: text,
          ));
          strokes = strokes.where((stroke) {
            return !stroke.points.any((point) => point != null && selectedRect!.contains(point!));
          }).toList();
          canUndo = strokes.isNotEmpty;
          selectedRect = null;
          showSaveButton = false;
        });
      } else {
        print("[❌] 서버 오류 발생: 상태코드 ${response.statusCode}");
      }
    } catch (e) {
      print("[❗] 예외 발생: $e");
    }
  }


  Future<void> _captureAndUploadNote() async {
    String title = '';
    String fileUrl = '';

    try {
      final boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = Directory.systemTemp;
      final file = await File('${tempDir.path}/note_capture_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(pngBytes);

      title = _noteTitleController.text.trim();
      if (title.isEmpty || title == '노트 이름 설정') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("노트 제목을 먼저 설정해주세요"),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final db = FirebaseDatabase.instance.ref();
      final userKey = widget.currentUserEmail.replaceAll('.', '_');
      final api = Api();

      final isExistingNote = widget.existingNoteData != null && widget.existingNoteData!['noteId'] != null;
      final originalTitle = widget.existingNoteData?['title'];
      final isTitleChanged = title != originalTitle;

      // 새 제목이면 중복 검사 후 갱신
      if (isTitleChanged) {
        title = await getUniqueNoteTitle(title, widget.currentUserEmail);
        _noteTitleController.text = title;
      }

      // 이미지 업로드
      final result = await api.uploadNoteFile(file, widget.currentUserEmail, title);
      if (result != null && result['file_url'] != null) {
        fileUrl = result['file_url'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("노트가 저장되었습니다"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("노트 업로드 실패"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // JSON 데이터 준비
      final strokeJson = strokes.map((s) => {
        'points': s.points.whereType<Offset>().map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'color': '#${s.color.value.toRadixString(16).padLeft(8, '0')}',
        'width': s.strokeWidth,
      }).toList();

      final textJson = textNotes.map((t) => {
        'x': t.position.dx,
        'y': t.position.dy,
        'text': t.controller.text,
        'fontSize': t.fontSize,
        'color': '#${t.color.value.toRadixString(16).padLeft(8, '0')}',
        'width': t.size.width,
        'height': t.size.height,
      }).toList();

      final imageJson = imageNotes.map((i) => {
        'x': i.position.dx,
        'y': i.position.dy,
        'filePath': i.file.path,
        'width': i.size.width,
        'height': i.size.height,
      }).toList();

      // 기존 노트 삭제 조건
      if (isExistingNote && isTitleChanged) {
        final oldNoteId = widget.existingNoteData!['noteId'];
        if (oldNoteId != null) {
          await db.child('notes').child(userKey).child(oldNoteId).remove();
          await api.deleteNoteFile(widget.currentUserEmail, originalTitle ?? '');
        }
      }

      // 새 노트 저장
      String noteId;
      if (isExistingNote && !isTitleChanged) {
        // 덮어쓰기
        noteId = widget.existingNoteData!['noteId'];
      } else {
        // 새로 push
        noteId = db.child('notes').child(userKey).push().key!;
      }

      await db.child('notes').child(userKey).child(noteId).set({
        'title': title,
        'imageUrl': fileUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'data': {
          'strokes': strokeJson,
          'texts': textJson,
          'images': imageJson,
        }
      });


    } catch (e) {
      print("❌ 노트 저장 중 오류 발생: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("오류 발생: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }


  // 제목이 중복되면 자동으로 (1), (2) ... 붙여주는 함수
  Future<String> getUniqueNoteTitle(String baseTitle, String userEmail) async {
    final db = FirebaseDatabase.instance.ref();
    final userKey = userEmail.replaceAll('.', '_');

    final snapshot = await db.child('notes').child(userKey).get();
    if (!snapshot.exists) return baseTitle;

    final existingTitles = <String>{};
    final notesMap = Map<String, dynamic>.from(snapshot.value as Map);
    for (var note in notesMap.values) {
      if (note is Map && note['title'] is String) {
        existingTitles.add(note['title']);
      }
    }

    // 중복 검사
    if (!existingTitles.contains(baseTitle)) return baseTitle;

    int counter = 1;
    String newTitle;
    do {
      newTitle = '$baseTitle ($counter)';
      counter++;
    } while (existingTitles.contains(newTitle));

    return newTitle;
  }




  Widget _buildDraggableNote(_TextNote note) {
    return Positioned(
      left: note.position.dx,
      top: note.position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          // 크기 조절 핸들 누른 경우 이동 금지
          if (_isInResizeHandle(details.localPosition, note)) return;

          setState(() {
            note.position += details.delta;
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _buildNoteBox(note),
            if (note.isSelected)
              Positioned(
                bottom: -12,
                right: -12,
                child: _buildResizeHandle(note),
              ),
          ],
        ),
      ),
    );
  }

  bool _isInResizeHandle(Offset local, _TextNote note) {
    // note 내부 좌표 기준으로 핸들 위치 정의
    const double handleSize = 40;
    final handleRect = Rect.fromLTWH(
      note.size.width - handleSize,
      note.size.height - handleSize,
      handleSize,
      handleSize,
    );
    return handleRect.contains(local);
  }



  Widget _buildResizeHandle(_TextNote note) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (details) {
        setState(() {
          final newWidth = note.size.width + details.delta.dx;
          final newHeight = note.size.height + details.delta.dy;

          final screenWidth = MediaQuery.of(context).size.width;
          final screenHeight = MediaQuery.of(context).size.height;

          note.size = Size(
            newWidth.clamp(60.0, screenWidth - 80), // 양쪽 여백 고려
            newHeight.clamp(30.0, screenWidth - 80),
          );
        });
      },
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey, width: 1.5),
        ),
        child: const Icon(Icons.open_in_full, size: 18),
      ),
    );
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
            color: selectedColor == color ? Colors.white : Colors.transparent,
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
      clipBehavior: Clip.none,
      children: [
        // ✅ TextField를 Positioned로 감싸 Stack 내에서 아래에 위치하게
        Positioned(
          child: Container(
            width: note.size.width,
            height: note.size.height,
            decoration: note.isSelected
                ? BoxDecoration(
              border: Border.all(color: Colors.grey, width: 1.5),
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
        ),

        // ✅ 삭제 버튼 - Stack 맨 위에 위치
        if (note.isSelected)
          Positioned(
            top: -12,
            left: -12,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                print("❌ 삭제 버튼 클릭됨");
                setState(() {
                  textNotes.remove(note);
                });
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 1.5),
                ),
                child: const Icon(Icons.close, size: 18),
              ),
            ),
          ),

        // 크기 조절 핸들
        if (note.isSelected)
          Positioned(
            bottom: -12,
            right: -12,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) {
                setState(() {
                  for (var n in textNotes) n.isSelected = false;
                  note.isSelected = true;
                });
              },
              onPanUpdate: (details) {
                setState(() {
                  final newWidth = note.size.width + details.delta.dx;
                  final newHeight = note.size.height + details.delta.dy;

                  // 크기 제한
                  final clampedWidth = newWidth.clamp(60.0, 500.0);
                  final clampedHeight = newHeight.clamp(30.0, 500.0);

                  note.size = Size(clampedWidth, clampedHeight);
                });
              },
              child: Container(
                width: 40, // 최소한의 터치 영역 확보
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // 🔴 키보드 내려가면 포커스 해제
      },
      child: Scaffold(
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
                                //뒤로가기 버튼 누르면 노트 저장
                                GestureDetector(
                                  // NoteScreen.dart 파일의 뒤로가기 버튼 onTap 수정
                                  onTap: () async {
                                    if (isSaving) return;
                                    isSaving = true;

                                    final title = _noteTitleController.text.trim();

                                    if (title.isEmpty || title == '노트 이름 설정') {
                                      isSaving = false;
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('알림'),
                                          content: const Text('노트 이름을 먼저 설정해주세요.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('확인'),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }


                                    LoadingOverlay.show(context, message: '노트 저장 중...');
                                    try {
                                      await _captureAndUploadNote();
                                    } finally {
                                      LoadingOverlay.hide();
                                      isSaving = false;
                                      if (mounted) Navigator.pop(context, true);
                                    }
                                  }
                                  ,
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


                            // 오른쪽 끝: 키보드 + 선택 아이콘 + 메뉴 아이콘
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
                                  onTap: () => _setMode(image: true),
                                  child: Image.asset(
                                    isImageMode
                                        ? 'assets/images/clicked_image.png'
                                        : 'assets/images/image.png',
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
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTapDown: (details) {
                                    setState(() {
                                      isNoteMenuVisible = !isNoteMenuVisible;
                                      noteMenuPosition = details.globalPosition;
                                    });
                                  },
                                  child: Image.asset(
                                    'assets/images/menu.png',
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
                        child: RepaintBoundary( // ✅ 전체 Stack을 감싸도록 이동
                          key: _repaintKey,
                          child: GestureDetector(
                            onTapUp: _handleTapUp,
                            behavior: HitTestBehavior.translucent,
                            child: Stack(
                              key: _stackKey,
                              children: [
                                // 기존 CustomPaint만 감싸던 RepaintBoundary는 삭제
                                Positioned.fill(
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

                                if (isDrawingMode)
                                  Positioned.fill(
                                    child: Listener(
                                      onPointerDown: _handleStylusDown,
                                      onPointerMove: _handleStylusMove,
                                      onPointerUp: _handleStylusUp,
                                      behavior: HitTestBehavior.translucent,
                                      child: Container(),
                                    ),
                                  ),

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

                                ...textNotes.map((note) => _buildDraggableNote(note)),

                                ...imageNotes.map((imgNote) {
                                  return Positioned(
                                    left: imgNote.position.dx,
                                    top: imgNote.position.dy,
                                    child: GestureDetector(
                                      onPanUpdate: (details) {
                                        setState(() {
                                          imgNote.position += details.delta;
                                        });
                                      },
                                      child: Container(
                                        width: imgNote.size.width,
                                        height: imgNote.size.height,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                        ),
                                        child: Image.network(
                                          '${imgNote.file.path}?t=${DateTime.now().millisecondsSinceEpoch}',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                }),

                                if (selectedRect != null)
                                  Positioned(
                                    left: selectedRect!.left,
                                    top: selectedRect!.top,
                                    child: Container(
                                      width: selectedRect!.width,
                                      height: selectedRect!.height,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey, width: 2),
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),

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
                                          LoadingOverlay.show(context, message: '텍스트 추출 중...');
                                          try {
                                            await sendToFlaskOCR(); // ✅ 텍스트 추출 로직 실행
                                            setState(() {
                                              showSaveButton = false;
                                              selectedRect = null;
                                            });
                                          } catch (e) {
                                            print("❌ 텍스트 추출 중 오류 발생: $e");
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("텍스트 추출 중 오류 발생: $e"),
                                                backgroundColor: Colors.red,
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          } finally {
                                            LoadingOverlay.hide();
                                          }
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

                                if (isNoteMenuVisible && noteMenuPosition != null)
                                  Positioned(
                                    left: noteMenuPosition!.dx - 60,
                                    top: noteMenuPosition!.dy + 10 - MediaQuery.of(context).padding.top,
                                    child: Material(
                                      elevation: 4,
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              print('📄 요약 실행'); // TODO: 실제 요약 함수로 연결
                                              setState(() {
                                                isNoteMenuVisible = false;
                                              });
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              child: Text('요약', style: TextStyle(fontSize: 16)),
                                            ),
                                          ),
                                          const Divider(height: 1),
                                          InkWell(
                                            onTap: () {
                                              print('🗑️ 삭제 실행'); // TODO: 실제 삭제 함수로 연결
                                              setState(() {
                                                isNoteMenuVisible = false;
                                              });
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              child: Text('삭제', style: TextStyle(fontSize: 16, color: Colors.red)),
                                            ),
                                          ),
                                        ],
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
                                if (isNoteMenuVisible)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isNoteMenuVisible = false;
                                        });
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                      ),
                                    ),
                                  ),

                              ],
                            ),
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
      ),
    );
  }

  void _handleTapUp(TapUpDetails details) {
    if (!isDrawingMode && isTextMode) {
      final tappedPosition = details.localPosition;

      // 이미 선택된 노트가 있는 경우: 선택 해제만
      final tappedInsideNote = textNotes.any((note) {
        final rect = Rect.fromLTWH(
          note.position.dx,
          note.position.dy,
          note.size.width,
          note.size.height,
        );
        return rect.contains(tappedPosition);
      });

      if (tappedInsideNote) {
        // 이미 선택된 노트라면 아무것도 하지 않음 (또는 선택 유지)
        return;
      } else if (textNotes.any((n) => n.isSelected)) {
        // 다른 데 눌렀고 선택된 노트가 있었다면 → 선택 해제만
        setState(() {
          for (var n in textNotes) n.isSelected = false;
        });
        return;
      }

      // 아무 노트도 선택 안 되어 있고, 노트 영역도 아니라면 → 새 노트 생성
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
      // 포커스를 잃었을 때 드래그 중이면 선택 유지
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

class _ImageNote {
  Offset position;
  File file;
  Size size;
  bool isSelected;

  _ImageNote({
    required this.position,
    required this.file,
    this.size = const Size(150, 150),
    this.isSelected = false,
  });
}