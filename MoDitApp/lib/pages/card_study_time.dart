import 'package:flutter/material.dart';

class StudyTimeCard extends StatelessWidget {
  final Map<String, Duration> studyTimes;
  final String currentUser;
  final bool isStudying;

  const StudyTimeCard({
    super.key,
    required this.studyTimes,
    required this.currentUser,
    required this.isStudying,
  });

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Widget _buildStudent(String name) {
    bool studying = name == currentUser && isStudying;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Image.asset(
          studying ? 'assets/images/study_icon2.png' : 'assets/images/study_icon.png',
          width: 35,
          height: 35,
        ),
        const SizedBox(height: 4),
        Text(_formatTime(studyTimes[name] ?? Duration.zero), style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = studyTimes.keys.toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      width: MediaQuery.of(context).size.width * 0.40, // 부모 컨테이너의 가로 길이 설정
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(), // 카드 안에서는 스크롤 비활성화
        crossAxisCount: 3, // 한 줄에 3개의 아이템
        crossAxisSpacing:12, // 가로 방향 간격
        mainAxisSpacing: 4, // 세로 방향 간격
        childAspectRatio: 1.3, // 아이템의 가로:세로 비율
        shrinkWrap: true, // 자식 크기만큼만 크기 조정
        children: members.map((name) => _buildStudent(name)).toList(),
      ),
    );
  }
}