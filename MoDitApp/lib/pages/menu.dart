import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'study_time.dart'; // StudyTimeScreen 임포트
import 'taskManageScreen.dart'; // TaskManageScreen 임포트
import 'notice.dart'; // NoticePage 임포트
import 'chatting.dart'; // ChattingPage 임포트
import 'meeting_calendar.dart'; // MeetingCalendarScreen 임포트
import 'card_study_time.dart'; // StudyTimeCard 위젯 임포트
import 'card_meeting_calendar.dart'; // MeetingCalendarCard 위젯 임포트

class MenuScreen extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  final String currentUserName; // ✅ 추가

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
  bool isStudying = true; // 예시용. 나중에 Firebase 연동 가능
  int _homeworkTabIndex = 0; // 과제 탭 내부 인덱스

  final db = FirebaseDatabase.instance.ref();
  String groupName = '';
  List<String> memberNames = [];
  DateTime? _recordDate;
  bool isRecordingView = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

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
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              children: [
                // 첫 번째 행: 공부 시간 카드 + 미팅 카드
                Row(
                  children: [
                    // 공부 시간 카드
                    SizedBox(
                      width: screenWidth * 0.33,
                      child: GestureDetector(
                        onTap: () => _navigateToPage('study_time'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('공부 시간', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              StudyTimeCard(
                                studyTimes: studyTimes,
                                currentUser: currentUser,
                                isStudying: isStudying,
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // 미팅 일정 & 녹음 카드
                    SizedBox(
                      width: screenWidth * 0.33,
                      child: GestureDetector(
                        onTap: () => _navigateToPage('meeting_calendar'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('미팅 일정 & 녹음', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              MeetingCalendarCard(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // 두 번째 행: 과제, 공지, 채팅 카드
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildCard(
                        title: '과제 관리',
                        icon: 'homework_icon',
                        onTap: () => _navigateToPage('task'),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildCard(
                        title: '공지사항',
                        icon: 'notice_icon',
                        onTap: () => _navigateToPage('notice'),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _buildCard(
                        title: '채팅',
                        icon: 'chatting_icon',
                        onTap: () => _navigateToPage('chatting'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
        return TaskManageScreen(
          tabIndex: _homeworkTabIndex,
          onTabChanged: (int index) {
            setState(() => _homeworkTabIndex = index);
          },
        );
      case 'notice':
        return NoticePage(
          groupId: widget.groupId,
          currentUserEmail: widget.currentUserEmail,
          currentUserName: widget.currentUserName, // ✅ 전달
        );
      case 'study_time':
        return const StudyTimeWidget();
      case 'chatting':
        return ChattingPage(
          groupId: widget.groupId,
          currentUserEmail: widget.currentUserEmail,
        );
      case 'meeting_calendar':
        return MeetingCalendarWidget(
          onRecordDateSelected: (date) {
            setState(() {
              _recordDate = date;
              isRecordingView = true;
            });
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/$icon.png',
              width: 40,
            ),
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
