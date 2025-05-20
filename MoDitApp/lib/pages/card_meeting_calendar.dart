import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';

class MeetingCalendarCard extends StatefulWidget {
  final String groupId; // ✅ 그룹 ID 추가

  const MeetingCalendarCard({super.key, required this.groupId});

  @override
  State<MeetingCalendarCard> createState() => _MeetingCalendarCardState();
}

class _MeetingCalendarCardState extends State<MeetingCalendarCard> {
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final db = FirebaseDatabase.instance.ref();
  late Map<DateTime, List<String>> eventMap;

  @override
  void initState() {
    super.initState();
    eventMap = {};
    _listenGroupMeetingEvents();
  }

  void _listenGroupMeetingEvents() {
    db.child('groupStudies/${widget.groupId}/meeting').onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;

      final meetings = Map<String, dynamic>.from(data as Map);
      final newEventMap = <DateTime, List<String>>{};

      for (final entry in meetings.entries) {
        final meeting = Map<String, dynamic>.from(entry.value);

        final rawTitle = meeting['title']?.toString().trim();
        final hasValidTitle = rawTitle != null && rawTitle.isNotEmpty;

        if (hasValidTitle && meeting['date'] != null) {
          final parsedDate = DateTime.tryParse(meeting['date']);
          if (parsedDate != null) {
            final normalizedDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
            newEventMap.putIfAbsent(normalizedDay, () => []).add(rawTitle);
          }
        }
      }

      newEventMap.removeWhere((_, v) => v.isEmpty);

      setState(() {
        eventMap = newEventMap;
      });
    });
  }

  List<String> getEventsForDay(DateTime day) {
    final events = eventMap[DateTime(day.year, day.month, day.day)] ?? [];
    return List.from(events);
  }

  @override
  Widget build(BuildContext context) {
    final events = getEventsForDay(selectedDate);
    final double baseHeight = (events.length * 48.0).clamp(60.0, 240.0);
    final double listHeight = _calendarFormat == CalendarFormat.month
        ? baseHeight * 0.5
        : baseHeight;

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
            key: ValueKey("${eventMap.hashCode}-${DateTime.now().millisecondsSinceEpoch}"),
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
              formatButtonTextStyle: TextStyle(fontSize: 14),
              formatButtonDecoration: BoxDecoration(
                border: Border.all(color: Colors.black26),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 6),
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
