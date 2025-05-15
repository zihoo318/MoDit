import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'friend_add_popup.dart';
import 'group_create_popup.dart';
import 'group_main_screen.dart';
import 'note_screen.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserEmail;
  final String currentUserName;
  const HomeScreen({required this.currentUserEmail, super.key, required String this.currentUserName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> groupStudies = [];

  @override
  void initState() {
    super.initState();
    loadGroupStudies();
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

  void _showFriendAddPopup() {
    showDialog(
      context: context,
      builder: (context) => FriendAddPopup(currentUserEmail: widget.currentUserEmail),
    );
  }

  void _showGroupCreatePopup() {
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
              currentUserName: widget.currentUserName,
            ),
          ),
        );
      },
      child: Container(
        width: 120,
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE1E6FB),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(group['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  // 하드코딩 노트카드
  Widget _buildNoteCardWithImage(String imagePath, String title) {
    return AspectRatio(
      aspectRatio: 14 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(title, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteAddCard(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 14 / 9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Icon(Icons.add, size: 30, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupStudyAddCard(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2F6),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.add, size: 20, color: Colors.grey),
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
            child: Image.asset('assets/images/background.png', fit: BoxFit.cover),
          ),

          // 상단바
          Positioned(
            top: 40,
            left: 30,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Transform.translate(
                  offset: const Offset(-20, 0),
                  child: Image.asset('assets/images/logo.png', height: 40),
                ),
                GestureDetector(
                  onTap: _showFriendAddPopup,
                  child: Row(
                    children: [
                      const Text('친구 추가', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Image.asset('assets/images/plus_icon2.png', width: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 그룹 스터디 (가로 스크롤)
          Positioned(
            top: 100,
            left: 30,
            right: 30,
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...groupStudies.map((g) => _buildGroupStudyCard(g)).toList(),
                      _buildGroupStudyAddCard(_showGroupCreatePopup),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 노트카드 (하드코딩 + 추가 버튼)
          Positioned.fill(
            top: 200,
            left: 30,
            right: 30,
            bottom: 30,
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              padding: const EdgeInsets.all(20),
              childAspectRatio: 14 / 9,
              children: [
                _buildNoteAddCard(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NoteScreen()),
                  );
                }),
                _buildNoteCardWithImage('assets/images/test_note1.jpg', '명사 정리'),
                _buildNoteCardWithImage('assets/images/test_note2.jpg', '형용사/명사'),
                _buildNoteCardWithImage('assets/images/test_note3.jpg', '부사/품사 구별'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
