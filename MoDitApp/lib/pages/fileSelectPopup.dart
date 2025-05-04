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
      content: SizedBox(
        width: 300, // 팝업 자체의 가로폭 제한
        height: 220,
        child: ListView(
          shrinkWrap: true,
          children: fileOptions.map((file) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // 팝업 닫기
                    onFileSelected(file);    // 콜백 실행
                  },
                  child: Container(
                    width: 220, // 버튼 가로폭 줄임
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.blue[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(file, style: const TextStyle(color: Colors.black)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
