import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'flask_api.dart';
import 'package:firebase_database/firebase_database.dart';
import 'loading_overlay.dart';
import 'note_summary_popup.dart';
import 'note_utils.dart';
import 'note_models.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';


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
  double fontSize = 16.0;
  bool isStrokePopupVisible = false;
  late final Ticker _ticker;

  List<Stroke> strokes = [];
  List<Offset?> currentPoints = [];
  List<TextNote> textNotes = [];

  Rect? selectedRect;
  Offset? dragStart;
  Offset? dragEnd;

  Color selectedStrokeColor = Colors.black;  // 손글씨용
  Color selectedTextColor = Colors.black;    // 텍스트용
  double strokeWidth = 2.0;
  bool isEraser = false;

  // undo, redo
  bool canUndo = false;
  List<Stroke> redoStack = [];

  // 이미지 기능 추가
  List<ImageNote> imageNotes = [];

  final GlobalKey _stackKey = GlobalKey();

  // 제목 커서 사라지게 하기 위한 변수
  final FocusNode _titleFocusNode = FocusNode();

  // 노트 이름 설정을 위한 변수
  TextEditingController _noteTitleController = TextEditingController();
  bool _isEditingTitle = false; // 사용자가 텍스트 수정할 때 사용

  bool isSaving = false;

  bool isNoteMenuVisible = false;
  Offset? noteMenuPosition;

  Color? customColor;

  bool _isStrokeButtonTapped = false;

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
        // null-safe 처리 추가
        final strokesData = data['strokes'] as List?;
        final textsData = data['texts'] as List?;
        final imagesData = data['images'] as List?;

        // strokes 복원
        if (strokesData != null) {
          strokes = strokesData.map((s) {
            final points = (s['points'] as List)
                .map((p) => Offset(p['x'] * 1.0, p['y'] * 1.0))
                .toList();
            final color = Color(int.parse(s['color'].substring(1), radix: 16));
            return Stroke(points: points, color: color, strokeWidth: s['width'] * 1.0);
          }).toList();
        }

        // textNotes 복원
        if (textsData != null) {
          textNotes = textsData.map<TextNote>((t) {
            return TextNote(
              position: Offset(t['x'] * 1.0, t['y'] * 1.0),
              fontSize: t['fontSize'] * 1.0,
              color: Color(int.parse(t['color'].substring(1), radix: 16)),
              initialText: t['text'],
              size: Size(t['width'] * 1.0, t['height'] * 1.0),
            );
          }).toList();
        }

        // imageNotes 복원
        if (imagesData != null) {
          imageNotes = imagesData.map<ImageNote>((i) {
            double width = i['width'] * 1.0;
            double height = i['height'] * 1.0;
            return ImageNote(
              position: Offset(i['x'] * 1.0, i['y'] * 1.0),
              file: File(i['filePath']),
              size: Size(width, height),
              aspectRatio: width / height,
            );
          }).toList();
        }
      }
    }
    // 손글씨 모드로 시작
    _setMode(drawing: true);

    // 제목 입력란 포커스 해제 시 편집 종료
    _titleFocusNode.addListener(() {
      if (!_titleFocusNode.hasFocus) {
        setState(() {
          _isEditingTitle = false;
        });
      }
    });
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
        color: selectedStrokeColor,
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

  // 이미지를 선택하고, imageNotes 리스트에 저장
  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final decoded = await decodeImageFromList(await File(image.path).readAsBytes());

    double maxWidth = 450;
    double maxHeight = 450;

    double originalWidth = decoded.width.toDouble();
    double originalHeight = decoded.height.toDouble();

    // 비율 유지하며 크기 축소
    double widthRatio = maxWidth / originalWidth;
    double heightRatio = maxHeight / originalHeight;
    double scale = widthRatio < heightRatio ? widthRatio : heightRatio;

    // 비율 유지한 축소된 크기
    double scaledWidth = originalWidth * scale;
    double scaledHeight = originalHeight * scale;

    setState(() {
      imageNotes.add(ImageNote(
        position: const Offset(100, 100),
        file: File(image.path),
        size: Size(scaledWidth, scaledHeight),
        aspectRatio: originalWidth / originalHeight,
      ));
    });

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

  Future<void> _handleBackNavigation() async {
    if (isSaving) return;
    isSaving = true;

    final title = _noteTitleController.text.trim();
    final hasContent = strokes.isNotEmpty || textNotes.isNotEmpty || imageNotes.isNotEmpty;

    if (!hasContent) {
      isSaving = false;
      Navigator.pop(context); // 내용 없으면 그냥 나가기
      return;
    }

    if (title.isEmpty || title == '노트 이름 설정') {
      isSaving = false;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('저장 전'),
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


  //노트 삭제
  Future<void> _handleDeleteNote() async {
    setState(() => isNoteMenuVisible = false);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('정말 삭제하시겠습니까?'),
        content: const Text('삭제한 노트는 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = FirebaseDatabase.instance.ref();
      final userKey = widget.currentUserEmail.replaceAll('.', '_');
      final noteId = widget.existingNoteData?['noteId'];
      final title = widget.existingNoteData?['title'];

      if (noteId != null && title != null) {
        // ✅ 저장된 노트 삭제
        await db.child('notes').child(userKey).child(noteId).remove();
        await Api().deleteNoteFile(widget.currentUserEmail, title);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("노트가 삭제되었습니다"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) Navigator.pop(context, true);
    }
  }

  Widget _buildDraggableNote(TextNote note) {
    return Positioned(
      left: note.position.dx,
      top: note.position.dy,
      child: GestureDetector(
        onPanUpdate: (isDrawingMode || isSelectMode) ? null : (details) {
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

  // 이미지 엑스 버튼, 크기조절
  Widget _buildDraggableImageNote(ImageNote imgNote) {
    return Positioned(
      left: imgNote.position.dx,
      top: imgNote.position.dy,
      child: GestureDetector(
        onTap: () {
          if (isDrawingMode || isSelectMode) return; // 손글씨 모드에서는 무시
          setState(() {
            for (var img in imageNotes) img.isSelected = false;
            imgNote.isSelected = true;
          });
        },
        onPanUpdate: (isDrawingMode || isSelectMode) ? null : (details) {
          setState(() {
            imgNote.position += details.delta;
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: imgNote.size.width,
              height: imgNote.size.height,
              decoration: BoxDecoration(
                border: imgNote.isSelected ? Border.all(color: Colors.grey) : null,
              ),
              child: Image.file(
                imgNote.file,
                fit: BoxFit.contain,
              ),
            ),

            if (imgNote.isSelected)
              Positioned(
                top: -12,
                left: -12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      imageNotes.remove(imgNote);
                    });
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
              ),

            if (imgNote.isSelected)
              Positioned(
                bottom: -12,
                right: -12,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      double newWidth = (imgNote.size.width + details.delta.dx).clamp(20.0, double.infinity);
                      double newHeight = newWidth / imgNote.aspectRatio;
                      imgNote.size = Size(newWidth, newHeight);
                    });
                  },
                  child: Container(
                    width: 40,
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
        ),
      ),
    );
  }


  bool _isInResizeHandle(Offset local, TextNote note) {
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



  Widget _buildResizeHandle(TextNote note) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanUpdate: (details) {
        setState(() {
          final newWidth = note.size.width + details.delta.dx;
          final newHeight = note.size.height + details.delta.dy;

          final screenWidth = MediaQuery.of(context).size.width;

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



  Widget _buildColorButton(Color color, {required bool isForText}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isForText) {
            selectedTextColor = color;
            for (var note in textNotes) {
              if (note.isSelected) {
                note.color = color;
              }
            }
          } else {
            selectedStrokeColor = color;
            isEraser = false;
          }

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
            color: (isForText ? selectedTextColor : selectedStrokeColor) == color
                ? Colors.white
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }

  // 사용자 커스텀 색
  Widget _buildColorPickerButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🖊️ 색상 선택'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: customColor ?? Colors.black,
                onColorChanged: (color) {
                  setState(() {
                    customColor = color;
                    selectedStrokeColor = color;
                    isEraser = false;
                  });
                },
                enableAlpha: false,
                displayThumbColor: true,
              ),
            ),
            actions: [
              TextButton(
                child: const Text('확인'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 30,
        height: 30,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: customColor ?? Colors.grey.shade300,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.add, size: 16, color: Colors.black),
      ),
    );
  }

  Widget _buildStrokeWidthButton() {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        setState(() {
          isStrokePopupVisible = !isStrokePopupVisible;
          _isStrokeButtonTapped = true;
        });
        // 150ms 후 애니메이션 복귀
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) {
            setState(() {
              _isStrokeButtonTapped = false;
            });
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: _isStrokeButtonTapped ? 56 : 48,
        width: _isStrokeButtonTapped ? 56 : 48,
        alignment: Alignment.center,
        curve: Curves.easeOut,
        child: Container(
          height: strokeWidth,
          width: 24,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }


  Widget _buildNoteBox(TextNote note) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // TextField를 Positioned로 감싸 Stack 내에서 아래에 위치하게
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
              enabled: !(isDrawingMode || isSelectMode || isImageMode),
              onTap: () {
                if (isSelectMode || isImageMode) return; // 선택 모드, 이미지 모드일 땐 무시
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

        // 삭제 버튼 - Stack 맨 위에 위치
        if (note.isSelected)
          Positioned(
            top: -12,
            left: -12,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                setState(() {
                  textNotes.remove(note);
                });
              },
              child: Container(
                width: 40,
                height: 40,
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

  // 클릭한 좌표가 이미지나 텍스트 영역에 해당되는지 확인
  void _handleTapDownForDeselect(TapDownDetails details) {
    final pos = details.localPosition;

    bool tappedOnText = textNotes.any((note) {
      final rect = Rect.fromLTWH(note.position.dx, note.position.dy, note.size.width, note.size.height);
      return rect.contains(pos);
    });

    bool tappedOnImage = imageNotes.any((img) {
      final rect = Rect.fromLTWH(img.position.dx, img.position.dy, img.size.width, img.size.height);
      return rect.contains(pos);
    });

    if (!tappedOnText && !tappedOnImage) {
      setState(() {
        for (var note in textNotes) note.isSelected = false;
        for (var img in imageNotes) img.isSelected = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // 직접 pop을 제어하므로 false
      onPopInvoked: (bool didPop) async {
        await _handleBackNavigation(); // 무조건 저장 실행
      },
        child: GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          for (var note in textNotes) {
            note.isSelected = false;
          }
          for (var img in imageNotes) {
            img.isSelected = false;
          }
        });
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
                                  onTap: _handleBackNavigation,
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
                              _buildColorButton(Colors.black, isForText: false),
                              _buildColorButton(Colors.red, isForText: false),
                              _buildColorButton(Colors.blue, isForText: false),
                              _buildColorPickerButton(),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 50,
                                child: _buildStrokeWidthButton(),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedStrokeColor = Colors.white;
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
                                  _buildColorButton(Colors.black, isForText: true),
                                  _buildColorButton(Colors.red, isForText: true),
                                  _buildColorButton(Colors.blue, isForText: true),
                                  const SizedBox(width: 16),
                                  const Text('폰트 크기'),
                                  SizedBox(
                                    width: 250,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              activeTrackColor: Color(0xFFB8BDF1),                // 활성 바 색상
                                              inactiveTrackColor: Color(0xFFB8BDF1).withOpacity(0.3), // 비활성 바 색상
                                              thumbColor: Color(0xFFB8BDF1),                      // 동그란 핸들 색상
                                              overlayColor: Color(0xFFB8BDF1).withOpacity(0.2),   // 클릭 시 퍼지는 색상
                                              valueIndicatorColor: Color(0xFFB8BDF1),             // 말풍선 배경색
                                              valueIndicatorTextStyle: TextStyle(color: Colors.black),
                                            ),
                                            child: Slider(
                                              value: fontSize,
                                              min: 10,
                                              max: 32,
                                              divisions: 11,
                                              label: fontSize.toStringAsFixed(0),
                                              onChanged: (value) {
                                                setState(() {
                                                  fontSize = value;
                                                  for (var note in textNotes) {
                                                    if (note.isSelected) {
                                                      note.fontSize = value;
                                                    }
                                                  }
                                                });
                                              },
                                            ),
                                          )

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
                        child: RepaintBoundary( // 전체 Stack을 감싸도록 이동
                          key: _repaintKey,
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTapDown: (details) {
                              FocusScope.of(context).unfocus(); // 키보드 내려가게
                              _handleTapDownForDeselect(details); // 선택 해제도 같이 처리
                            },
                            onTapUp: _handleTapUp, // 텍스트 모드일 경우 텍스트 추가 처리
                            child: Stack(
                              key: _stackKey,
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _BackgroundPainter(), // 흰 배경만 그리는 별도 페인터
                                  ),
                                ),

                                if (isSelectMode)
                                  Positioned.fill(
                                    child: Listener(
                                      behavior: HitTestBehavior.opaque, // 이미지나 텍스트 위에서도 드래그 이벤트를 받게 함
                                      onPointerDown: (event) {
                                        setState(() {
                                          dragStart = event.localPosition;
                                          selectedRect = null;
                                        });
                                      },
                                      onPointerMove: (event) {
                                        setState(() {
                                          dragEnd = event.localPosition;
                                          selectedRect = Rect.fromPoints(dragStart!, dragEnd!);
                                          showSaveButton = false;
                                        });
                                      },
                                      onPointerUp: (event) {
                                        setState(() {
                                          showSaveButton = selectedRect != null;
                                        });
                                      },
                                    ),
                                  ),

                                // 이미지 또는 텍스트 외 영역 클릭 시 선택 해제용
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTapDown: _handleTapDownForDeselect,
                                    child: Container(),
                                  ),
                                ),

                                if (isTextMode)
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTapUp: (details) {
                                        FocusScope.of(context).unfocus(); // 키보드 내리기
                                        _handleTapUp(details); // 기존 동작 유지
                                      },
                                      child: Container(),
                                    ),
                                  ),

                                // 이미지
                                ...imageNotes.map((imgNote) => _buildDraggableImageNote(imgNote)),
                                // 텍스트
                                ...textNotes.map((note) => _buildDraggableNote(note)),


                                // 4. 손글씨 (항상 맨 위에서 그리기만 함, 터치 이벤트는 막지 않음)
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: DrawingPainter(
                                        strokes,
                                        currentPoints,
                                        selectedStrokeColor,
                                        strokeWidth,
                                      ),
                                    ),
                                  ),
                                ),

                                // 5. 손글씨 입력 리스너는 실제로 펜 모드일 때만 활성화 (터치 감지)
                                if (isDrawingMode)
                                  Positioned.fill(
                                    child: Listener(
                                      onPointerDown: (event) {
                                        if (isStrokePopupVisible) {
                                          setState(() {
                                            isStrokePopupVisible = false;
                                          });
                                        }
                                        _handleStylusDown(event);
                                      },
                                      onPointerMove: _handleStylusMove,
                                      onPointerUp: _handleStylusUp,
                                      behavior: HitTestBehavior.translucent,
                                      child: Container(),
                                    ),
                                  ),

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
                                            final ocrText = await sendToFlaskOCR(
                                              repaintKey: _repaintKey,
                                              selectedRect: selectedRect!,
                                              pixelRatio: 3.0,
                                            );
                                            if (ocrText != null && mounted) {
                                              setState(() {
                                                textNotes.add(TextNote(
                                                  position: Offset(selectedRect!.left, selectedRect!.top),
                                                  initialText: ocrText,
                                                ));
                                                strokes = strokes.where((stroke) {
                                                  return !stroke.points.any((point) => point != null && selectedRect!.contains(point!));
                                                }).toList();
                                                canUndo = strokes.isNotEmpty;
                                                selectedRect = null;
                                                showSaveButton = false;
                                              });
                                            }
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

                                if (isNoteMenuVisible && noteMenuPosition != null)
                                  Positioned(
                                    left: 1390,
                                    top: 10,
                                    child: Material(
                                      elevation: 4,
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            // 요약 버튼 탭 시 동작
                                            onTap: () async {
                                              setState(() => isNoteMenuVisible = false);

                                              await Future.delayed(const Duration(milliseconds: 200)); // 렌더링 대기

                                              try {
                                                final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                                                if (boundary != null) {
                                                  final image = await boundary.toImage(pixelRatio: 3.0);
                                                  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                                                  if (byteData != null) {
                                                    final tempFile = await File('${Directory.systemTemp.path}/note_summary.png').create();
                                                    await tempFile.writeAsBytes(byteData.buffer.asUint8List());

                                                    //print("팝업 호출 직전");
                                                    SummaryPopup.show(context, imageFile: tempFile);
                                                    //print("팝업 호출 직후");
                                                  } else {
                                                    throw Exception("바이트 데이터를 가져올 수 없습니다.");
                                                  }
                                                } else {
                                                  throw Exception("RepaintBoundary 찾기 실패");
                                                }
                                              } catch (e) {
                                                print("요약 처리 중 오류 발생: $e");
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('요약 처리 중 오류가 발생했습니다'), backgroundColor: Colors.red),
                                                  );
                                                }
                                              }
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              child: Text('요약', style: TextStyle(fontSize: 16)),
                                            ),
                                          ),
                                          const Divider(height: 1),
                                          InkWell(
                                            onTap: _handleDeleteNote,
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
                                          width: 250,
                                          child: SliderTheme(
                                            data: SliderTheme.of(context).copyWith(
                                              activeTrackColor: const Color(0xFFB8BDF1),
                                              inactiveTrackColor: const Color(0xFFB8BDF1).withOpacity(0.3),
                                              thumbColor: const Color(0xFFB8BDF1),
                                              overlayColor: const Color(0xFFB8BDF1).withOpacity(0.2),
                                              valueIndicatorColor: const Color(0xFFB8BDF1),
                                              valueIndicatorTextStyle: const TextStyle(color: Colors.black),
                                            ),
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
      late TextNote newNote;
      newNote = TextNote(
        position: tappedPosition,
        fontSize: fontSize,
        color: selectedTextColor,
        size: Size(300, 100), // 텍스트 기본 영역 크기
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
    // final backgroundPaint = Paint()..color = Colors.white;
    // canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

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

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
