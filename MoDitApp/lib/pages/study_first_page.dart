import 'package:flutter/material.dart';

class StudyFirstPage extends StatelessWidget {
  const StudyFirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.arrow_back),
                const SizedBox(width: 10),
                const Text(
                  '그룹 스터디 이름',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                _buildMember('가을'),
                _buildMember('윤지'),
                _buildMember('유진'),
                _buildMember('지후'),
                const SizedBox(width: 10),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage('assets/images/user_icon.png'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildIconBox('공부 시간', 'assets/images/studytime_icon.png'),
                _buildIconBox('채팅', 'assets/images/study_icon.png'),
                _buildIconBox('공지사항', 'assets/images/notice_icon.png'),
                _buildIconBox('과제 관리', 'assets/images/homework_icon.png'),
                _buildIconBox('미팅 일정', 'assets/images/meetingplan_icon.png'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMember(String name) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          name,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildIconBox(String label, String imagePath) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, width: 36, height: 36),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
