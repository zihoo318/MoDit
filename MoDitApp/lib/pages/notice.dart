import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'notice_write.dart';
import 'notice_detail.dart';

class NoticePage extends StatefulWidget {
  const NoticePage({super.key, required groupId, required String currentUserEmail});

  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  final _database = FirebaseDatabase.instance.ref('notices');
  List<Map<String, dynamic>> _notices = [];

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  void _loadNotices() {
    _database.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;

      final Map<String, dynamic> noticeMap = Map<String, dynamic>.from(data as Map);
      final newList = noticeMap.entries.map((entry) {
        final val = Map<String, dynamic>.from(entry.value);
        return {
          'key': entry.key,
          'title': val['title'] ?? '',
          'content': val['content'] ?? '',
          'timestamp': val['timestamp'] ?? '',
        };
      }).toList();

      newList.sort((a, b) => b['timestamp'].compareTo(a['timestamp'])); // 시간순 정렬

      setState(() {
        _notices = newList;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/background1.png', fit: BoxFit.cover)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_back, size: 24),
                          SizedBox(width: 8),
                          Text('공지사항', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Row(
                        children: [
                          Image.asset('assets/images/notice_icon.png', width: 24),
                          const SizedBox(width: 12),
                          const Text('MoDit', style: TextStyle(color: Color(0xFF0D0A64), fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Image.asset('assets/images/user_icon.png', width: 32),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 공지사항 카드
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                  ),
                  child: Column(
                    children: [
                      ..._notices.map((notice) => _buildNoticeItem(notice)).toList(),
                      const SizedBox(height: 12),
                      const Text('<1|2|3|4|5>', style: TextStyle(fontSize: 16, color: Colors.black54)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NoticeWritePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade200),
                  child: const Text("공지사항 작성"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(Map<String, dynamic> notice) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NoticeDetailPage(
              title: notice['title'],
              content: notice['content'],
            ),
          ),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(notice['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(thickness: 1),
        ],
      ),
    );
  }
}
