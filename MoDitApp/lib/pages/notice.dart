import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'notice_view_popup.dart';

class NoticePage extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  final String currentUserName;

  const NoticePage({
    required this.groupId,
    required this.currentUserEmail,
    required this.currentUserName,
    super.key,
  });

  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  List<Map<String, dynamic>> notices = [];
  final db = FirebaseDatabase.instance.ref();
  int currentPage = 1;
  final int itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    loadNotices();
  }

  void loadNotices() async {
    final noticeSnap = await db.child('groupStudies').child(widget.groupId).child('notices').get();
    if (noticeSnap.exists) {
      final data = Map<String, dynamic>.from(noticeSnap.value as Map);

      final list = data.entries.map((e) {
        final item = Map<String, dynamic>.from(e.value as Map);
        return <String, dynamic>{
          'id': e.key,
          'title': item['title'] ?? '',
          'body': item['body'] ?? '',
          'name': item['name'] ?? '',
          'createdAt': item['createdAt'] ?? 0,
          'pinned': item['pinned'] ?? false,
        };
      }).toList();

      list.sort((a, b) {
        if (a['pinned'] != b['pinned']) {
          return (b['pinned'] ? 1 : 0) - (a['pinned'] ? 1 : 0);
        }
        return (b['createdAt'] as int).compareTo(a['createdAt'] as int);
      });

      setState(() {
        notices = list;
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
              final newRef = db.child('groupStudies').child(widget.groupId).child('notices').push();
              await newRef.set({
                'title': titleController.text,
                'body': bodyController.text,
                'name': widget.currentUserName,
                'createdAt': DateTime.now().millisecondsSinceEpoch,
                'pinned': false,
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

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> get pagedNotices {
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage > notices.length) ? notices.length : start + itemsPerPage;
    return notices.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (notices.length / itemsPerPage).ceil();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('공지사항', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 20),

            // 공지 리스트
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFB8BDF1).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.all(24),
                child: ListView.separated(
                  itemCount: pagedNotices.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final notice = pagedNotices[i];
                    return GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => NoticeViewPopup(
                          title: notice['title'],
                          body: notice['body'],
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ⭐ 왼쪽 별 아이콘
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: GestureDetector(
                                onTap: () async {
                                  await db
                                      .child('groupStudies')
                                      .child(widget.groupId)
                                      .child('notices')
                                      .child(notice['id'])
                                      .update({'pinned': !(notice['pinned'] ?? false)});
                                  loadNotices();
                                },
                                child: Icon(
                                  notice['pinned'] ? Icons.star : Icons.star_border,
                                  color: notice['pinned'] ? Colors.amber : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),

                            // 📄 텍스트 블럭
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(notice['title'], style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(notice['name'], style: const TextStyle(fontSize: 12)),
                                      const Spacer(),
                                      Text(_formatDate(notice['createdAt']), style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
    );
  }
}