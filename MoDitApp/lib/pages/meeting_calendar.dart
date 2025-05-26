import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http; // ✅ 추가
import 'dart:convert'; // ✅ 추가
import 'flask_api.dart';


class MeetingCalendarWidget extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;
  final void Function(DateTime, String) onRecordDateSelected;

  const MeetingCalendarWidget({
    super.key,
    required this.groupId,
    required this.currentUserEmail,
    required this.onRecordDateSelected,
  });

  @override
  State<MeetingCalendarWidget> createState() => _MeetingCalendarWidgetState();
}

class _MeetingCalendarWidgetState extends State<MeetingCalendarWidget> {
  final db = FirebaseDatabase.instance.ref();
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<Map<String, dynamic>> meetings = [];

  late StreamSubscription<DatabaseEvent> _meetingSubscription;

  @override
  void initState() {
    super.initState();
    _loadMeetings();

    // 실시간 리스너 등록
    _meetingSubscription = db.child('groupStudies/${widget.groupId}/meeting').onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final List<Map<String, dynamic>> loaded = [];
        for (final entry in data.entries) {
          final value = Map<String, dynamic>.from(entry.value);
          final date = DateTime.tryParse(value['date'] ?? '');
          if (date != null) {
            loaded.add({...value, 'date': date, 'id': entry.key});
          }
        }
        setState(() {
          meetings = loaded;
        });
      } else {
        setState(() {
          meetings = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _meetingSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadMeetings() async {
    final snapshot = await db.child('groupStudies/${widget.groupId}/meeting').get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final List<Map<String, dynamic>> loaded = [];

      for (final entry in data.entries) {
        final value = Map<String, dynamic>.from(entry.value);
        final date = DateTime.tryParse(value['date'] ?? '');
        if (date != null) {
          loaded.add({...value, 'date': date, 'id': entry.key});
        }
      }

      setState(() {
        meetings = loaded;
      });
    }
  }

  List<Map<String, dynamic>> getMeetingsForDay(DateTime day) {
    return meetings.where((m) => isSameDay(m['date'], day)).toList();
  }

  void _confirmDelete(Map<String, dynamic> meeting) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '삭제 확인',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D0A64),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 1, color: Color(0xFF0D0A64)),
                  const SizedBox(height: 16),
                  const Text(
                    '이 미팅을 삭제하시겠습니까?',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                          foregroundColor: const Color(0xFF0D0A64),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton( // ElevatedButton → OutlinedButton 으로 변경
                        onPressed: () async {
                          await db.child('groupStudies/${widget.groupId}/meeting/${meeting['id']}').remove();
                          setState(() => meetings.removeWhere((m) => m['id'] == meeting['id']));
                          Navigator.pop(context); // 삭제 확인 팝업 닫기
                          Navigator.pop(context); // 미팅 일정 수정 팝업도 닫기
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          foregroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }


  void _showEditDialog(Map<String, dynamic> meeting) {
    final titleController = TextEditingController(text: meeting['title']);
    final locationController = TextEditingController(text: meeting['location']);
    final membersController = TextEditingController(text: (meeting['members'] as List).join(', '));
    DateTime pickedDate = meeting['date'];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 450,
                  maxHeight: 480,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📅 미팅 일정 수정',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D0A64),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(thickness: 1, color: Color(0xFF0D0A64)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              TextButton(
                                onPressed: () async {
                                  final newDate = await showDatePicker(
                                    context: context,
                                    initialDate: pickedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2030),
                                    builder: (context, child) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        child: Container(width: 500, child: child),
                                      );
                                    },
                                  );
                                  if (newDate != null) {
                                    setState(() => pickedDate = newDate);
                                  }
                                },
                                child: Text(
                                  DateFormat('yyyy.MM.dd').format(pickedDate),
                                  style: const TextStyle(
                                    fontSize: 21,
                                    color: Color(0xFF0D0A64),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: titleController,
                                decoration: const InputDecoration(
                                  labelText: '미팅 주제',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: locationController,
                                decoration: const InputDecoration(
                                  labelText: '장소',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: membersController,
                                decoration: const InputDecoration(
                                  labelText: '참여자 (쉼표로 구분)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => _confirmDelete(meeting),
                            child: const Text('삭제', style: TextStyle(color: Colors.red)),
                          ),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                                  foregroundColor: const Color(0xFF0D0A64),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('취소'),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () async {
                                  final updated = {
                                    'title': titleController.text,
                                    'location': locationController.text,
                                    'members': membersController.text
                                        .split(',')
                                        .map((e) => e.trim())
                                        .toList(),
                                    'date': DateFormat('yyyy-MM-dd').format(pickedDate),
                                  };
                                  await db
                                      .child('groupStudies/${widget.groupId}/meeting/${meeting['id']}')
                                      .update(updated);

                                  setState(() {
                                    final index = meetings.indexWhere((m) => m['id'] == meeting['id']);
                                    if (index != -1) {
                                      meetings[index] = {...updated, 'date': pickedDate, 'id': meeting['id']};
                                    }
                                  });

                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                                  foregroundColor: const Color(0xFF0D0A64),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('수정'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  void showAddMeetingDialog() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null) return;

    final participantsController = TextEditingController();
    final locationController = TextEditingController();
    final topicController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 450,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '📅 미팅 일정 추가',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0D0A64)),
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          DateFormat('yyyy.MM.dd').format(pickedDate),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: participantsController,
                        decoration: const InputDecoration(
                          labelText: '참여자 (쉼표로 구분)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: '장소',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: topicController,
                        decoration: const InputDecoration(
                          labelText: '미팅 주제',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                              foregroundColor: const Color(0xFF0D0A64),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("취소"),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              final newMeeting = {
                                'date': DateFormat('yyyy-MM-dd').format(pickedDate),
                                'title': topicController.text,
                                'members': participantsController.text.split(',').map((e) => e.trim()).toList(),
                                'location': locationController.text,
                                'createdAt': ServerValue.timestamp,
                              };

                              final ref = db.child('groupStudies/${widget.groupId}/meeting').push();
                              await ref.set(newMeeting);


                              // ✅ Firebase에 알림 데이터 저장
                              final membersSnapshot = await db.child('groupStudies/${widget.groupId}/members').get();
                              final groupNameSnapshot = await db.child('groupStudies/${widget.groupId}/name').get();

                              if (membersSnapshot.exists && groupNameSnapshot.exists) {
                                final groupName = groupNameSnapshot.value.toString();
                                final members = Map<String, dynamic>.from(membersSnapshot.value as Map);

                                for (final emailKey in members.keys) {
                                  final pushRef = db.child('user/$emailKey/push').push();
                                  await pushRef.set({
                                    'category': 'meeting',
                                    'timestamp': ServerValue.timestamp,
                                    'groupId': widget.groupId,
                                    'message': '[$groupName]에 새로운 미팅이 등록되었습니다. (${DateFormat('yyyy.MM.dd').format(pickedDate)})',
                                  });
                                }

                                // Flask 서버로 알림 푸시 요청
                                await http.post(
                                  Uri.parse('${Api.baseUrl}/send_meeting_alert'),
                                  headers: {"Content-Type": "application/json"},
                                  body: jsonEncode({
                                    "groupId": widget.groupId,
                                    "date": DateFormat('yyyy.MM.dd').format(pickedDate),
                                    "senderEmail": widget.currentUserEmail, // 추가
                                  }),
                                );
                              }

                              if (mounted) {
                                setState(() {
                                  meetings.add({...newMeeting, 'date': pickedDate, 'id': ref.key});
                                  selectedDate = pickedDate;
                                  focusedDate = pickedDate;
                                });
                              }

                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                              foregroundColor: const Color(0xFF0D0A64),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("등록"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meetingsForDay = getMeetingsForDay(selectedDate);

    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildCalendar(),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFB8BDF1).withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Scrollbar(
              child: ListView.builder(
                itemCount: meetingsForDay.length,
                itemBuilder: (context, index) {
                  final meeting = meetingsForDay[index];
                  return GestureDetector(
                    onTap: () => widget.onRecordDateSelected(meeting['date'], meeting['id']),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMeetingCard(meeting)
                          .animate(delay: Duration(milliseconds: index * 80)) // ✅ 여기서 delay 직접 전달
                          .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut)
                          .fadeIn(duration: 300.ms),
                    ),
                  );
                },
              ),
            ),


          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("미팅 일정 & 녹음", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Text(DateFormat('yyyy.MM').format(focusedDate), style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: showAddMeetingDialog,
              child: Row(
                children: const [
                  Text("미팅 일정 추가", style: TextStyle(fontSize: 16, color: Color(0xFF6C79FF))),
                  SizedBox(width: 6),
                  Icon(Icons.add_circle, color: Color(0xFF6C79FF)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDate,
        selectedDayPredicate: (day) => isSameDay(selectedDate, day),
        calendarFormat: _calendarFormat,
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        availableCalendarFormats: const {
          CalendarFormat.month: '월',
          CalendarFormat.twoWeeks: '2주',
          CalendarFormat.week: '주',
        },
        onDaySelected: (selected, focused) => setState(() {
          selectedDate = selected;
          focusedDate = focused;
        }),
        eventLoader: getMeetingsForDay,
        calendarStyle: const CalendarStyle(
          markerDecoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meeting['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text((meeting['members'] as List<dynamic>).join(', ')),
                if (meeting['location'] != null)
                  Text("장소: ${meeting['location']}"),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              _showEditDialog(meeting);
            },
            child: const Text(
              '수정',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF0D0A64),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}