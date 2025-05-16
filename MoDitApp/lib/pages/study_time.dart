import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class StudyTimeWidget extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  final String currentUserName;

  const StudyTimeWidget({
    super.key,
    required this.groupId,
    required this.currentUserEmail,
    required this.currentUserName,
  });

  @override
  State<StudyTimeWidget> createState() => _StudyTimeWidgetState();
}

class _StudyTimeWidgetState extends State<StudyTimeWidget> {
  final db = FirebaseDatabase.instance.ref();
  Timer? timer;
  bool isStudying = false;
  Map<String, int> studySeconds = {}; // 초 단위 저장
  Map<String, String> memberNames = {}; // 이메일 → 이름 매핑
  Set<String> currentlyStudying = {}; // 현재 공부 중인 사용자 목록

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _listenToStudyTimes();
    _checkMidnightReset();
  }

  void _loadMembers() async {
    final snap = await db.child('groupStudies').child(widget.groupId).child('members').get();
    if (snap.exists) {
      final members = Map<String, dynamic>.from(snap.value as Map);
      for (var email in members.keys) {
        final userSnap = await db.child('user').child(email).get();
        if (userSnap.exists) {
          final data = Map<String, dynamic>.from(userSnap.value as Map);
          memberNames[email] = data['name'] ?? email.split('@')[0];
        }
      }
      setState(() {});
    }
  }

  void _listenToStudyTimes() {
    db.child('groupStudies').child(widget.groupId).child('studyTimes').onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          studySeconds = {};
          currentlyStudying.clear();
          data.forEach((emailKey, value) {
            studySeconds[emailKey] = value['elapsed'] ?? 0;
            if (value['isStudying'] == true) currentlyStudying.add(emailKey);
          });
        });
      }
    });
  }

  void _checkMidnightReset() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);
    Future.delayed(durationUntilMidnight, () async {
      await db.child('groupStudies').child(widget.groupId).child('studyTimes').remove();
    });
  }

  void _startStudy() {
    setState(() => isStudying = true);
    final emailKey = widget.currentUserEmail.replaceAll('.', '_');
    timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final current = (studySeconds[emailKey] ?? 0) + 1;
      await db.child('groupStudies').child(widget.groupId).child('studyTimes').child(emailKey).set({
        'elapsed': current,
        'name': widget.currentUserName,
        'isStudying': true,
      });
    });
  }

  void _stopStudy() async {
    setState(() => isStudying = false);
    timer?.cancel();
    final emailKey = widget.currentUserEmail.replaceAll('.', '_');
    await db.child('groupStudies').child(widget.groupId).child('studyTimes').child(emailKey).update({
      'isStudying': false,
    });
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$secs";
  }

  Widget _buildStudent(String emailKey) {
    final name = memberNames[emailKey] ?? emailKey.split('@')[0];
    final seconds = studySeconds[emailKey] ?? 0;
    final isThisUserStudying = currentlyStudying.contains(emailKey) ||
        (emailKey == widget.currentUserEmail.replaceAll('.', '_') && isStudying);

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
            isThisUserStudying
                ? 'assets/images/study_icon2.png'
                : 'assets/images/study_icon.png',
            width: 85,
            height: 80,
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(seconds),
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allKeys = memberNames.keys.toList();
    final currentKey = widget.currentUserEmail.replaceAll('.', '_');
    final myTime = studySeconds[currentKey] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("공부 시간", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          _formatTime(myTime),
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
                alignment: WrapAlignment.center,
                children: allKeys.map(_buildStudent).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
