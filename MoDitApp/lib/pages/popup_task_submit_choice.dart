import 'package:flutter/material.dart';

class SubmitChoicePopup extends StatelessWidget {
  final VoidCallback onInternalNoteSelected;
  final VoidCallback onExternalFileSelected;

  const SubmitChoicePopup({
    Key? key,
    required this.onInternalNoteSelected,
    required this.onExternalFileSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFE7E5FC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        '제출 방식 선택',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D0A64),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '노트에서 만든 파일을 제출하시겠습니까?\n아니면 기기에서 파일을 선택하시겠습니까?',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onInternalNoteSelected();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB0B8FC),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('모딧 노트 파일 제출', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(context);
              onExternalFileSelected();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0D0A64),
              side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('외부 파일 선택', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
