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
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final db = FirebaseDatabase.instance.ref();
  final Map<DateTime, List<String>> eventMap = {};

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

  List<String> getEventsForDay(DateTime day) {
    return eventMap[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final events = getEventsForDay(selectedDate);

    // ✅ Month 모드일 경우 더 작은 높이 사용
    final double listHeight = (events.length * 48.0).clamp(60.0, 240.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: focusedDate,
            selectedDayPredicate: (day) => isSameDay(selectedDate, day),
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            onDaySelected: (selected, focused) {
              setState(() {
                selectedDate = selected;
                focusedDate = focused;
              });
            },
            eventLoader: getEventsForDay,
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              formatButtonShowsNext: false,
              formatButtonTextStyle: const TextStyle(fontSize: 14),
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 6), // 🔧 더 여유 줄이기

          if (events.isNotEmpty)
            SizedBox(
              height: listHeight,
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        events[index],
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  },
                ),
              ),
            )

          else
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '해당 날짜에 미팅 일정이 없습니다.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
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
