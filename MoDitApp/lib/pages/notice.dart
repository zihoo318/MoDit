import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:ui';

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
  Map<String, dynamic>? selectedNotice;

  @override
  void initState() {
    super.initState();
    loadNotices();
  }

  void loadNotices() async {
    final noticeSnap = await db
        .child('groupStudies')
        .child(widget.groupId)
        .child('notices')
        .get();
    if (noticeSnap.exists) {
      final data = Map<String, dynamic>.from(noticeSnap.value as Map);

      final list = data.entries.map((e) {
        final item = Map<String, dynamic>.from(e.value as Map);
        return <String, dynamic>{
          'id': e.key,
          'title': item['title'] ?? '',
          'body': item['body'] ?? '',
          'name': item['name'] ?? '',
          'email': item['email'] ?? '',
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
        selectedNotice = null;
      });
    }
  }

  void _showNoticeDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierLabel: "공지사항 등록",
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(), // 배경 탭 시 키보드 닫기
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 250),
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                  curve: Curves.easeOut,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 500,
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    child: SingleChildScrollView( // 세로 스크롤 허용
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '📢 공지사항 등록',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D0A64),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextField(
                                  controller: titleController,
                                  decoration: const InputDecoration(
                                    labelText: '공지사항 제목',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 17),
                                TextField(
                                  controller: bodyController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: '공지사항 내용',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("취소"),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                                        foregroundColor: const Color(0xFF0D0A64),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () async {
                                        final newRef = db.child('groupStudies').child(widget.groupId).child('notices').push();
                                        await newRef.set({
                                          'title': titleController.text,
                                          'body': bodyController.text,
                                          'name': widget.currentUserName,
                                          'email': widget.currentUserEmail,
                                          'createdAt': DateTime.now().millisecondsSinceEpoch,
                                          'pinned': false,
                                        });
                                        Navigator.pop(context);
                                        loadNotices();
                                      },
                                      child: const Text("등록"),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                                        foregroundColor: const Color(0xFF0D0A64),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }



  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day
        .toString().padLeft(2, '0')}';
  }

  Widget _buildNoticeList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: notices.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (_, i) {
              final notice = notices[i];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque, // 투명 영역도 터치 감지
                  onTap: () => setState(() => selectedNotice = notice),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: IconButton(
                          key: ValueKey<bool>(notice['pinned'] ?? false),
                          icon: Icon(
                            notice['pinned'] ? Icons.star : Icons.star_border,
                            color: notice['pinned'] ? Colors.amber : null,                          ),
                          onPressed: () async {
                            final newValue = !(notice['pinned'] ?? false);
                            await db
                                .child('groupStudies')
                                .child(widget.groupId)
                                .child('notices')
                                .child(notice['id'])
                                .update({'pinned': newValue});
                            loadNotices();
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
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
      ],
    );
  }

  void _editNotice(Map<String, dynamic> notice) {
    final titleController = TextEditingController(text: notice['title']);
    final bodyController = TextEditingController(text: notice['body']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공지사항 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '내용'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              final id = notice['id'];
              await db
                  .child('groupStudies')
                  .child(widget.groupId)
                  .child('notices')
                  .child(id)
                  .update({
                'title': titleController.text.trim(),
                'body': bodyController.text.trim(),
              });
              Navigator.pop(context);
              loadNotices();
            },
            child: const Text('저장', style: TextStyle(color: Color(0xFF0D0A64))),
          ),
        ],
      ),
    );
  }

  void _deleteNotice(Map<String, dynamic> notice) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('공지사항 삭제'),
        content: Text('‘${notice['title']}’ 공지사항을 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await db
          .child('groupStudies')
          .child(widget.groupId)
          .child('notices')
          .child(notice['id'])
          .remove();
      setState(() {
        selectedNotice = null;
      });
      loadNotices();
    }
  }

  Widget _buildNoticeDetail() {
    if (selectedNotice == null) {
      return const Center(child: Text('공지사항을 선택하세요'));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedNotice!['title'],
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              if (selectedNotice!['pinned'] == true)
                const Icon(Icons.star, color: Colors.amber, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('작성자: ${selectedNotice!['name']}', style: const TextStyle(fontSize: 14)),
              const Spacer(),
              Text('작성일: ${_formatDate(selectedNotice!['createdAt'])}', style: const TextStyle(fontSize: 14)),
            ],
          ),
          const Divider(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Text(selectedNotice!['body'], style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
          if (selectedNotice!['email'] == widget.currentUserEmail)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editNotice(selectedNotice!),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('수정'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D0A64),
                    side: const BorderSide(color: Color(0xFF0D0A64)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _deleteNotice(selectedNotice!),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('삭제'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),

        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildNoticeList(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Container(
              key: ValueKey(selectedNotice?['id'] ?? 'empty'), // key 중요
              child: _buildNoticeDetail(),
            ),
          ),
        ),

      ],
    );
  }

}