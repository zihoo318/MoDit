import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'loading_overlay.dart';

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
  Map<String, String> memberNames = {};
  Map<String, dynamic> studyTimes = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });

    // 실시간 반영을 위해 1초마다 setState
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    LoadingOverlay.show(context, message: "공부 시간 불러오는 중...");
    try {
      await _loadMemberNames();
      _listenToStudyTimes();
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _loadMemberNames() async {
    final memberSnap = await db.child('groupStudies/${widget.groupId}/members').get();
    if (memberSnap.exists) {
      final memberData = Map<String, dynamic>.from(memberSnap.value as Map);
      for (final emailKey in memberData.keys) {
        final userSnap = await db.child('user/$emailKey').get();
        if (userSnap.exists) {
          final userData = Map<String, dynamic>.from(userSnap.value as Map);
          memberNames[emailKey] = userData['name'] ?? emailKey.split('@')[0];
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
      }
    });
  }

  void _startStudy() async {
    final emailKey = widget.currentUserEmail.replaceAll('.', '_');
    final now = DateTime.now().toUtc().toIso8601String();
    final elapsed = (studyTimes[emailKey]?['elapsed'] ?? 0) as int;

    await db.child('groupStudies/${widget.groupId}/studyTimes/$emailKey').set({
      'elapsed': elapsed,
      'startTime': now,
      'isStudying': true,
      'name': widget.currentUserName,
    });
  }

  void _stopStudy() async {
    final emailKey = widget.currentUserEmail.replaceAll('.', '_');
    final data = studyTimes[emailKey];
    if (data == null || data['isStudying'] != true) return;

    final startTime = DateTime.tryParse(data['startTime'] ?? '');
    if (startTime == null) return;

    final now = DateTime.now().toUtc();
    final elapsed = (data['elapsed'] ?? 0) + now.difference(startTime).inSeconds;

    await db.child('groupStudies/${widget.groupId}/studyTimes/$emailKey').update({
      'elapsed': elapsed,
      'isStudying': false,
      'startTime': null,
    });
  }

  String _formatTime(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
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

  Widget _buildStudent(String emailKey) {
    final name = memberNames[emailKey] ?? emailKey.split('@')[0];
    final seconds = _calculateRealTimeSeconds(emailKey);
    final isStudying = studyTimes[emailKey]?['isStudying'] == true;

    return SizedBox(
      width: 135,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: isStudying ? 60 : 54,
            height: isStudying ? 60 : 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isStudying ? const Color(0xFFB3C7FF) : const Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
            child: Text(
              name,
              style: TextStyle(
                fontSize: isStudying ? 18 : 16,
                fontWeight: isStudying ? FontWeight.bold : FontWeight.normal,
                color: isStudying ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Image.asset(
              isStudying ? 'assets/images/study_icon2.png' : 'assets/images/study_icon.png',
              width: 85,
              height: 80,
              key: ValueKey(isStudying), // 상태 전환 시 애니메이션 적용
            ),
          ),
          const SizedBox(height: 4),
          Text(_formatTime(seconds), style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final currentKey = widget.currentUserEmail.replaceAll('.', '_');
    final allKeys = memberNames.keys.toList();
    final myTime = _calculateRealTimeSeconds(currentKey);
    final isStudying = studyTimes[currentKey]?['isStudying'] == true;

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
                  child: Text("공부 시간", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                        Text(_formatTime(myTime), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
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