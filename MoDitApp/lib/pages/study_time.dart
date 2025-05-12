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
    '가을': const Duration(hours: 0),
    '윤지': const Duration(hours: 0),
    '유진': const Duration(hours: 0),
    '지후': const Duration(hours: 0),
    '시연': const Duration(hours: 0),
    '수연': const Duration(hours: 0),
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
    bool studying = name == currentUser && isStudying;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFE0E0E0),
            shape: BoxShape.circle,
          ),
          child: Text(name, style: const TextStyle(fontSize: 14)),
        ),
        const SizedBox(height: 2),
        Image.asset(
          studying ? 'assets/images/study_icon2.png' : 'assets/images/study_icon.png',
          width: 100,
          height: 100,
        ),
        const SizedBox(height: 2),
        Text(_formatTime(studyTimes[name] ?? Duration.zero), style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = studyTimes.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text("공부 시간", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1ECFA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_formatTime(elapsedTime), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                const SizedBox(width: 16),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.play_arrow, color: Color(0xFF6C79FF)),
                  onPressed: isStudying ? null : _startStudy,
                ),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.stop, color: Color(0xFF6C79FF)),
                  onPressed: isStudying ? _stopStudy : null,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
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
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
              children: members.map((name) => _buildStudent(name)).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
