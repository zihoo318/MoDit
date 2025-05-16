import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'study_time.dart';
import 'taskManageScreen.dart';
import 'notice.dart';
import 'chatting.dart';
import 'meeting_calendar.dart';
import 'card_study_time.dart';
import 'card_meeting_calendar.dart';

class MenuScreen extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  final String currentUserName;
  final void Function(int)? onNavigateToTab; // ✅ 추가

  const MenuScreen({
    required this.groupId,
    required this.currentUserEmail,
    required this.currentUserName,
    this.onNavigateToTab, // ✅ 추가
    Key? key,
  }) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
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
                        InkWell(
                          onTap: () => widget.onNavigateToTab?.call(1),
                          child: _buildCardContainer(
                            title: '공부 시간',
                            child: StudyTimeCard(
                              groupId: widget.groupId,
                              currentUserEmail: widget.currentUserEmail,
                              currentUserName: widget.currentUserName,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => widget.onNavigateToTab?.call(3),
                            child: _buildHomeworkCard(),
                          ),
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
                                  onTap: () => widget.onNavigateToTab?.call(4),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: _buildCard(
                                  title: '채팅',
                                  icon: 'chatting_icon',
                                  onTap: () => widget.onNavigateToTab?.call(5),
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
                      onTap: () => widget.onNavigateToTab?.call(2),
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

  Widget _buildCard({required String title, required String icon, required VoidCallback onTap}) {
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
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeworkCard() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.30 + 47,
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
              const Text('과제 관리', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('조별 발표 준비', style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
