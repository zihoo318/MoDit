import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

class TestApiPage extends StatefulWidget {
  const TestApiPage({super.key});

  @override
  State<TestApiPage> createState() => _TestApiPageState();
}

class _TestApiPageState extends State<TestApiPage> {
  Uint8List? fileBytes;
  String? fileName;
  String resultText = '';
  bool showSummarySplit = false;

  final String baseUrl = "http://192.168.219.106:8080"; // Flask 서버 주소
  final String groupName = "테스트스터디";

  final String hardcodedOriginalText = '''SK텔레콤이 모든 직원을 동원해 유심(USIM) 해킹 사태 해결을 위해 총력전에 나섰다. 국내 1위 통신사업자로서의 사회적 역할을 다하겠다는 것이다. 일각에서는 유심사태에 대한 과도한 괴담을 경계하는 목소리도 나온다.

SK텔레콤은 28일 오전 유영상 대표가 주재하는 가운데 긴급 타운홀미팅을 열고 본사 직원들에게 대리점 현장 지원에 적극 나설 것을 독려했다.〈관련기사 4면〉

이날부터 전국 T월드 매장 2600여곳에서 유심 무상교체가 시작됐다.

전국 SK텔레콤 T월드 대리점과 인천공항 등에는 유심을 교체하려는 인파가 몰리며 혼선이 빚어졌다. SK텔레콤의 유심 무료교체 신청을 위한 예약페이지에는 10만명 이상의 대기 인파가 몰려 이용자가 불편을 피하기 어려웠다. 해외 이용자는 출국 후 유심 안심보호서비스, 유심교체 등을 여전히 이용하기 어려운 상황이다.

이같은 혼선에도 아직 유심 복제로 인한 직접적 피해자는 나타나지 않았다. SK텔레콤은 정부와 협의해 피해자가 나타날 경우 피해액 전액을 보상하고, 해외 이용자에 대해서도 대책을 마련키로 했다. 무상 유심교체 서비스와 함께 소프트웨어(SW) 초기화로 기존 물리 유심·이심(e심) 정보를 변환해 피해를 예방하는 기술도 도입할 방침이다.

유영상 대표는 고객 불편과 현장 혼란을 최소화하기 위해 업무를 가리지 않고 총력 대응에 나설 것을 주문했다. SK텔레콤은 본사 직원 뿐 아니라, 유심 교체 대란에 대비해 로밍센터 인력을 평소보다 50% 이상 늘리고 임시 부스를 마련했다. 이같은 조치에도 몰려든 인원을 감당하기에는 역부족이었다.

혼선은 지속되고 있다. 다만, 일부 전문가 사이에서는 과도한 괴담, 포비아(공포증)를 경계해야 한다는 목소리도 나온다. 현재 이동통신 표준상 같은 가입자 정보를 가진 두 대의 단말이 동시에 망에 접속할 수 없기 때문에 복제 심(SIM)이 사용되더라도 즉각 탐지가 가능하고 비정상 인증 탐지(FDS) 시스템으로 차단할 수 있는 것으로 전해졌다. 아직 명확한 피해자가 나타나지 않은 것과 무관하지 않다. 다만, 해커가 일부 이용자의 개인정보를 가지고 있을 경우 유심복제와 연계해 피해가 발생할 가능성은 존재하기 때문에, 근본적 예방조치인 유심 보호서비스, 유심 교체 등에 대한 노력은 지속해야 한다는 주문이다.

김용대 한국과학기술원(KAIST) 교수는 “가장 확실한 대책은 유심 보호 서비스를 활성화하는 것”이라며 “기술적 근거 없이 과도한 공포가 퍼지는 것을 경계해야 한다”고 말했다.''';

  Future<void> pickFile() async {
    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: [XTypeGroup(label: 'audio', extensions: ['m4a', 'mp3', 'wav'])],
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          fileBytes = bytes;
          fileName = file.name;
          resultText = "파일 선택 완료: $fileName";
          showSummarySplit = false;
        });
      }
    } catch (e) {
      setState(() {
        resultText = "파일 선택 중 오류 발생: $e";
      });
    }
  }

  Future<void> sendSTTRequest() async {
    if (fileBytes == null || fileName == null) {
      setState(() {
        resultText = "먼저 음성 파일을 선택하세요";
      });
      return;
    }
    final uri = Uri.parse('$baseUrl/stt/upload');
    final request = http.MultipartRequest('POST', uri);
    final mimeType = lookupMimeType(fileName!) ?? 'audio/m4a';

    request.files.add(http.MultipartFile.fromBytes(
      'voice', fileBytes!, filename: fileName!, contentType: MediaType.parse(mimeType),
    ));
    request.fields['groupName'] = groupName;

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);
      final String textUrl = data['text_url'];
      final textResponse = await http.get(Uri.parse(Uri.encodeFull(textUrl)));
      setState(() {
        resultText = textResponse.body;
        showSummarySplit = false;
      });
    } catch (e) {
      setState(() {
        resultText = "STT 처리 중 오류 발생: $e";
      });
    }
  }

  Future<void> sendSummaryRequest() async {
    final uri = Uri.parse('$baseUrl/summary/generate');
    final fakeUrl = "https://kr.object.ncloudstorage.com/modit-storage/stt_test/%EA%B8%B0%EC%82%AC_test.txt";
    final requestBody = {"fileUrl": fakeUrl, "groupName": groupName};

    try {
      final response = await http.post(uri, headers: {"Content-Type": "application/json"}, body: jsonEncode(requestBody));
      final data = jsonDecode(response.body);
      final summaryUrl = data['summary_url'];
      final textResponse = await http.get(Uri.parse(Uri.encodeFull(summaryUrl)));
      setState(() {
        resultText = textResponse.body;
        showSummarySplit = true;
      });
    } catch (e) {
      setState(() {
        resultText = "요약 처리 중 오류 발생: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Flask API 테스트")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(onPressed: pickFile, icon: const Icon(Icons.attach_file), label: const Text("파일 첨부")),
            const SizedBox(height: 10),
            if (fileName != null) Text("선택된 파일: $fileName"),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(onPressed: sendSTTRequest, icon: const Icon(Icons.record_voice_over), label: const Text("STT 요청")),
                ElevatedButton.icon(onPressed: sendSummaryRequest, icon: const Icon(Icons.summarize), label: const Text("Summary 요청")),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("결과:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: showSummarySplit
                  ? Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey[100],
                      child: SingleChildScrollView(
                        child: SelectableText("원문:\n\n$hardcodedOriginalText", style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey[50],
                      child: SingleChildScrollView(
                        child: SelectableText("요약본:\n\n$resultText", style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                  ),
                ],
              )
                  : Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: SingleChildScrollView(
                  child: SelectableText(resultText, style: const TextStyle(fontSize: 16, fontFamily: "monospace")),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
