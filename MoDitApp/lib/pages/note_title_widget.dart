// note_title_widget.dart
import 'package:flutter/material.dart';

class NoteTitleWidget extends StatefulWidget {
  final String initialTitle;
  final void Function(String) onTitleSaved;

  const NoteTitleWidget({
    Key? key,
    required this.initialTitle,
    required this.onTitleSaved,
  }) : super(key: key);

  @override
  _NoteTitleWidgetState createState() => _NoteTitleWidgetState();
}

class _NoteTitleWidgetState extends State<NoteTitleWidget> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    widget.onTitleSaved(_controller.text.trim());
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isEditing = true),
      child: _isEditing
          ? SizedBox(
        width: 240,
        child: TextField(
          controller: _controller,
          autofocus: true,
          onSubmitted: (_) => _save(),
          decoration: InputDecoration(
            hintText: '노트 제목을 입력하세요',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 4),
          ),
          style: TextStyle(fontSize: 17, color: Colors.black87),
        ),
      )
          : SizedBox(
        width: 240,
        child: Text(
          _controller.text.isEmpty ? '노트 이름 설정' : _controller.text,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 17, color: Colors.black87),
        ),
      ),
    );
  }
}
