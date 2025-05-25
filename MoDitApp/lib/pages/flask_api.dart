import 'dart:io';
import 'dart:convert'; // jsonDecode 사용을 위해 필요

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // MediaType 사용
import 'package:path/path.dart';
import 'package:mime/mime.dart';

class Api {
  // 공통 API URL 설정
  static const String baseUrl = "http://192.168.45.152:8080";

  Future<Map<String, dynamic>?> uploadVoiceFile(File audioFile, String groupId) async {
    final uri = Uri.parse('$baseUrl/stt/upload');
    final request = http.MultipartRequest('POST', uri);

    final mimeType = lookupMimeType(audioFile.path) ?? 'audio/m4a';

    request.files.add(await http.MultipartFile.fromPath(
      'voice',
      audioFile.path,
      contentType: MediaType.parse(mimeType),
      filename: basename(audioFile.path),
    ));

    request.fields['groupId'] = groupId;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print("================= print 시작 =====================");
    if (response.statusCode == 200) {
      print('업로드 성공');
      print('결과 본문: ${response.body}');
      return jsonDecode(response.body);
    } else {
      print('오류 상태 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');
      return null;
    }
  }

  // 과제 업로드 api (flask에서 ncp object stroage에 업로드)
  Future<Map<String, dynamic>?> uploadTaskFile(File file, String groupId, String userEmail, String taskTitle, String subTaskTitle) async {
    final uri = Uri.parse('$baseUrl/task/upload');
    final request = http.MultipartRequest('POST', uri);

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    request.files.add(await http.MultipartFile.fromPath(
      'task',
      file.path,
      contentType: MediaType.parse(mimeType),
      filename: basename(file.path),
    ));

    // 필드에 필요한 정보 추가
    request.fields['groupId'] = groupId;
    request.fields['userEmail'] = userEmail;
    request.fields['taskTitle'] = taskTitle;
    request.fields['subTaskTitle'] = subTaskTitle;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('과제 업로드 오류: ${response.statusCode}');
      return null;
    }
  }

  // 노트 업로드 api (flask에서 ncp object stroage에 업로드) -> 파베에 url 업로드는 dart에서 해야됨(반환값 확인하기)
  Future<Map<String, dynamic>?> uploadNoteFile(File file, String userEmail, String noteTitle) async {
    final uri = Uri.parse('$baseUrl/note/upload');
    final request = http.MultipartRequest('POST', uri);

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    request.files.add(await http.MultipartFile.fromPath(
      'note',
      file.path,
      contentType: MediaType.parse(mimeType),
      filename: basename(file.path),
    ));

    request.fields['userEmail'] = userEmail;
    request.fields['noteTitle'] = noteTitle;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('노트 업로드 오류: ${response.statusCode}');
      return null;
    }
  }

  // 노트 파일 삭제 요청 (Object Storage에서 삭제)
  Future<void> deleteNoteFile(String userEmail, String noteTitle) async {
    final uri = Uri.parse('$baseUrl/delete_note');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': userEmail,
        'title': noteTitle,
      }),
    );

    if (response.statusCode == 200) {
      print("🗑오브젝트 스토리지 노트 삭제 성공");
    } else {
      print("삭제 실패: ${response.statusCode} ${response.body}");
    }
  }

  // 음성녹음 요약 생성 요청 API
  Future<String?> requestSummary(String fileUrl, String groupName) async {
    final uri = Uri.parse('$baseUrl/summary/generate');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fileUrl': fileUrl,
        'groupName': groupName,
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);

      // 서버에서 summary_text가 비어 있거나 없음
      if ((result['summary_text'] == null || result['summary_text'].toString().trim().isEmpty)) {
        print('요약할 내용이 없습니다.');
        return result['message'];
      }

      print('녹음텍스트 요약 요청 성공');
      print('요약 텍스트: ${result['summary_text']}');
      return result['summary_text'];
    } else {
      print('녹음텍스트 요약 요청 실패: ${response.statusCode}');
      print('본문: ${response.body}');
      return '요약 요청 실패';
    }
  }


  // 스토리지에서 음성녹음파일, 텍스트화 파일, 요약본 한번에 삭제
  Future<void> deleteRecordingFiles({
    required String audioUrl,
    required String textUrl,
    String? summaryUrl,
  }) async {
    final uri = Uri.parse('$baseUrl/stt/delete_audio_text'); // Flask 서버 주소

    final body = {
      'audio_url': audioUrl,
      'text_url': textUrl,
      if (summaryUrl != null) 'summary_url': summaryUrl,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print("스토리지에서 녹음, 텍스트, 요약 삭제 성공");
      print("응답: ${response.body}");
    } else {
      print("삭제 실패: ${response.statusCode} - ${response.body}");
    }
  }


  // 노트 요약(ocr->요약)
  // 노트 캡처 이미지를 서버로 전송하고, 요약된 텍스트를 바로 반환
  Future<String?> uploadNoteImageAndSummarize(File imageFile) async {
    final uri = Uri.parse('$baseUrl/ocr/upload_and_summarize_text');
    final request = http.MultipartRequest('POST', uri);

    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      imageFile.path,
      contentType: MediaType.parse(mimeType),
      filename: basename(imageFile.path),
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      print('요약 결과: ${result['summary']}');
      return result['summary'];
    } else {
      print('요약 실패: ${response.statusCode}');
      print('본문: ${response.body}');
      return null;
    }
  }

  // 과제 새로 등록 시 그룹 구성원들에게 알림
  Future<void> sendTaskAlert(String groupId, String title, String senderEmail) async {
    final url = Uri.parse('${Api.baseUrl}/send_task_alert');
    final body = {
      "groupId": groupId,
      "title": title,
      "senderEmail": senderEmail, // 등록자 이메일
    };

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        print("과제 푸시 알림 전송 성공");
      } else {
        print("과제 푸시 알림 실패: ${res.statusCode} / ${res.body}");
      }
    } catch (e) {
      print("과제 푸시 알림 예외 발생: $e");
    }
  }


  // 공지사항 등록 시 그룹 전체 알림
  Future<void> sendNoticeAlert(String groupId, String title, String senderEmail) async {
    final url = Uri.parse('${Api.baseUrl}/send_notice_alert');
    final body = {
      "groupId": groupId,
      "title": title,
      "senderEmail": senderEmail, // 등록자 이메일 전달
    };

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        print("공지사항 푸시 알림 전송 성공");
      } else {
        print("공지사항 푸시 실패: ${res.statusCode} / ${res.body}");
      }
    } catch (e) {
      print("공지사항 푸시 예외 발생: $e");
    }
  }


}