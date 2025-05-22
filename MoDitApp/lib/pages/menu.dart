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
import 'menu_animated_card.dart';

class MenuScreen extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  final String currentUserName;
  final void Function(int)? onNavigateToTab;
  final Offset targetCenter;

  const MenuScreen({
    required this.groupId,
    required this.currentUserEmail,
    required this.currentUserName,
    required this.targetCenter,
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
  int? _selectedCardIndex;

  @override
  void initState() {
    super.initState();
    _loadUpcomingTask();
  }

  Future<void> _loadUpcomingTask() async {
    final db = FirebaseDatabase.instance.ref();
    final snapshot = await db.child('tasks').child(widget.groupId).get();
    if (!snapshot.exists) return;

    final tasksMap = Map<String, dynamic>.from(snapshot.value as Map);
    final today = DateTime.now();
    Map<String, String>? earliest;

    for (final taskEntry in tasksMap.entries) {
      final taskData = Map<String, dynamic>.from(taskEntry.value);
      final title = taskData['title'] as String?;
      final deadlineStr = taskData['deadline'] as String?;
      final deadline = deadlineStr != null ? DateTime.tryParse(deadlineStr) : null;
      if (title == null || deadline == null || deadline.isBefore(today)) continue;

      final subTasksMap = Map<String, dynamic>.from(taskData['subTasks'] as Map? ?? {});
      for (final subEntry in subTasksMap.entries) {
        final subData = Map<String, dynamic>.from(subEntry.value);
        final subtitle = subData['subtitle'] as String?;
        final submissionsMap = Map<String, dynamic>.from(subData['submissions'] as Map? ?? {});
        if (subtitle != null && !submissionsMap.containsKey(widget.currentUserEmail)) {
          if (earliest == null ||
              deadline.isBefore(DateTime.parse(earliest['deadline']!))) {
            earliest = {
              'title': title,
              'subtitle': subtitle,
              'deadline': deadline.toIso8601String(),
            };
          }
        }
      }
    }

    setState(() {
      upcomingTask = earliest;
      _isTaskLoaded = true;
    });
  }

  void _onStudyTimeLoaded() {
    setState(() => _isStudyTimeLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final cardW = w * 0.30;
    final cardAnim = Duration(milliseconds: 300);
    final pageAnim = Duration(milliseconds: 650);


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
            padding: EdgeInsets.all(w * 0.03),
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽 컬럼
                  SizedBox(
                    width: cardW + 45,
                    height: h * 0.9,
                    child: Column(
                      children: [
                        // 공부 시간 카드 (index = 1)
                        AnimatedCard(
                          index: 1,
                          selectedIndex: _selectedCardIndex,
                          onTap: () => setState(() => _selectedCardIndex = 1),
                          targetCenter: widget.targetCenter,
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
                          onCompleted: () => widget.onNavigateToTab?.call(1),
                        ),

                        const SizedBox(height: 12),

                        // 과제 관리 카드 (index = 3)
                        AnimatedCard(
                          index: 3,
                          selectedIndex: _selectedCardIndex,
                          onTap: () => setState(() => _selectedCardIndex = 3),
                          targetCenter: widget.targetCenter,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _buildTaskCard(),
                          ),
                          onCompleted: () => widget.onNavigateToTab?.call(3),
                        ),

                        const SizedBox(height: 12),

                        // 공지사항(4) & 채팅(5)
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedCard(
                                index: 4,
                                selectedIndex: _selectedCardIndex,
                                onTap: () => setState(() => _selectedCardIndex = 4),
                                targetCenter: widget.targetCenter,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 1),
                                  child: _buildCard(
                                    title: '공지사항',
                                    icon: 'notice_icon',
                                    iconSize: 40,
                                  ),
                                ),
                                onCompleted: () => widget.onNavigateToTab?.call(4),
                              ),
                            ),
                            Expanded(
                              child: AnimatedCard(
                                index: 5,
                                selectedIndex: _selectedCardIndex,
                                onTap: () => setState(() => _selectedCardIndex = 5),
                                targetCenter: widget.targetCenter,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: _buildCard(
                                    title: '채팅',
                                    icon: 'chatting_icon',
                                    iconSize: 40,
                                  ),
                                ),
                                onCompleted: () => widget.onNavigateToTab?.call(5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // 오른쪽 미팅 일정 & 녹음 카드 (index = 2)
                  AnimatedCard(
                    index: 2,
                    selectedIndex: _selectedCardIndex,
                    onTap: () => setState(() => _selectedCardIndex = 2),
                    targetCenter: widget.targetCenter,
                    child: SizedBox(
                      width: cardW + 80,
                      height: w * 0.4 - 10,
                      child: _buildCardContainer(
                        title: '미팅 일정 & 녹음',
                        icon: 'calendar_icon',
                        iconSize: 29,
                        child: MeetingCalendarCard(groupId: widget.groupId),
                      ),
                    ),
                    onCompleted: () => widget.onNavigateToTab?.call(2),
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
          Row(children: [
            Image.asset('assets/images/$icon.png', width: iconSize),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          child, // 원래 크기 그대로
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String icon,
    required double iconSize,
  }) {
    return Container(
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
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }


  Widget _buildTaskCard() {
    final width = MediaQuery.of(context).size.width;
    final title = upcomingTask?['title'];
    final subtitle = upcomingTask?['subtitle'];
    final deadlineStr = upcomingTask?['deadline'];
    String dDay = '';
    if (deadlineStr != null) {
      final dl = DateTime.tryParse(deadlineStr);
      if (dl != null) {
        final diff = DateTime(dl.year, dl.month, dl.day).difference(DateTime.now()).inDays;
        dDay = 'D-${diff >= 0 ? diff : 0}';
      }
    }

    return Container(
      width: width * 0.30 + 47,
      height: 105,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Image.asset('assets/images/homework_icon.png', width: 36),
          const SizedBox(width: 10),
          const Text('과제 관리', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Text(
              (title == null || subtitle == null)
                  ? '제출하지 않은 과제가 없습니다.'
                  : '$title  -  $subtitle',
              style: const TextStyle(fontSize: 15),
            ),
          ),
          if (dDay.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5F7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(dDay, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
        ]),
      ]),
    );
  }
}