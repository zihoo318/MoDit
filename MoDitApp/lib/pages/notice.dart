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
  List<String> memberNames = [];
  List<Map<String, String>> notices = [];
  final db = FirebaseDatabase.instance.ref();
  int currentPage = 1;
  final int itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    loadGroupInfo();
    loadNotices();
  }

  void loadGroupInfo() async {
    final groupSnap = await db.child('groupStudies').child(widget.groupId).get();
    if (groupSnap.exists) {
      final data = groupSnap.value as Map;
      setState(() {
        groupName = data['name'] ?? '';
      });

      final members = Map<String, dynamic>.from(data['members'] ?? {});
      final List<String> names = [];
      for (var emailKey in members.keys) {
        final userSnap = await db.child('user').child(emailKey).get();
        if (userSnap.exists) {
          final userData = userSnap.value as Map;
          names.add(userData['name'] ?? emailKey);
        }
      }
      setState(() {
        memberNames = names;
      });
    }
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
          Positioned.fill(
            child: Image.asset('assets/images/background_logo.png', fit: BoxFit.cover, alignment: Alignment.topLeft),
          ),
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단바
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(groupName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        for (var name in memberNames)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD9D9D9),
                              shape: BoxShape.circle,
                            ),
                            child: Text(name, style: const TextStyle(fontSize: 12)),
                          ),
                        const SizedBox(width: 12),
                        const CircleAvatar(
                          radius: 16,
                          backgroundImage: AssetImage('assets/images/user_icon2.png'),
                        )
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 30),

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
                const SizedBox(height: 20),

                // 공지사항 리스트
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFECEEFF),
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