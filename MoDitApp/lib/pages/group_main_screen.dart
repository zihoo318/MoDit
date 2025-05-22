// -----------------------------
// group_main_screen.dart
// -----------------------------
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
import 'mypage.dart'; // 맨 위에 추가
import 'package:moditapp/pages/mypage.dart';


import 'home.dart';

class GroupMainScreen extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  final String currentUserName;

  const GroupMainScreen({
    required this.groupId,
    required this.currentUserEmail,
    required this.currentUserName,
    super.key,
  });

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

  final List<String> menuTitles = [
    '메뉴', '공부 시간', '미팅 일정 & 녹음', '과제 관리', '공지사항', '채팅'
  ];

  final List<String> menuIcons = [
    'menu_icon', 'study_icon', 'calendar_icon', 'homework_icon', 'notice_icon', 'chatting_icon'
  ];

  final List<String> menuIconsSelected = [
    'menu_icon2', 'study_icon2', 'calendar_icon2', 'homework_icon2', 'notice_icon2', 'chatting_icon2'
  ];

  @override
  void initState() {
    super.initState();
    _loadGroupInfo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderBox = context.findRenderObject() as RenderBox;
      final offset = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      setState(() {
        _targetCenter = Offset(
            offset.dx + size.width * 0.6, // 메뉴 제외한 오른쪽 영역 중앙
            offset.dy + size.height * 0.55 // 상단바 제외한 중앙
        );
      });
    });
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
                            curve: Curves.easeInOut,
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
                                      key: ValueKey(selected), // 상태 변화 감지용 키
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
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD9D9D9),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(name, style: const TextStyle(fontSize: 15, color: Colors.black)),
                              )),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => MyPagePopup(
                                      userEmail: widget.currentUserEmail,
                                      userName: widget.currentUserName,
                                    )
                                  );
                                },
                                child: const CircleAvatar(
                                  radius: 16,
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
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(
                currentUserEmail: widget.currentUserEmail,
                currentUserName: widget.currentUserName,
              ),
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
        );
      default:
        return const SizedBox();
    }
  }
}
