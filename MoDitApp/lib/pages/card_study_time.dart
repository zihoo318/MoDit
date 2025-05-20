import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class StudyTimeCard extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  final String currentUserName;
  final VoidCallback? onDataLoaded;

  const StudyTimeCard({
    super.key,
    required this.groupId,
    required this.currentUserEmail,
    required this.currentUserName,
    this.onDataLoaded,
  });

  @override
  State<StudyTimeCard> createState() => _StudyTimeCardState();
}

class _StudyTimeCardState extends State<StudyTimeCard> {
  final db = FirebaseDatabase.instance.ref();
  Map<String, int> studySeconds = {}; // 초 단위
  Map<String, String> memberNames = {}; // 이메일 → 이름 매핑
  Set<String> currentlyStudying = {}; // 공부 중인 사람

  @override
  void initState() {
    super.initState();
    // _loadMembers();
    // _listenToStudyTimes();
    _loadStudyData(); // 비동기 로딩 시작
  }

  Future<void> _loadStudyData() async {
    await _loadMembers(); // 예: 멤버 정보 불러오기
    _listenToStudyTimes(); // 리스너 등록

    // 모든 데이터 로딩이 끝나면 콜백 호출
    if (widget.onDataLoaded != null) {
      widget.onDataLoaded!();
    }
  }

  Future<void> _loadMembers() async {
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
            if (value['isStudying'] == true) {
              currentlyStudying.add(emailKey);
            }
          });
        });
      }
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
    final isStudying = currentlyStudying.contains(emailKey);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(name, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 6),
        Image.asset(
          isStudying ? 'assets/images/study_icon2.png' : 'assets/images/study_icon.png',
          width: 35,
          height: 35,
        ),
        const SizedBox(height: 7),
        Text(
          _formatTime(seconds),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final members = memberNames.keys.toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      width: MediaQuery.of(context).size.width * 0.42,
      height: MediaQuery.of(context).size.height * 0.31,
      child: GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 17,
        childAspectRatio: 1.3,
        shrinkWrap: true,
        children: members.map(_buildStudent).toList(),
      ),
    );
  }
}
