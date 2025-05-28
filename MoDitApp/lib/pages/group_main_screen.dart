import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'chatting.dart';
import 'first_page.dart';
import 'notice.dart';
import 'meeting_calendar.dart';
import 'meeting_record.dart';
import 'study_time.dart';
import 'taskManageScreen.dart';
import 'menu.dart';
import 'home.dart';
import 'login.dart';

class GroupMainScreen extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  final String currentUserName;
  final int initialTabIndex;

  const GroupMainScreen({
    required this.groupId,
    required this.currentUserEmail,
    required this.currentUserName,
    this.initialTabIndex = 0,
    super.key,
  });

  // 별도 목적(녹음에서 캘린더로 돌아가기)의 네임드 생성자 추가
  GroupMainScreen.forCalendar({
    required String groupId,
    required String currentUserEmail,
    required String currentUserName,
  }) : this(
    groupId: groupId,
    currentUserEmail: currentUserEmail,
    currentUserName: currentUserName,
    initialTabIndex: 2, // 미팅 일정 탭으로 시작
  );

  @override
  State<GroupMainScreen> createState() => _GroupMainScreenState();
}

class _GroupMainScreenState extends State<GroupMainScreen> {
  final db = FirebaseDatabase.instance.ref();
  int _selectedIndex = 0;
  int _homeworkTabIndex = 0;
  String groupName = '';
  List<String> memberNames = [];

  DateTime? _recordDate;
  String? _meetingId;
  bool isRecordingView = false;

  late Offset _targetCenter;

  bool _isMyPageOpen = false;
  bool _isEditingName = false;
  late TextEditingController _nameController;

  final List<String> menuTitles = ['메뉴', '공부 시간', '미팅 일정 & 녹음', '과제 관리', '공지사항', '채팅'];
  final List<String> menuIcons = ['menu_icon', 'study_icon', 'calendar_icon', 'homework_icon', 'notice_icon', 'chatting_icon'];
  final List<String> menuIconsSelected = ['menu_icon2', 'study_icon2', 'calendar_icon2', 'homework_icon2', 'notice_icon2', 'chatting_icon2'];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _nameController = TextEditingController(text: widget.currentUserName);
    _loadGroupInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = context.findRenderObject() as RenderBox;
      final offset = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      setState(() {
        _targetCenter = Offset(
          offset.dx + size.width * 0.6,
          offset.dy + size.height * 0.55,
        );
      });
    });
    print(" currentUserName: "+widget.currentUserName);
  }

  void _loadGroupInfo() async {
    final groupSnap = await db.child('groupStudies').child(widget.groupId).get();
    if (groupSnap.exists) {
      final data = Map<String, dynamic>.from(groupSnap.value as Map);
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
        groupName = data['name'] ?? '그룹';
        memberNames = names;
      });
    }
  }

  Future<void> _updateName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    final userKey = widget.currentUserEmail.replaceAll('.', '_');
    await db.child('user').child(userKey).update({'name': newName});
    setState(() => _isEditingName = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: const Text(
          "이름이 수정되었습니다.",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFEAEAFF),
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
    );
  }

  void _showAddFriendDialog() async {
    final userKey = widget.currentUserEmail.replaceAll('.', '_');

    // 1) 내 친구 목록 가져오기
    final friendsSnap = await db.child('user').child(userKey).child('friends').get();
    if (!friendsSnap.exists) {
      _showSnackBar('친구가 없습니다.');
      return;
    }
    final friendsData = Map<String, dynamic>.from(friendsSnap.value as Map);

    // 2) 친구 이메일 키 리스트
    final List<String> friendKeys = friendsData.keys.toList();

    // 3) 친구 이름 리스트 가져오기 (비동기)
    final List<Map<String, String>> friendList = [];
    for (var fKey in friendKeys) {
      if (memberNames.contains(await _getUserNameByKey(fKey))) continue; // 이미 멤버면 제외

      final userSnap = await db.child('user').child(fKey).get();
      if (userSnap.exists) {
        final userData = userSnap.value as Map;
        friendList.add({
          'key': fKey,
          'name': userData['name'] ?? fKey,
        });
      }
    }

    // 4) 팝업 띄우기
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 450,
                  maxHeight: 380,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👥 친구 추가',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D0A64),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1, color: Color(0xFF0D0A64)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: friendList.isEmpty
                          ? const Center(
                        child: Text(
                          '추가할 친구가 없습니다.',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      )
                          : ListView.builder(
                        itemCount: friendList.length,
                        itemBuilder: (context, index) {
                          final friend = friendList[index];
                          return ListTile(
                            title: Text(friend['name'] ?? ''),
                            onTap: () {
                              final selectedKey = friend['key'] ?? '';
                              final selectedName = friend['name'] ?? '';
                              Navigator.of(context).pop(); // 팝업 닫기 먼저
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _addMember(selectedKey, selectedName);
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                          foregroundColor: const Color(0xFF0D0A64),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('취소'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  Future<void> _addMember(String friendKey, String friendName) async {
    try {
      // 1) DB 내 그룹 멤버에 friendKey 추가 (값은 true 또는 friendName 등)
      await db.child('groupStudies').child(widget.groupId).child('members').update({
        friendKey: true,
      });

      // 2) 로컬 멤버 목록에도 추가
      setState(() {
        memberNames.add(friendName);
      });

      _showSnackBar('$friendName 님이 멤버로 추가되었습니다.');
    } catch (e) {
      _showSnackBar('멤버 추가 중 오류가 발생했습니다.');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFEAEAFF),
      ),
    );
  }


// 이메일 키로 이름 가져오는 헬퍼 함수
  Future<String> _getUserNameByKey(String emailKey) async {
    final userSnap = await db.child('user').child(emailKey).get();
    if (userSnap.exists) {
      final userData = userSnap.value as Map;
      return userData['name'] ?? emailKey;
    }
    return emailKey;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background.png', fit: BoxFit.cover, alignment: Alignment.topLeft),
          ),
          Row(
            children: [
              Container(
                width: 250,
                margin: const EdgeInsets.only(left: 20, top: 40, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 25),
                    Padding(
                      padding: const EdgeInsets.only(right: 110),
                      child: Image.asset('assets/images/logo.png', height: 40),
                    ),
                    const SizedBox(height: 50),
                    ...List.generate(menuTitles.length, (index) {
                      final bool isCalendarSection = _selectedIndex == 2 || (_selectedIndex == 6 && isRecordingView);
                      final selected = index == 2 ? isCalendarSection : _selectedIndex == index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                              isRecordingView = false;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFB8BDF1).withOpacity(0.3) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: Image.asset(
                                      'assets/images/${selected ? menuIconsSelected[index] : menuIcons[index]}.png',
                                      key: ValueKey(selected),
                                      width: 22,
                                    ),
                                  ),
                                ),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: selected ? const Color(0xFF6495ED) : Colors.black54,
                                  ),
                                  child: Text(menuTitles[index]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(groupName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              ...memberNames.map((name) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 38,
                                height: 38,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD9D9D9),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(name, style: const TextStyle(fontSize: 15, color: Colors.black)),
                              )),

                              const SizedBox(width: 8),
                              // 친구 추가 버튼
                              GestureDetector(
                                onTap: _showAddFriendDialog,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white, size: 19),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() => _isMyPageOpen = !_isMyPageOpen);
                                },
                                child: const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.white,
                                  backgroundImage: AssetImage('assets/images/user_icon2.png'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(child: _buildSelectedContent()),
                  ],
                ),
              )
            ],
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '내 프로필',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D0A64),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage(
                          'assets/images/user_icon2.png',
                        ),
                      ),
                      const SizedBox(height: 10),
                      _isEditingName
                          ? TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17),
                        decoration: InputDecoration(
                          hintText: '이름 입력',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                        ),
                      )
                          : Text(
                        _nameController.text,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _buildBackButton(),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      bottom: 35,
      left: 30,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 500),
              pageBuilder: (_, animation, secondaryAnimation) => HomeScreen(
                currentUserEmail: widget.currentUserEmail,
                currentUserName: widget.currentUserName,
              ),
              transitionsBuilder: (_, animation, __, child) {
                final scaleTween = Tween(begin: 0.95, end: 1.0)
                    .chain(CurveTween(curve: Curves.easeOutCubic));
                final fade = Tween(begin: 0.0, end: 1.0).animate(animation);

                return FadeTransition(
                  opacity: fade,
                  child: ScaleTransition(
                    scale: animation.drive(scaleTween),
                    child: child,
                  ),
                );
              },
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.purpleAccent.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, color: Colors.white),
              SizedBox(width: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // 예: Scale + Fade 효과
        return ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _selectedIndex == 0 && _targetCenter != null
          ? MenuScreen(
        key: const ValueKey('menu'),
        groupId: widget.groupId,
        currentUserEmail: widget.currentUserEmail,
        currentUserName: widget.currentUserName,
        onNavigateToTab: (int index) {
          setState(() => _selectedIndex = index);
        },
        targetCenter: _targetCenter!,
      )
          : _animatedTabWrapper(_selectedIndex),
    );
  }

  Widget _animatedTabWrapper(int index) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(index),
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        final opacity = (scale - 0.95) / 0.05 * 0.4 + 0.6; // 0.6 → 1.0 매핑 (=scale: 0.95 → 1.0일 때 opacity: 0.6 → 1.0으로 선형 변화)

        return Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: scale,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(40),
        ),
        child: _getContentForOtherTabs(),
      ),
    );
  }



  Widget _getContentForOtherTabs() {
    switch (_selectedIndex) {
      case 1:
        return StudyTimeWidget(
          groupId: widget.groupId,
          currentUserEmail: widget.currentUserEmail,
          currentUserName: widget.currentUserName,
        );
      case 2:
        return MeetingCalendarWidget(
          groupId: widget.groupId,
          currentUserEmail: widget.currentUserEmail,
          onRecordDateSelected: (date, meetingId) {
            setState(() {
              _recordDate = date;
              _meetingId = meetingId;
              _selectedIndex = 6;
              isRecordingView = true;
            });
          },
        );
      case 3:
        return TaskManageScreen(
          groupId: widget.groupId,
          currentUserEmail: widget.currentUserEmail,
          tabIndex: _homeworkTabIndex,
          onTabChanged: (index) {
            setState(() => _homeworkTabIndex = index);
          },
        );
      case 4:
        return NoticePage(
          groupId: widget.groupId,
          currentUserEmail: widget.currentUserEmail,
          currentUserName: widget.currentUserName,
        );
      case 5:
        return ChattingPage(
          groupId: widget.groupId,
          currentUserEmail: widget.currentUserEmail,
        );
      case 6:
        return (_recordDate == null || _meetingId == null)
            ? const Center(child: Text('날짜가 선택되지 않았습니다'))
            : MeetingRecordWidget(
          selectedDate: _recordDate!,
          groupId: widget.groupId,
          meetingId: _meetingId!,
          currentUserEmail: widget.currentUserEmail,
          currentUserName: widget.currentUserName,
          onBackToCalendar: () {
            setState(() {
              _selectedIndex = 2; // 캘린더 탭 인덱스로 돌아가기
              isRecordingView = false;
            });
          },
        );
      default:
        return const SizedBox();
    }
  }
}
