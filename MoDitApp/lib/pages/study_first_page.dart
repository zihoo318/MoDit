import 'dart:math';
import 'package:flutter/material.dart';

// 각 페이지 import
import 'homework.dart';
import 'study_time.dart';
import 'chatting.dart';
import 'notice.dart';
import 'homework.dart';
import 'meeting_schedule.dart';

class StudyFirstPage extends StatelessWidget {
  final String groupName;
  final List<String> members;

  const StudyFirstPage({
    super.key,
    required this.groupName,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final random = Random();
    final colors = [
      const Color(0xFF4C92D7),
      const Color(0xFF6495ED),
      const Color(0xFF7DB5EB),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 상단 바
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 10),
                Text(
                  groupName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ...members.map((name) {
                  final color = colors[random.nextInt(colors.length)];
                  return _buildMember(name, color);
                }).toList(),
                const SizedBox(width: 10),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage('assets/images/user_icon.png'),
                ),
              ],
            ),
            const SizedBox(height: 60),
            // 🔹 아이콘 박스 (2행 구성)
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIconBox(context, '공부 시간', 'assets/images/studytime_icon.png', StudyTimeScreen()),
                    _buildIconBox(context, '채팅', 'assets/images/study_icon.png', ChattingScreen(groupName: groupName)),
                  ],
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildIconBox(context, '공지사항', 'assets/images/notice_icon.png', const NoticePage(groupId: '', currentUserEmail: '',)),
                    _buildIconBox(context, '과제 관리', 'assets/images/homework_icon.png', const HomeworkScreen()),
                    _buildIconBox(context, '미팅 일정', 'assets/images/meetingplan_icon.png', const MeetingSchedulePage()),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMember(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildIconBox(BuildContext context, String label, String imagePath, Widget targetPage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => targetPage),
        );
      },
      child: Container(
        width: 270,
        height: 260,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(70),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 100, height: 100),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
