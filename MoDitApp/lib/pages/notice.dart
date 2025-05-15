import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class NoticePage extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  const NoticePage({required this.groupId, required this.currentUserEmail, super.key});

  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  String groupName = '';
  List<Map<String, String>> notices = [];
  final db = FirebaseDatabase.instance.ref();
  int currentPage = 1;
  final int itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    loadNotices();
  }

  void loadNotices() async {
    final noticeSnap = await db.child('notices').child(widget.groupId).get();
    if (noticeSnap.exists) {
      final data = Map<String, dynamic>.from(noticeSnap.value as Map);

      final list = data.entries.map((e) {
        final item = Map<String, dynamic>.from(e.value as Map);
        return <String, String>{
          'title': item['title'] ?? '',
          'body': item['body'] ?? '',
        };
      }).toList();

      setState(() {
        notices = List<Map<String, String>>.from(list.reversed);
      });
    }
  }

  void _showNoticeDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFECE6F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        title: const Text('공지사항 등록'),
        content: SizedBox(
          width: 300,
          height: 180,
          child: Column(
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: '공지사항 제목')),
              TextField(controller: bodyController, decoration: const InputDecoration(labelText: '공지사항 내용'), maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              final newRef = db.child('notices').child(widget.groupId).push();
              await newRef.set({
                'title': titleController.text,
                'body': bodyController.text,
                'createdAt': DateTime.now().millisecondsSinceEpoch,
              });
              Navigator.pop(context);
              loadNotices();
            },
            child: const Text('등록'),
          )
        ],
      ),
    );
  }

  List<Map<String, String>> get pagedNotices {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage > notices.length) ? notices.length : start + itemsPerPage;
    return notices.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (notices.length / itemsPerPage).ceil();

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단바 부분 제거됨

                const SizedBox(height: 0),

                // 공지사항 제목 + 등록
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('공지사항', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    GestureDetector(
                      onTap: _showNoticeDialog,
                      child: Row(
                        children: [
                          const Text('공지사항 등록', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Image.asset('assets/images/plus_icon2.png', width: 20),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 40),

                // 공지사항 리스트
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8BDF1).withOpacity(0.3), // 공지사항 배경색
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: ListView.separated(
                      itemCount: pagedNotices.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pagedNotices[i]['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(pagedNotices[i]['body'] ?? ''),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 페이지네이션
                if (totalPages > 1)
                  Center(
                    child: Wrap(
                      spacing: 8,
                      children: List.generate(
                        totalPages,
                            (index) => GestureDetector(
                          onTap: () => setState(() => currentPage = index + 1),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: currentPage == index + 1 ? FontWeight.bold : FontWeight.normal,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
