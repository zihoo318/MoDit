import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_database/firebase_database.dart';

class MeetingCalendarWidget extends StatefulWidget {
  final String groupId;
  final void Function(DateTime) onRecordDateSelected;

  const MeetingCalendarWidget({
    super.key,
    required this.groupId,
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

  @override
  void initState() {
    super.initState();
    _loadMeetings(); // ✅ Firebase에서 미팅 데이터 불러오기
  }

  Future<void> _loadMeetings() async {
    final snapshot =
        await db.child('groupStudies/${widget.groupId}/meeting').get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      final List<Map<String, dynamic>> loadedMeetings = [];
      for (final entry in data.entries) {
        final value = Map<String, dynamic>.from(entry.value);
        final date = DateTime.tryParse(value['date'] ?? '');
        if (date != null) {
          loadedMeetings.add({...value, 'date': date});
        }
      }

      setState(() {
        meetings = loadedMeetings;
      });
    }
  }

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

    final participantsController = TextEditingController();
    final locationController = TextEditingController();
    final topicController = TextEditingController();

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
            TextField(
                controller: participantsController,
                decoration:
                    const InputDecoration(hintText: '참여자 (쉼표로 구분)')),
            TextField(
                controller: locationController,
                decoration: const InputDecoration(hintText: '장소')),
            TextField(
                controller: topicController,
                decoration: const InputDecoration(hintText: '미팅 주제')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("취소")),
          ElevatedButton(
            onPressed: () async {
              final newMeeting = {
                'date': DateFormat('yyyy-MM-dd').format(pickedDate),
                'title': topicController.text,
                'members': participantsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .toList(),
                'location': locationController.text,
                'createdAt': ServerValue.timestamp,
              };

              final meetingRef = db
                  .child('groupStudies/${widget.groupId}/meeting')
                  .push();
              await meetingRef.set(newMeeting);

              setState(() {
                meetings.add({...newMeeting, 'date': pickedDate});
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
                    onTap: () =>
                        widget.onRecordDateSelected(meeting['date']),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMeetingCard(meeting),
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
        const Text("미팅 일정 & 녹음",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Text(DateFormat('yyyy.MM').format(focusedDate),
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: showAddMeetingDialog,
              child: Row(
                children: const [
                  Text("미팅 일정 추가",
                      style: TextStyle(fontSize: 16, color: Color(0xFF6C79FF))),
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
          markerDecoration:
              BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meeting['title'],
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(meeting['members'].join(', ')),
          if (meeting['location'] != null)
            Text("장소: ${meeting['location']}"),
        ],
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
