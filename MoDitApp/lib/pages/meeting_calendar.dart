// meeting_calendar.dart (clickable meeting cards)
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'package:table_calendar/table_calendar.dart';
import 'meeting_record.dart';

class MeetingCalendarScreen extends StatefulWidget {
  const MeetingCalendarScreen({super.key});

  @override
  State<MeetingCalendarScreen> createState() => _MeetingCalendarScreenState();
}

class _MeetingCalendarScreenState extends State<MeetingCalendarScreen> {
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();
  final List<Map<String, dynamic>> meetings = [
    {
      'date': DateTime(2025, 5, 6),
      'title': '캡스톤 미팅',
      'members': ['가을', '윤지', '유진', '지후']
    }
  ];

  List<Map<String, dynamic>> getMeetingsForDay(DateTime day) {
    return meetings.where((m) => isSameDay(m['date'], day)).toList();
  }

  void showAddMeetingDialog() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate == null) return;

    final TextEditingController participantsController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    final TextEditingController topicController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('미팅 일정 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DateFormat('yyyy.MM.dd').format(pickedDate)),
            const SizedBox(height: 8),
            TextField(controller: participantsController, decoration: const InputDecoration(hintText: '참여자 (쉼표로 구분)')),
            TextField(controller: locationController, decoration: const InputDecoration(hintText: '장소')),
            TextField(controller: topicController, decoration: const InputDecoration(hintText: '미팅 주제')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                meetings.add({
                  'date': pickedDate,
                  'title': topicController.text,
                  'members': participantsController.text.split(',').map((e) => e.trim()).toList(),
                });
                selectedDate = pickedDate;
                focusedDate = pickedDate;
              });
              Navigator.pop(context);
            },
            child: const Text("등록"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> members = ['가을', '윤지', '유진', '지후'];

    return Scaffold(
      body: Row(
        children: [
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
                children: [
                  _buildTitleBar(),
                  _buildCalendar(),
                  const SizedBox(height: 16),
                  if (getMeetingsForDay(selectedDate).isNotEmpty)
                    ...getMeetingsForDay(selectedDate).map((meeting) => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MeetingRecordScreen(selectedDate: meeting['date']),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildMeetingCard(meeting),
                          ),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("미팅 일정 & 녹음", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  Icon(Icons.add_circle, color: Color(0xFF6C79FF))
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
        onDaySelected: (selected, focused) {
          setState(() {
            selectedDate = selected;
            focusedDate = focused;
          });
        },
        calendarFormat: CalendarFormat.month,
        eventLoader: getMeetingsForDay,
        calendarStyle: const CalendarStyle(
          markerDecoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
        ),
      ),
    );
  }

  Widget _buildMeetingCard(Map<String, dynamic> meeting) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meeting['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(meeting['members'].join(', ')),
          ],
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
