import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'friend_add_popup.dart';
import 'group_create_popup.dart';
import 'group_main_screen.dart';
import 'note_screen.dart';
import 'package:intl/intl.dart';

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
  List<Map<String, dynamic>> userNotes = [];

  bool _isNoteLoading = false;

  @override
  void initState() {
    super.initState();
    loadGroupStudies();
    listenToUserNotes();  //노트 불러오기
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

  Future<void> loadUserNotes() async {
    if (_isNoteLoading) return;
    _isNoteLoading = true;

    final userKey = widget.currentUserEmail.replaceAll('.', '_');
    await Future.delayed(Duration(milliseconds: 300));

    final snapshot = await db.child('notes').child(userKey).get();
    if (snapshot.exists) {
      final notesMap = Map<String, dynamic>.from(snapshot.value as Map);
      final loadedNotes = notesMap.entries.map((entry) {
        final noteData = Map<String, dynamic>.from(entry.value);
        return {
          'noteId': entry.key,
          'title': noteData['title'] ?? '제목 없음',
          'imageUrl': noteData['imageUrl'] ?? '',
          'timestampMillis': noteData['timestampMillis'] ?? 0,
        };
      }).toList();

      loadedNotes.sort((a, b) => (b['timestampMillis'] ?? 0).compareTo(a['timestampMillis'] ?? 0));

      setState(() {  // 이 부분이 반드시 있어야 함
        userNotes = loadedNotes;
      });
    } else {
      setState(() {
        userNotes = []; // 노트가 없을 경우 비워줌
      });
    }
  }

  void listenToUserNotes() {
    final userKey = widget.currentUserEmail.replaceAll('.', '_');
    db.child('notes').child(userKey).onValue.listen((event) {
      if (!mounted || event.snapshot.value == null) {
        setState(() => userNotes = []);
        return;
      }

      final notesMap = Map<String, dynamic>.from(event.snapshot.value as Map);
      final loadedNotes = notesMap.entries.map((entry) {
        final noteData = Map<String, dynamic>.from(entry.value);
        return {
          'noteId': entry.key,
          'title': noteData['title'] ?? '제목 없음',
          'imageUrl': noteData['imageUrl'] ?? '',
          'timestampMillis': noteData['timestampMillis'] ?? 0,
        };
      }).toList();

      loadedNotes.sort((a, b) => (b['timestampMillis'] ?? 0).compareTo(a['timestampMillis'] ?? 0));

      setState(() => userNotes = loadedNotes);
    });
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

  Widget _buildNoteCardFromFirebase(String imageUrl, String title, int timestampMillis) {
    final formattedTime = DateFormat('yyyy.MM.dd HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(timestampMillis),
    );
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
              child: Image.network(
                '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}', // ✅ 캐시 무력화
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.broken_image)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  Text( // 제목
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text( // 날짜
                    DateFormat('yyyy.MM.dd HH:mm').format(
                      DateTime.fromMillisecondsSinceEpoch(timestampMillis),
                    ),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteNote(String title) async {
    final userKey = widget.currentUserEmail.replaceAll('.', '_');

    final snap = await db.child('notes').child(userKey)
        .orderByChild('title').equalTo(title)
        .limitToFirst(1)
        .get();

    if (snap.exists) {
      final existingSnap = snap.children.first;
      final noteId = existingSnap.key;

      // FirebaseDatabase에서 삭제
      await db.child('notes').child(userKey).child(noteId!).remove();

      // FirebaseStorage에서 해당 노트의 이미지 삭제
      try {
        final safeTitle = Uri.encodeComponent(title);
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('notes/$userKey');

// 이 경로 하위 전체 파일을 가져와 title이 포함된 것 삭제
        final ListResult result = await storageRef.listAll();
        for (final item in result.items) {
          final nameDecoded = Uri.decodeComponent(item.name);
          if (nameDecoded.contains(title)) {
            await item.delete();
            print('🗑️ 삭제된 파일: ${item.name}');
          }
        }


        print('✅ Firebase Storage 이미지 삭제 완료');
      } catch (e) {
        print('⚠️ Firebase Storage 이미지 삭제 실패: $e');
      }
    }
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
                  offset: const Offset(-10, 0),
                  child: Image.asset('assets/images/logo.png', height: 45),
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
                    MaterialPageRoute(
                      builder: (_) => NoteScreen(currentUserEmail: widget.currentUserEmail),
                    ),
                  ).then((value) {
                    if (value == true) {
                      loadUserNotes();
                    }
                  });
                  return; // ✅ 명시적으로 void 반환
                }),



                ...userNotes.map((note) =>
                    GestureDetector(
                      onTap: () async {
                        final userKey = widget.currentUserEmail.replaceAll('.', '_');
                        final snap = await db.child('notes').child(userKey)
                            .orderByChild('title').equalTo(note['title'])
                            .limitToFirst(1).get();
                        final existingSnap = snap.children.first;
                        final existingNote = existingSnap.value as Map;

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NoteScreen(
                              currentUserEmail: widget.currentUserEmail,
                              existingNoteData: {
                                ...existingNote,
                                'noteId': existingSnap.key,
                                'title': note['title'],
                              },
                            ),
                          ),
                        );

                        if (result == true) loadUserNotes();
                      },

                      onLongPress: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('노트 삭제'),
                            content: Text("‘${note['title']}’ 노트를 삭제하시겠습니까?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('취소'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('삭제', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _deleteNote(note['title']);
                          await loadUserNotes();  // 데이터 다시 불러오기
                          setState(() {});        // ✅ 강제로 UI 다시 그리기

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('노트가 삭제되었습니다')),
                          );
                        }

                      },


                      child: _buildNoteCardFromFirebase(
                        note['imageUrl'],
                        note['title'],
                        note['timestampMillis'],),
                    )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}