import 'package:flutter/material.dart';

class FileSelectPopup extends StatelessWidget {
  final List<String> fileOptions;
  final Function(String) onFileSelected;

  const FileSelectPopup({
    super.key,
    required this.fileOptions,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('제출할 파일을 선택하세요'),
      backgroundColor: const Color(0xFFDBEDFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(
          maxHeight: 300, // 팝업 내부 최대 높이 지정
        ),
        child: ListView(
          shrinkWrap: true,
          children: fileOptions.map((file) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context); // 팝업 닫기
                  onFileSelected(file);    // 선택한 파일 반환
                },
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(file, style: const TextStyle(color: Colors.black)),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
