import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'flask_api.dart';

class SummaryPopup extends StatefulWidget {
  final File imageFile;

  const SummaryPopup({super.key, required this.imageFile});

  static void show(BuildContext context, {required File imageFile}) {
    print("팝업 호출됨");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => SummaryPopup(imageFile: imageFile),
    );
  }

  @override
  State<SummaryPopup> createState() => _SummaryPopupState();
}

class _SummaryPopupState extends State<SummaryPopup> {
  String? summaryText;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final result = await Api().uploadNoteImageAndSummarize(widget.imageFile);
      if (mounted) {
        setState(() {
          summaryText = result ?? '요약 결과가 없습니다.';
          isLoading = false;
        });
      }
    } catch (e) {
      print("\u274c 요약 실패: $e");
      if (mounted) {
        setState(() {
          summaryText = '요약 중 오류가 발생했습니다.';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFF9F9FD),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: 500,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🧠 노트 요약 결과',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D0A64))),
            const SizedBox(height: 12),
            const Divider(thickness: 1, color: Color(0xFF0D0A64)),
            const SizedBox(height: 12),
            isLoading
                ? SizedBox(
              width: double.infinity, // 팝업 너비에 맞춤
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  SizedBox(height: 40),
                  Center(child: CircularProgressIndicator()),
                  SizedBox(height: 16),
                  Text(
                    "AI가 열심히 요약 중입니다...",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                ],
              ),
            )
                : SizedBox(
              height: 300,
              child: SingleChildScrollView(
                child: SelectableText(
                  summaryText ?? '',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isLoading)
                  TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: summaryText ?? ''));
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        SnackBar(
                          content: const Text(
                            "복사되었습니다.",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: const Color(0xFFEAEAFF),
                        ),
                      );
                    },
                    child: const Text('복사'),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class DialogBackgroundWrapper extends StatelessWidget {
  const DialogBackgroundWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withOpacity(0.3),
      ),
    );
  }
}
