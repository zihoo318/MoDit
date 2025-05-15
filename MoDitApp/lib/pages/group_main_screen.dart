import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'chatting.dart';
import 'notice.dart';
import 'meeting_calendar.dart';
import 'meeting_record.dart';
import 'study_time.dart';
import 'taskManageScreen.dart';
import 'menu.dart';

class GroupMainScreen extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  const GroupMainScreen({required this.groupId, required this.currentUserEmail, super.key});

  @override
  State<GroupMainScreen> createState() => _GroupMainScreenState();
}

class _GroupMainScreenState extends State<GroupMainScreen> {
  final db = FirebaseDatabase.instance.ref();
  int _selectedIndex = 0; // 전체 메뉴 인덱스
  String groupName = '';
  List<String> memberNames = [];

  DateTime? _recordDate;
  bool isRecordingView = false;

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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topLeft,
            ),
          ),
          Row(
            children: [
              // 왼쪽 메뉴바
              Container(
                width: 250,
                margin: const EdgeInsets.only(left: 20, top: 40, bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Padding(
                      padding: const EdgeInsets.only(right: 60),
                      child: Image.asset('assets/images/logo.png', height: 35),
                    ),
                    const SizedBox(height: 40),
                    ...List.generate(menuTitles.length, (index) {
                      final selected = _selectedIndex == index;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedIndex = index);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFFB8BDF1).withOpacity(0.3) : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Image.asset(
                                    'assets/images/${selected ? menuIconsSelected[index] : menuIcons[index]}.png',
                                    width: 22,
                                  ),
                                ),
                                Text(
                                  menuTitles[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selected ? const Color(0xFF6495ED) : Colors.black.withOpacity(0.3),
                                  ),
                                )
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

              // 오른쪽 메인 영역
              Expanded(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // 상단 바
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
                          Text(groupName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                              ...memberNames.map((name) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD9D9D9),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(name, style: const TextStyle(fontSize: 15)),
                              )),
                              const SizedBox(width: 8),
                              const CircleAvatar(
                                radius: 16,
                                backgroundImage: AssetImage('assets/images/user_icon2.png'),
                              )
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
          )
        ],
      ),
    );
  }

  Widget _buildSelectedContent() {
    if (_selectedIndex == 0) {
      return MenuScreen(groupId: widget.groupId, currentUserEmail: widget.currentUserEmail, currentUserName: widget.currentUserEmail,);
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(40),
            ),
            child: _getContentForOtherTabs(),
          ),
        ),
      ],
    );
  }

  Widget _getContentForOtherTabs() {
    switch (_selectedIndex) {
      case 1:
        return const StudyTimeWidget();
      case 2:
        return MeetingCalendarWidget(
          onRecordDateSelected: (date) {
            setState(() {
              _recordDate = date;
              _selectedIndex = 6;
              isRecordingView = true;
            });
          },
        );

      case 3:
        return TaskManageScreen(groupId: widget.groupId, currentUserEmail: widget.currentUserEmail);
      case 4:
        return NoticePage(groupId: widget.groupId, currentUserEmail: widget.currentUserEmail, currentUserName: widget.currentUserEmail,);
      case 5:
        return ChattingPage(groupId: widget.groupId, currentUserEmail: widget.currentUserEmail);
      case 6:
        return _recordDate == null
            ? const Center(child: Text('날짜가 선택되지 않았습니다'))
            : MeetingRecordWidget(selectedDate: _recordDate!);
      default:
        return const SizedBox();
    }
  }
}