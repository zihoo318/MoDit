import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'friend_add_popup.dart';
import 'group_create_popup.dart';
import 'group_main_screen.dart';
import 'notice.dart';
import 'flask_test.dart'; //임시 테스트 코드

class HomeScreen extends StatefulWidget {
  final String currentUserEmail;
  final String currentUserName; // ✅ 추가

  const HomeScreen({
    required this.currentUserEmail,
    required this.currentUserName,
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> groupStudies = [];
  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    loadGroupStudies();
    loadNotes();
  }

  void loadGroupStudies() async {
    final snapshot = await db.child('groupStudies').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final List<Map<String, dynamic>> visibleGroups = [];
      final userKey = widget.currentUserEmail.replaceAll('.', '_');

      for (var entry in data.entries) {
        final value = Map<String, dynamic>.from(entry.value);
        if ((value['members'] as Map?)?.containsKey(userKey) ?? false) {
          visibleGroups.add({
            'id': entry.key,
            'name': value['name'] ?? '이름없음',
          });
        }
      }

      setState(() {
        groupStudies = visibleGroups;
      });
    }
  }

  void loadNotes() async {
    final snapshot = await db.child('notes').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        notes = data.entries.map((e) => {
          'id': e.key,
          'title': e.value['title'] ?? '노트',
        }).toList();
      });
    }
  }

  void _showFriendAddPopup() {
    showDialog(
      context: context,
      builder: (context) => FriendAddPopup(currentUserEmail: widget.currentUserEmail),
    );
  }

  _showGroupCreatePopup() {
    showDialog(
      context: context,
      builder: (context) => GroupCreatePopup(currentUserEmail: widget.currentUserEmail),
    ).then((_) => loadGroupStudies());
  }

  Widget _buildGroupStudyCard(Map<String, dynamic> group) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupMainScreen(
              groupId: group['id'],
              currentUserEmail: widget.currentUserEmail,
              currentUserName: widget.currentUserName, // ✅ 전달
            ),
          ),
        );
      },
      child: Container(
        width: 193,
        height: 177,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFB8BDF1).withOpacity(0.3),
          borderRadius: BorderRadius.circular(60),
        ),
        child: Center(child: Text(group['name'], style: const TextStyle(fontSize: 16))),
      ),
    );
  }

  Widget _buildNoteCard(String title) {
    return Container(
      width: 150,
      height: 177,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(60),
      ),
      child: Center(child: Text(title, style: const TextStyle(fontSize: 14))),
    );
  }

  Widget _buildAddCard(VoidCallback onTap, {double width = 193, Color? color}) {
    return Container(
      width: width,
      height: 177,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFB8BDF1).withOpacity(0.3),
        borderRadius: BorderRadius.circular(60),
      ),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Image.asset('assets/images/plus_icon.png', width: 40),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background_logo.png', fit: BoxFit.cover, alignment: Alignment.topLeft),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 100, left: 40, right: 40, bottom: 40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _showFriendAddPopup,
                        child: Row(
                          children: [
                            const Text('친구 추가', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 4),
                            Image.asset('assets/images/plus_icon2.png', width: 30),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ClipOval(
                        child: Image.asset('assets/images/user_icon2.png', width: 50),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                Container(
                  height: 220,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        const SizedBox(width: 20),
                        ...groupStudies.map((g) => _buildGroupStudyCard(g)).toList(),
                        _buildAddCard(_showGroupCreatePopup),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      ...notes.map((n) => _buildNoteCard(n['title'])).toList(),
                      _buildAddCard(() {}, width: 150, color: Colors.white),
                      const SizedBox(width: 20),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TestApiPage()),
                      );
                    },
                    child: const Text("테스트 API 페이지 이동"),
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
