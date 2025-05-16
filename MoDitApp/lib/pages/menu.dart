import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'study_time.dart';
import 'taskManageScreen.dart';
import 'notice.dart';
import 'chatting.dart';
import 'meeting_calendar.dart';
import 'meeting_record.dart';
import 'card_study_time.dart';
import 'card_meeting_calendar.dart';

class MenuScreen extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  final String currentUserName;

  const MenuScreen({
    required this.groupId,
    required this.currentUserEmail,
    required this.currentUserName,
    Key? key,
  }) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Map<String, Duration> studyTimes = {
    '가을': const Duration(hours: 1, minutes: 23, seconds: 45),
    '윤지': const Duration(hours: 2, minutes: 12, seconds: 10),
    '유진': const Duration(hours: 1, minutes: 59, seconds: 5),
    '지후': const Duration(hours: 3, minutes: 10, seconds: 0),
    '시연': const Duration(hours: 2, minutes: 5, seconds: 0),
    '수연': const Duration(hours: 2, minutes: 45, seconds: 15),
  };

  String currentUser = '지후';
  bool isStudying = true;
  int _homeworkTabIndex = 0;

  final db = FirebaseDatabase.instance.ref();
  String groupName = '';
  List<String> memberNames = [];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = screenWidth * 0.30;

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
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: cardWidth + 45,
                    height: screenHeight * 0.80 + 21,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () => _navigateToPage('study_time'),
                          child: _buildCardContainer(
                            title: '공부 시간',
                            child: StudyTimeCard(
                              studyTimes: studyTimes,
                              currentUser: currentUser,
                              isStudying: isStudying,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _buildHomeworkCard(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _buildCard(
                                  title: '공지사항',
                                  icon: 'notice_icon',
                                  onTap: () => _navigateToPage('notice'),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _buildCard(
                                  title: '채팅',
                                  icon: 'chatting_icon',
                                  onTap: () => _navigateToPage('chatting'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: cardWidth + 80,
                    height: screenWidth * 0.4 - 10,
                    child: GestureDetector(
                      onTap: () => _navigateToPage('meeting_calendar'),
                      child: _buildCardContainer(
                        title: '미팅 일정 & 녹음',
                        child: const MeetingCalendarCard(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDDay(String deadline) {
    final deadlineDate = DateTime.parse(deadline);
    final today = DateTime.now();
    final difference = deadlineDate.difference(today).inDays;

    if (difference > 0) return 'D-$difference';
    if (difference == 0) return 'D-DAY';
    return '마감됨';
  }

  Widget _buildHomeworkCard() {
    final List<Map<String, dynamic>> tasks = [
      {
        'title': '챕터 3 요약',
        'deadline': '2025-05-18',
        'submitted': false,
      },
      {
        'title': '기말 과제 초안',
        'deadline': '2025-05-20',
        'submitted': true,
      },
      {
        'title': '조별 발표 준비',
        'deadline': '2025-05-17',
        'submitted': false,
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.30;

    final DateTime now = DateTime.now();
    final filteredTasks = tasks.where((task) {
      final deadline = DateTime.parse(task['deadline']);
      return deadline.isAfter(now) && task['submitted'] == false;
    }).toList()
      ..sort((a, b) => DateTime.parse(a['deadline']).compareTo(DateTime.parse(b['deadline'])));

    final Map<String, dynamic>? nextTask = filteredTasks.isNotEmpty ? filteredTasks.first : null;

    return GestureDetector(
      onTap: () => _navigateToPage('task'),
      child: Container(
        width: cardWidth + 47,
        height: 105,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/images/homework_icon.png', width: 36),
                const SizedBox(width: 10),
                const Text(
                  '과제 관리',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (nextTask != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      nextTask['title'],
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _calculateDDay(nextTask['deadline']),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              )
            else
              const Text('미제출 과제가 없습니다.', style: TextStyle(fontSize: 14, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  void _navigateToPage(String pageName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => getPageByName(pageName),
      ),
    );
  }

  Widget getPageByName(String pageName) {
    switch (pageName) {
      case 'task':
        return TaskManageScreen(groupId: widget.groupId, currentUserEmail: widget.currentUserEmail);
      case 'notice':
        return NoticePage(
          groupId: widget.groupId,
          currentUserEmail: widget.currentUserEmail,
          currentUserName: widget.currentUserName,
        );
      case 'study_time':
        return const StudyTimeWidget();
      case 'chatting':
        return ChattingPage(groupId: widget.groupId, currentUserEmail: widget.currentUserEmail);
      case 'meeting_calendar':
        return MeetingCalendarWidget(
          groupId: widget.groupId,
          onRecordDateSelected: (date, meetingId) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MeetingRecordWidget(
                  selectedDate: date,
                  groupId: widget.groupId,
                  meetingId: meetingId,
                ),
              ),
            );
          },
        );
      default:
        return const Center(child: Text('잘못된 페이지'));
    }
  }

  Widget _buildCard({
    required String title,
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/$icon.png', width: 40),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
