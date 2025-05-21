import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'study_time.dart';
import 'taskManageScreen.dart';
import 'notice.dart';
import 'chatting.dart';
import 'meeting_calendar.dart';
import 'meeting_record.dart';
import 'card_study_time.dart';
import 'card_meeting_calendar.dart';
import 'loading_overlay.dart';

class MenuScreen extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  final String currentUserName;
  final void Function(int)? onNavigateToTab;

  const MenuScreen({
    required this.groupId,
    required this.currentUserEmail,
    required this.currentUserName,
    this.onNavigateToTab,
    Key? key,
  }) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Map<String, String>? upcomingTask;
  bool _isStudyTimeLoaded = false;
  bool _isTaskLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LoadingOverlay.show(context, message: '데이터 로딩 중입니다...');
      _loadUpcomingTask();
    });
  }

  void _onStudyTimeLoaded() {
    setState(() => _isStudyTimeLoaded = true);
    _checkAllLoaded();
  }

  void _onTaskLoaded() {
    setState(() => _isTaskLoaded = true);
    _checkAllLoaded();
  }

  void _checkAllLoaded() {
    if (_isStudyTimeLoaded && _isTaskLoaded) {
      LoadingOverlay.hide();
    }
  }

  Future<void> _loadAllData() async {
    LoadingOverlay.show(context, message: '데이터 로딩 중입니다...');

    try {
      await _loadUpcomingTask();
    } catch (e) {
      print("데이터 로딩 에러: $e");
    } finally {
      LoadingOverlay.hide();
    }
  }

  Future<void> _loadUpcomingTask() async {
    final task = await getUpcomingUnsubmittedTask(widget.groupId, widget.currentUserEmail);
    setState(() {
      upcomingTask = task;
    });
    _onTaskLoaded(); // 과제 데이터 로딩 완료 후 체크
  }


  Future<Map<String, String>?> getUpcomingUnsubmittedTask(String groupId, String currentUserEmail) async {
    final db = FirebaseDatabase.instance.ref();
    final snapshot = await db.child('tasks').child(groupId).get();
    if (!snapshot.exists) return null;

    final today = DateTime.now();
    Map<String, String>? earliest;

    final tasks = Map<String, dynamic>.from(snapshot.value as Map);
    for (final task in tasks.values) {
      final taskData = Map<String, dynamic>.from(task);
      final title = taskData['title'];
      final deadlineStr = taskData['deadline'];
      final deadline = DateTime.tryParse(deadlineStr ?? '');
      if (deadline == null || deadline.isBefore(today)) continue;

      final subTasks = Map<String, dynamic>.from(taskData['subTasks'] ?? {});
      for (final sub in subTasks.values) {
        final subData = Map<String, dynamic>.from(sub);
        final subtitle = subData['subtitle'];
        final submissions = Map<String, dynamic>.from(subData['submissions'] ?? {});
        if (!submissions.containsKey(currentUserEmail)) {
          if (earliest == null || deadline.isBefore(DateTime.parse(earliest['deadline']!))) {
            earliest = {
              'title': title,
              'subtitle': subtitle,
              'deadline': deadline.toIso8601String(),
            };
          }
        }
      }
    }

    return earliest;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final cardWidth = screenWidth * 0.30;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
              alignment: Alignment.topLeft,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.03),
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: cardWidth + 45,
                    height: screenHeight * 0.9,
                    child: Column(
                      children: [
                        InkWell(
                          onTap: () => widget.onNavigateToTab?.call(1),
                          child: _buildCardContainer(
                            title: '공부 시간',
                            icon: 'study_icon',
                            iconSize: 26,
                            child: StudyTimeCard(
                              groupId: widget.groupId,
                              currentUserEmail: widget.currentUserEmail,
                              currentUserName: widget.currentUserName,
                              onDataLoaded: _onStudyTimeLoaded,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => widget.onNavigateToTab?.call(3),
                            child: _buildTaskCard(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1),
                                child: _buildCard(
                                  title: '공지사항',
                                  icon: 'notice_icon',
                                  iconSize: 40,
                                  onTap: () => widget.onNavigateToTab?.call(4),
                                )
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: _buildCard(
                                    title: '채팅',
                                    icon: 'chatting_icon',
                                    iconSize: 40,
                                    onTap: () => widget.onNavigateToTab?.call(5),
                                  )
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  SizedBox(
                    width: cardWidth + 80,
                    height: screenWidth * 0.4 - 10,
                    child: GestureDetector(
                      onTap: () => widget.onNavigateToTab?.call(2),
                      child: _buildCardContainer(
                        title: '미팅 일정 & 녹음',
                        icon: 'calendar_icon',
                        iconSize: 29,
                        child: MeetingCalendarCard(groupId: widget.groupId),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardContainer({
    required String title,
    required String icon,
    required Widget child,
    required double iconSize,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/$icon.png', width: iconSize), // iconSize 사용
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }


  Widget _buildCard({
    required String title,
    required String icon,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/$icon.png', width: iconSize),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }


  Widget _buildTaskCard() {
    String? title = upcomingTask?['title'];
    String? subtitle = upcomingTask?['subtitle'];
    String? deadlineStr = upcomingTask?['deadline'];

    String dDayText = '';
    if (deadlineStr != null) {
      final deadline = DateTime.tryParse(deadlineStr);
      if (deadline != null) {
        final today = DateTime.now();
        final todayDateOnly = DateTime(today.year, today.month, today.day);
        final deadlineDateOnly = DateTime(deadline.year, deadline.month, deadline.day);
        final difference = deadlineDateOnly.difference(todayDateOnly).inDays;
        dDayText = 'D-${difference >= 0 ? difference : 0}';
      }
    }

    return Container(
      width: MediaQuery.of(context).size.width * 0.30 + 47,
      height: 105,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/homework_icon.png', width: 36),
              const SizedBox(width: 10),
              const Text('과제 관리', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  (title == null || subtitle == null)
                      ? '제출하지 않은 과제가 없습니다.'
                      : '$title  -  $subtitle',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              if (dDayText.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dDayText,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
