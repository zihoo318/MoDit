import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'flask_api.dart';
import 'loading_overlay.dart';

class SummaryPopup extends StatefulWidget {
  final File imageFile;

  const SummaryPopup({super.key, required this.imageFile});

  static void show(BuildContext context, {required File imageFile}) {
    showDialog(
      context: context,
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
      print("❌ 요약 실패: $e");
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
    return AlertDialog(
      title: const Text('요약 결과'),
      content: SizedBox(
        width: 300,
        child: isLoading
            ? const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        )
            : SingleChildScrollView(
          child: SelectableText(summaryText ?? '', style: const TextStyle(fontSize: 15)),
        ),
      ),
      actions: [
        if (!isLoading)
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: summaryText ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('복사되었습니다')),
              );
            },
            child: const Text('복사'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
