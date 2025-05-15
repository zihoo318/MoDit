import 'package:flutter/material.dart';
import 'dart:async';

class StudyTimeWidget extends StatefulWidget {
  const StudyTimeWidget({super.key});

  @override
  State<StudyTimeWidget> createState() => _StudyTimeWidgetState();
}

class _StudyTimeWidgetState extends State<StudyTimeWidget> {
  Duration elapsedTime = Duration.zero;
  Timer? timer;
  bool isStudying = false;
  final String currentUser = '윤지';

  final Map<String, Duration> studyTimes = {
    '가을': Duration.zero,
    '윤지': Duration.zero,
    '유진': Duration.zero,
    '지후': Duration.zero,
    '시연': Duration.zero,
    '수연': Duration.zero,
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

  Widget _buildStudent(String name) {
    final bool studying = name == currentUser && isStudying;
    return SizedBox(
      width: 135,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
            child: Text(name, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 4),
          Image.asset(
            studying
                ? 'assets/images/study_icon2.png'
                : 'assets/images/study_icon.png',
            width: 85,
            height: 80,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(studyTimes[name]!),
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = studyTimes.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height:4),

        // ✅ "공부 시간" 텍스트는 왼쪽, 타이머 박스는 중앙
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "공부 시간",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1ECFA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(elapsedTime),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          iconSize: 24,
                          icon: const Icon(Icons.play_arrow, color: Color(0xFF6C79FF)),
                          onPressed: isStudying ? null : _startStudy,
                        ),
                        IconButton(
                          iconSize: 24,
                          icon: const Icon(Icons.stop, color: Color(0xFF6C79FF)),
                          onPressed: isStudying ? _stopStudy : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 학생 Wrap 레이아웃
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Wrap(
                spacing: 100,
                runSpacing: 45,
/* 유진언니 화면에 맞춘거
                spacing: 180,
                runSpacing: 100,
*/
                alignment: WrapAlignment.center,
                children: members.map(_buildStudent).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
