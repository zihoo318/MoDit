// card_meeting_calendar.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MeetingCalendarCard extends StatefulWidget {
  const MeetingCalendarCard({super.key});

  @override
  State<MeetingCalendarCard> createState() => _MeetingCalendarCardState();
}

class _MeetingCalendarCardState extends State<MeetingCalendarCard> {
  DateTime selectedDate = DateTime.now();
  DateTime focusedDate = DateTime.now();

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
        onDaySelected: (selected, focused) {
          setState(() {
            selectedDate = selected;
            focusedDate = focused;
          });
        },
        calendarFormat: CalendarFormat.month,
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
