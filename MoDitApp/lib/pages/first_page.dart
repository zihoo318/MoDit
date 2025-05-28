import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'friend_add_popup.dart';
import 'group_create_popup.dart';
import 'group_main_screen.dart';
import 'login.dart';
import 'note_screen.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserEmail;
  final String currentUserName;
  const HomeScreen({required this.currentUserEmail, super.key, required String this.currentUserName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final db = FirebaseDatabase.instance.ref();
  List<Map<String, dynamic>> groupStudies = [];
  List<Map<String, dynamic>> userNotes = [];

  bool _isNoteLoading = false;

  // 선택된 그룹 id 저장(애니메이션)
  String? _animatingGroupId;

  late AnimationController _groupAnimController;
  late Animation<double> _groupScaleAnimation;
  late Animation<double> _groupFadeAnimation;

  // 마이페이지 변수
  bool _isMyPageOpen = false;
  bool _isEditingName = false;
  late TextEditingController _nameController;

  bool _isNotificationOpen = false; // 알림창 열림 여부
  List<Map<String, dynamic>> _notifications = []; // 알림 데이터 리스트

  // 알림 탭 애니메이션 변수
  late AnimationController _notificationAnimController;
  late Animation<double> _notificationScaleAnimation;
  late Animation<double> _notificationHeightAnimation;


  @override
  void initState() {
    super.initState();
    _groupAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _groupScaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _groupAnimController, curve: Curves.easeOut),
    );
    _groupFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _groupAnimController, curve: Curves.easeOut),
    );

    loadGroupStudies();
    listenToGroupStudies();
    loadUserNotes();
    listenToUserNotes();
    _nameController = TextEditingController();
    _loadUserNameFromDB();

    final userKey = widget.currentUserEmail.replaceAll('.', '_');

    db.child('user').child(userKey).child('push').onValue.listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;
      if (data == null) {
        setState(() {
          _notifications = [];
        });
        return;
      }

      final Map<dynamic, dynamic> rawMap = data as Map<dynamic, dynamic>;

      final List<Map<String, dynamic>> notifList = rawMap.entries.map((entry) {
        final val = Map<String, dynamic>.from(entry.value);
        return {
          'id': entry.key,
          'message': val['message'] ?? '',
          'timestamp': val['timestamp'] ?? 0,
          'category': val['category'] ?? '',
          'groupId': val['groupId'] ?? '',
          'isRead': val['isRead'] ?? false,  // 기본 false
        };
      }).toList();


      // 최신순 정렬 (timestamp 내림차순)
      notifList.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

      setState(() {
        _notifications = notifList;
      });
    });

    _notificationAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _notificationScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _notificationAnimController,
        curve: Curves.elasticOut,
      ),
    );
    _notificationHeightAnimation = Tween<double>(begin: 0, end: 480).animate(
      CurvedAnimation(
        parent: _notificationAnimController,
        curve: Curves.easeOutBack,
      ),
    );

    _notificationAnimController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _groupAnimController.dispose();
    _notificationAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadUserNameFromDB() async {
    final userKey = widget.currentUserEmail.replaceAll('.', '_');
    final snapshot = await db.child('user').child(userKey).get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final nameFromDB = data['name'] ?? widget.currentUserEmail.split('@')[0];
      setState(() {
        _nameController.text = nameFromDB;
      });
    }
  }


  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
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
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "친구 추가",
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: FriendAddPopup(currentUserEmail: widget.currentUserEmail),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }


  void _showGroupCreatePopup() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "그룹 생성",
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: GroupCreatePopup(currentUserEmail: widget.currentUserEmail),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
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

      loadedNotes.sort((a, b) =>
          (b['timestampMillis'] ?? 0).compareTo(a['timestampMillis'] ?? 0));

      setState(() { // 이 부분이 반드시 있어야 함
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
    db
        .child('notes')
        .child(userKey)
        .onValue
        .listen((event) {
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

      loadedNotes.sort((a, b) =>
          (b['timestampMillis'] ?? 0).compareTo(a['timestampMillis'] ?? 0));

      setState(() => userNotes = loadedNotes);
    });
  }

  //실시간 그룹 데이터 감지
  void listenToGroupStudies() {
    final userKey = widget.currentUserEmail.replaceAll('.', '_');
    db.child('groupStudies').onValue.listen((event) {
      if (event.snapshot.value == null) {
        setState(() {
          groupStudies = [];
        });
        return;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final List<Map<String, dynamic>> visibleGroups = [];

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
    });
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
            boxShadow: [ // 그림자 추가
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
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

  Widget _buildNoteCardFromFirebase(String imageUrl, String title,
      int timestampMillis) {
    final formattedTime = DateFormat('yyyy.MM.dd HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(timestampMillis),
    );
    return AspectRatio(
        aspectRatio: 14 / 9,
        child: Hero(
          tag: 'note_${title}',
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Expanded(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    children: [
                      Text(
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
                      Text(
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
        )
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
      final safeEmail = widget.currentUserEmail.replaceAll('.', '_');
      final noteData = Map<String, dynamic>.from(existingSnap.value as Map);

      // 1. FirebaseDatabase에서 삭제
      await db.child('notes').child(userKey).child(noteId!).remove();

      // 2. FirebaseStorage에서 해당 노트 폴더 내 파일 전체 삭제
      try {
        final folderRef = FirebaseStorage.instance
            .ref()
            .child('notes/$safeEmail/$title');

        final ListResult result = await folderRef.listAll();
        if (result.items.isEmpty) {
          print('⚠️ 삭제할 파일이 없습니다. 경로 확인 필요: ${folderRef.fullPath}');
        }
        for (final item in result.items) {
          print('🔍 삭제 시도 중: ${item.fullPath}');
          await item.delete();
          print('🗑️ 삭제된 파일: ${item.fullPath}');
        }

        print('✅ Firebase Storage 노트 폴더 내 이미지 전체 삭제 완료');
      } catch (e) {
        print('⚠️ Firebase Storage 이미지 삭제 실패: $e');
      }
    }
  }

  //이름 수정 함수
  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    final userKey = widget.currentUserEmail.replaceAll('.', '_');
    await FirebaseDatabase.instance.ref().child('user').child(userKey).update({'name': newName});
    setState(() => _isEditingName = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이름이 수정되었습니다')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          if (_isMyPageOpen) setState(() => _isMyPageOpen = false);
        },
        child: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                    'assets/images/background.png', fit: BoxFit.cover),
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
                          const SizedBox(width: 12),

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isNotificationOpen = !_isNotificationOpen;
                              });

                              if (_isNotificationOpen) {
                                _notificationAnimController.forward(from: 0.0);
                              } else {
                                _notificationAnimController.reverse();
                              }
                            },
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Image.asset(
                                  'assets/images/bell.png',
                                  width: 32,
                                  height: 32,
                                ),
                                if (_notifications.where((e) => e['isRead'] == false).isNotEmpty)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                      child: Text(
                                        '${_notifications.where((e) => e['isRead'] == false).length}',
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12), // 프로필과 알림 아이콘 간 간격

                          // 프로필 CircleAvatar 기존 코드
                          GestureDetector(
                            onTap: () {
                              setState(() => _isMyPageOpen = !_isMyPageOpen);
                            },
                            child: const CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              backgroundImage: AssetImage('assets/images/user_icon2.png'),
                            ),
                          ),
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
                    color: Colors.white.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,     // 그림자 색상
                        blurRadius: 10,            // 흐림 정도
                        offset: Offset(0, 4),      // 그림자 위치 (x, y)
                      ),
                    ],
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...groupStudies.map((g) {
                            final isSelected = _animatingGroupId == g['id'];

                            if (isSelected) {
                              _groupAnimController.forward(from: 0.0);
                            }

                            return GestureDetector(
                              onTap: () {
                                setState(() => _animatingGroupId = g['id']);
                                _groupAnimController.forward(from: 0.0);
                                Future.delayed(const Duration(milliseconds: 200), () {
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(milliseconds: 500),
                                      pageBuilder: (_, animation, __) => GroupMainScreen(
                                        groupId: g['id'],
                                        currentUserEmail: widget.currentUserEmail,
                                        currentUserName: widget.currentUserName,
                                      ),
                                      transitionsBuilder: (_, animation, __, child) {
                                        final tween = Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOut));
                                        final fade = Tween(begin: 0.0, end: 1.0).animate(animation);
                                        return FadeTransition(
                                          opacity: fade,
                                          child: ScaleTransition(scale: animation.drive(tween), child: child),
                                        );
                                      },
                                    ),
                                  ).then((_) => setState(() => _animatingGroupId = null));
                                });
                              },
                              onLongPress: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('그룹 삭제'),
                                    content: Text("‘${g['name']}’ 그룹을 삭제하시겠습니까?"),
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
                                  final groupId = g['id'];
                                  await db.child('groupStudies').child(groupId).remove();
                                  await db.child('tasks').child(groupId).remove();

                                  setState(() {
                                    groupStudies.removeWhere((grp) => grp['id'] == groupId);
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "그룹이 삭제되었습니다",
                                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                                      ),
                                      backgroundColor: Color(0xFFEAEAFF),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              child: AnimatedBuilder(
                                animation: _groupAnimController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: isSelected
                                        ? _groupScaleAnimation.value
                                        : 1.0,
                                    child: Opacity(
                                      opacity: isSelected ? _groupFadeAnimation
                                          .value : 1.0,
                                      child: Hero(
                                        tag: g['id'],
                                        child: child!,
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
                                    child: Text(
                                      g['name'],
                                      style: const TextStyle(fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5), // ✅ 배경 색상 및 투명도
                    borderRadius: BorderRadius.circular(30), // ✅ 라운드 처리
                  ),
                  padding: const EdgeInsets.all(20),
                  child: GridView.count(
                    crossAxisCount: 4,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 14 / 9,
                    children: [
                      _buildNoteAddCard(() {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 500),
                            pageBuilder: (_, animation, __) => NoteScreen(currentUserEmail: widget.currentUserEmail),
                            transitionsBuilder: (_, animation, __, child) {
                              final scaleTween = Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic));
                              final fadeTween = Tween(begin: 0.0, end: 1.0).animate(animation);
                              return FadeTransition(
                                opacity: fadeTween,
                                child: ScaleTransition(
                                  scale: animation.drive(scaleTween),
                                  child: child,
                                ),
                              );
                            },
                          ),
                        ).then((value) {
                          if (value == true) loadUserNotes();
                        });
                      }),

                      ...userNotes.map((note) => GestureDetector(
                        onTap: () async {
                          final userKey = widget.currentUserEmail.replaceAll('.', '_');
                          final snap = await db
                              .child('notes')
                              .child(userKey)
                              .orderByChild('title')
                              .equalTo(note['title'])
                              .limitToFirst(1)
                              .get();
                          final existingSnap = snap.children.first;
                          final existingNote = existingSnap.value as Map;

                          final result = await Navigator.of(context).push(
                            PageRouteBuilder(
                              transitionDuration: const Duration(milliseconds: 500),
                              pageBuilder: (_, animation, __) => NoteScreen(
                                currentUserEmail: widget.currentUserEmail,
                                existingNoteData: {
                                  ...existingNote,
                                  'noteId': existingSnap.key,
                                  'title': note['title'],
                                },
                              ),
                              transitionsBuilder: (_, animation, __, child) {
                                final scaleTween = Tween(begin: 0.95, end: 1.0)
                                    .chain(CurveTween(curve: Curves.easeOutCubic));
                                final fadeTween = Tween(begin: 0.0, end: 1.0).animate(animation);

                                return FadeTransition(
                                  opacity: fadeTween,
                                  child: ScaleTransition(
                                    scale: animation.drive(scaleTween),
                                    child: child,
                                  ),
                                );
                              },
                            ),
                          );

                          if (result == true) {
                            await loadUserNotes();
                            setState(() {});
                          }
                        },
                        onLongPress: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('노트 삭제'),
                              content: Text("‘${note['title']}’ 노트를 삭제하시겠습니까?"),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                                TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('삭제', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _deleteNote(note['title']);
                            await loadUserNotes();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "노트가 삭제되었습니다",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: Color(0xFFEAEAFF),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }

                        },
                        child: _buildNoteCardFromFirebase(
                          note['imageUrl'],
                          note['title'],
                          note['timestampMillis'],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              if (_isMyPageOpen)
                Positioned(
                  top: 100,
                  right: 40,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: const ValueKey("mypage_home"),
                      width: 280,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('내 프로필',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D0A64))),
                          const SizedBox(height: 18),
                          const CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            backgroundImage: AssetImage('assets/images/user_icon2.png'),
                          ),
                          const SizedBox(height: 10),
                          _isEditingName
                              ? TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 17),
                            decoration: InputDecoration(
                              hintText: '이름 입력',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            ),
                          )
                              : Text(_nameController.text,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (_isEditingName) {
                                  _updateName();
                                } else {
                                  setState(() => _isEditingName = true);
                                }
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: Text(_isEditingName ? '저장' : '이름 수정'),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xFFF0F0F0),
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _logout,
                              icon: const Icon(Icons.logout, size: 18),
                              label: const Text('로그아웃'),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: const Color(0xFFFBE9E9),
                                foregroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_isNotificationOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isNotificationOpen = false;
                      });
                    },
                    child: Container(
                      color: Colors.transparent, // 투명 배경
                    ),
                  ),
                ),

              if (_isNotificationOpen)
                Positioned(
                  top: 90,
                  right: 40,
                  width: 450,
                  height: _notificationHeightAnimation.value,
                  child: AnimatedBuilder(
                    animation: _notificationScaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _notificationScaleAnimation.value,
                        child: child,
                      );
                    },
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _notifications.isEmpty
                            ? const Center(child: Text('알림이 없습니다.'))
                            : ListView.separated(
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final notif = _notifications[index];
                            return ListTile(
                              leading: Stack(
                                children: [
                                  const Icon(Icons.notifications_active),
                                  if (notif['isRead'] == false)  // 읽지 않은 경우에만 빨간 점
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              title: Text(notif['message']),
                              subtitle: Text(DateFormat('yyyy.MM.dd HH:mm').format(
                                DateTime.fromMillisecondsSinceEpoch(notif['timestamp']),
                              )),
                              onTap: () async {
                                print('알림 클릭: ${notif['message']}');

                                // 읽음 처리 로직 (Firebase에 isRead=true 업데이트)
                                final userKey = widget.currentUserEmail.replaceAll('.', '_');
                                final notifId = notif['id'];
                                await db.child('user').child(userKey).child('push').child(notifId).update({'isRead': true});

                                setState(() {
                                  _isNotificationOpen = false;
                                  // 로컬 알림 리스트에서도 해당 알림을 읽음 처리
                                  final index = _notifications.indexWhere((element) => element['id'] == notifId);
                                  if (index != -1) {
                                    _notifications[index]['isRead'] = true;
                                  }
                                });

                                // 이후 화면 이동 등 기존 코드 유지
                                int tabIndex = 0;
                                switch (notif['category']) {
                                  case 'task':
                                    tabIndex = 3;
                                    break;
                                  case 'meeting':
                                    tabIndex = 2;
                                    break;
                                  case 'notice':
                                    tabIndex = 4;
                                    break;
                                  default:
                                    tabIndex = 0;
                                }

                                Navigator.of(context).push(
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(milliseconds: 500),
                                    pageBuilder: (context, animation, secondaryAnimation) => GroupMainScreen(
                                      groupId: notif['groupId'],
                                      currentUserEmail: widget.currentUserEmail,
                                      currentUserName: _nameController.text,
                                      initialTabIndex: tabIndex,
                                    ),
                                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                      final tween = Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOut));
                                      final fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(animation);

                                      return FadeTransition(
                                        opacity: fadeAnimation,
                                        child: ScaleTransition(
                                          scale: animation.drive(tween),
                                          child: child,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },

                            );
                          },
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
        )
    );
  }
}