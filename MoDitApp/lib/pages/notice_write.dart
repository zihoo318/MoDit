/*
// notice_write.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NoticeWritePage extends StatefulWidget {
  const NoticeWritePage({super.key});

  @override
  State<NoticeWritePage> createState() => _NoticeWritePageState();
}

class _NoticeWritePageState extends State<NoticeWritePage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _database = FirebaseDatabase.instance.ref('notices');

  void _saveNotice() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;

    _database.push().set({
      'title': title,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    }).then((_) {
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background1.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text('공지사항 작성', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: '제목'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    maxLines: 10,
                    decoration: const InputDecoration(labelText: '내용'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _saveNotice,
                    child: const Text('저장'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 */
