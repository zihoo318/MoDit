import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';

class MeetingCalendarCard extends StatefulWidget {
  const MeetingCalendarCard({super.key});

  @override
  State<MeetingCalendarCard> createState() => _MeetingCalendarCardState();
}

class _MeetingCalendarCardState extends State<MeetingCalendarCard> {
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();
  final db = FirebaseDatabase.instance.ref();
  final Map<DateTime, List<String>> eventMap = {}; // 날짜별 미팅 제목 목록

  @override
  void initState() {
    super.initState();
    _loadMeetingEvents();
  }

  void _loadMeetingEvents() async {
    final snapshot = await db.child('groupStudies').get();

    if (snapshot.exists) {
      final groupStudies = Map<String, dynamic>.from(snapshot.value as Map);

      for (final groupEntry in groupStudies.entries) {
        final group = groupEntry.value;
        if (group is Map && group.containsKey('meeting')) {
          final meetings = Map<String, dynamic>.from(group['meeting']);
          for (final entry in meetings.entries) {
            final meeting = Map<String, dynamic>.from(entry.value);
            if (meeting['date'] != null) {
              final date = DateTime.tryParse(meeting['date']);
              if (date != null) {
                final day = DateTime(date.year, date.month, date.day);
                eventMap.putIfAbsent(day, () => []).add(meeting['title'] ?? '미팅');
              }
            }
          }
        }
      }

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
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
        calendarFormat: CalendarFormat.month,
        onDaySelected: (selected, focused) {
          setState(() {
            selectedDate = selected;
            focusedDate = focused;
          });
        },
        eventLoader: (day) {
          return eventMap[DateTime(day.year, day.month, day.day)] ?? [];
        },
        calendarStyle: const CalendarStyle(
          markerDecoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
