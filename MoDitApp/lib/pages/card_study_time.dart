import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

import 'loading_overlay.dart';


class StudyTimeCard extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  final String currentUserName;
  final VoidCallback? onDataLoaded; // ✅ 추가

  const StudyTimeCard({
    super.key,
    required this.groupId,
    required this.currentUserEmail,
    required this.currentUserName,
    this.onDataLoaded, // ✅ 추가
  });

  @override
  State<StudyTimeCard> createState() => _StudyTimeCardState();
}

class _StudyTimeCardState extends State<StudyTimeCard> {
  final db = FirebaseDatabase.instance.ref();
  Map<String, int> studySeconds = {};
  Map<String, String> memberNames = {};
  Map<String, dynamic> studyTimes = {};
  Timer? _refreshTimer;
  bool _studyTimeLoaded = false; // 로딩 해제 여부


  bool _isLoading = true;  // 로딩 플래그 추가

  @override
  void initState() {
    super.initState();
    _initialize();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

void _initialize() async {
  setState(() => _isLoading = true);          // 로딩 시작
  await _loadMembers();                       // 멤버 불러오기
  _listenToStudyTimes();                      // 리스너 등록
  setState(() => _isLoading = false);         // 로딩 끝

  if (widget.onDataLoaded != null) {
    widget.onDataLoaded!();                   // 콜백 실행
  }
}



  Future<void> _loadMembers() async {
    final snap = await db.child('groupStudies/${widget.groupId}/members').get();
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
    db.child('groupStudies/${widget.groupId}/studyTimes').onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          studyTimes = data;
        });

        if (!_studyTimeLoaded) {
          _studyTimeLoaded = true;
          LoadingOverlay.hide(); // 🎯 최초 수신 시 로딩 해제
        }
      }
    });
  }


  int _calculateRealTimeSeconds(String emailKey) {
    final data = studyTimes[emailKey];
    if (data == null) return 0;
    int base = data['elapsed'] ?? 0;
    if (data['isStudying'] == true && data['startTime'] != null) {
      final start = DateTime.tryParse(data['startTime']);
      if (start != null) {
        final now = DateTime.now().toUtc();
        base += now.difference(start).inSeconds;
      }
    }
    return base;
  }

  String _formatTime(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  Widget _buildStudent(String emailKey) {
    final name = memberNames[emailKey] ?? emailKey.split('@')[0];
    final seconds = _calculateRealTimeSeconds(emailKey);
    final isStudying = studyTimes[emailKey]?['isStudying'] == true;

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
        Text(_formatTime(seconds), style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // 로딩 중에는 카드 크기/모양은 그대로 두고 스피너만 중앙에 표시
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
        ),
        width: MediaQuery.of(context).size.width * 0.42,
        height: MediaQuery.of(context).size.height * 0.31,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    // 여기까지 추가

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