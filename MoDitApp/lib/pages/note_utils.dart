// note_screen에서 비즈니스 로직 유틸 함수 분리
import 'dart:typed_data';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'flask_api.dart';


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

//선택 영역 캡쳐
Future<Uint8List?> captureSelectedArea({
  required GlobalKey repaintKey,
  required Rect selectedRect,
}) async {
  await WidgetsBinding.instance.endOfFrame;

  final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final ui.Image image = await boundary.toImage(pixelRatio: 5.0); // 또는 6.0까지
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return null;

  final fullImage = img.decodeImage(byteData.buffer.asUint8List());
  if (fullImage == null) return null;

  final cropped = img.copyCrop(
    fullImage,
    x: selectedRect.left.toInt(),
    y: selectedRect.top.toInt(),
    width: selectedRect.width.toInt(),
    height: selectedRect.height.toInt(),
  );

  return Uint8List.fromList(img.encodeJpg(cropped));
}


Future<String?> sendToFlaskOCR({
  required GlobalKey drawingKey, // ✅ 이름 명확하게 변경
  required Rect selectedRect,
  required double pixelRatio,
}) async {
  print("[🖼️] 손글씨만 캡처 시작");
  print('MoDitLog: start taking screenshots ');

  await WidgetsBinding.instance.endOfFrame;

  final boundary = drawingKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return null;

  final buffer = byteData.buffer.asUint8List();
  final fullImage = img.decodeImage(buffer);
  if (fullImage == null) return null;

  final cropX = (selectedRect.left * pixelRatio).clamp(0, fullImage.width - 1).toInt();
  final cropY = (selectedRect.top * pixelRatio).clamp(0, fullImage.height - 1).toInt();
  final cropWidth = (selectedRect.width * pixelRatio).clamp(1, fullImage.width - cropX).toInt();
  final cropHeight = (selectedRect.height * pixelRatio).clamp(1, fullImage.height - cropY).toInt();

  final cropped = img.copyCrop(
    fullImage,
    x: cropX,
    y: cropY,
    width: cropWidth,
    height: cropHeight,
  );

  final imageBytes = Uint8List.fromList(img.encodeJpg(cropped));

  final uri = Uri.parse('${Api.baseUrl}/ocr/upload');
  final request = http.MultipartRequest('POST', uri)
    ..files.add(http.MultipartFile.fromBytes('image', imageBytes, filename: 'note.jpg'));

  try {
    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      print('MoDitLog: Successfully received  OCR API results');
      final result = jsonDecode(respStr);
      return result['text'] ?? '';
    }
  } catch (e) {
    print('MoDitLog: flask ocr error');
    print("❗ Flask OCR 오류: $e");
  }

  return null;
}

