import 'dart:io';
import 'dart:convert'; // jsonDecode 사용을 위해 필요

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // MediaType 사용
import 'package:path/path.dart';
import 'package:mime/mime.dart';

class Api {
  // 공통 API URL 설정
  static const String baseUrl = "http://172.27.176.1:8080";

  Future<Map<String, dynamic>?> uploadVoiceFile(File audioFile, String groupName) async {
    final uri = Uri.parse('$baseUrl/stt/upload');
    final request = http.MultipartRequest('POST', uri);

    final mimeType = lookupMimeType(audioFile.path) ?? 'audio/m4a';

    request.files.add(await http.MultipartFile.fromPath(
      'voice',
      audioFile.path,
      contentType: MediaType.parse(mimeType),
      filename: basename(audioFile.path),
    ));

    // 그룹 이름 추가
    request.fields['groupName'] = groupName;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('오류 발생: ${response.statusCode}');
      return null;
    }
  }

}
