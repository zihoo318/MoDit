// study_time.dart (최적화: 간격, 크기, 배경 포함)
import 'package:flutter/material.dart';
import 'dart:async';

class StudyTimeScreen extends StatefulWidget {
  const StudyTimeScreen({super.key});

  @override
  State<StudyTimeScreen> createState() => _StudyTimeScreenState();
}

class _StudyTimeScreenState extends State<StudyTimeScreen> {
  Duration elapsedTime = Duration.zero;
  Timer? timer;
  bool isStudying = false;
  final String currentUser = '윤지';

  final Map<String, Duration> studyTimes = {
    '가을': const Duration(hours: 0, minutes: 0, seconds: 0),
    '윤지': const Duration(hours: 0, minutes: 0, seconds: 0),
    '유진': const Duration(hours: 0, minutes: 0, seconds: 0),
    '지후': const Duration(hours: 0, minutes: 0, seconds: 0),
    '시연': const Duration(hours: 0, minutes: 0, seconds: 0),
    '수연': const Duration(hours: 0, minutes: 0, seconds: 0),
  };

  void _startStudy() {
    setState(() => isStudying = true);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        elapsedTime += const Duration(seconds: 1);
        studyTimes[currentUser] = elapsedTime;
      });
    });
  }

  void _stopStudy() {
    setState(() => isStudying = false);
    timer?.cancel();
  }

  String _formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  Widget _buildSidebarItem(IconData icon, String title, {bool active = false}) {
    return Container(
      color: active ? const Color(0xFFCAD0FF) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: active ? const Color(0xFF6C79FF) : Colors.grey),
        title: Text(title, style: TextStyle(color: active ? const Color(0xFF6C79FF) : Colors.grey)),
      ),
    );
  }

  Widget _buildStudent(String name) {
    bool studying = name == currentUser && isStudying;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Image.asset(
          studying ? 'assets/images/study_icon2.png' : 'assets/images/study_icon.png',
          width: 100,
          height: 100,
        ),
        const SizedBox(height: 6),
        Text(_formatTime(studyTimes[name] ?? Duration.zero), style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = studyTimes.keys.toList();

    return Scaffold(
      body: Row(
        children: [
          // 사이드바
          Container(
            width: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDCDFFD), Color(0xFFF2DAFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("MoDit", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF9496DB))),
                ),
                _buildSidebarItem(Icons.grid_view_rounded, "메뉴"),
                _buildSidebarItem(Icons.alarm, "공부 시간", active: true),
                _buildSidebarItem(Icons.calendar_month_outlined, "미팅 일정 & 녹음"),
                _buildSidebarItem(Icons.book, "과제 관리"),
                _buildSidebarItem(Icons.announcement, "공지사항"),
                _buildSidebarItem(Icons.chat, "채팅"),
              ],
            ),
          ),
          // 본문
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDCDFFD), Color(0xFFF2DAFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 바
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        const Text("그룹스터디이름", style: TextStyle(fontSize: 18)),
                        const Spacer(),
                        ...members.map((e) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Chip(label: Text(e)),
                            )),
                        const SizedBox(width: 12),
                        const CircleAvatar(backgroundColor: Colors.white, radius: 20, child: Icon(Icons.person)),
                      ],
                    ),
                  ),
                  // 타이머 및 시작/정지 버튼
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1ECFA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_formatTime(elapsedTime), style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: const Icon(Icons.play_arrow, color: Color(0xFF6C79FF)),
                            onPressed: isStudying ? null : _startStudy,
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop, color: Color(0xFF6C79FF)),
                            onPressed: isStudying ? _stopStudy : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 학생들 아이콘과 시간
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 40,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.3,
                        shrinkWrap: true,
                        children: members.map((name) => _buildStudent(name)).toList(),
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
