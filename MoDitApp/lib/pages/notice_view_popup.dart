// notice_view_popup.dart
import 'package:flutter/material.dart';

class NoticeViewPopup extends StatelessWidget {
  final String title;
  final String body;

  const NoticeViewPopup({
    Key? key,
    required this.title,
    required this.body,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        )
      ],
    );
  }
}
