import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'meeting_record.dart';

class MeetingCalendarScreen extends StatefulWidget {
  const MeetingCalendarScreen({super.key});

  @override
  State<MeetingCalendarScreen> createState() => _MeetingCalendarScreenState();
}

class _MeetingCalendarScreenState extends State<MeetingCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final _database = FirebaseDatabase.instance.ref('meetings');
  Map<String, List<Map<String, dynamic>>> _events = {};
  Map<String, String> _meetingIdMap = {}; // meetingId 저장용

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  void _loadMeetings() {
    _database.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data == null) return;

      final meetings = Map<String, dynamic>.from(data as Map);
      final Map<String, List<Map<String, dynamic>>> eventMap = {};
      final Map<String, String> idMap = {};

      for (var entry in meetings.entries) {
        final meetingId = entry.key;
        final meeting = Map<String, dynamic>.from(entry.value);
        final date = meeting['date'];

        // 저장된 id 맵핑
        meeting['id'] = meetingId;
        if (!eventMap.containsKey(date)) {
          eventMap[date] = [];
        }
        eventMap[date]!.add(meeting);
        idMap[meetingId] = date;
      }

      setState(() {
        _events = eventMap;
        _meetingIdMap = idMap;
      });
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final formatted = DateFormat('yyyy.MM.dd').format(day);
    return _events[formatted] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        SizedBox.expand(
          child: Image.asset('assets/images/background1.png', fit: BoxFit.cover),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('〈 미팅 일정', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Image.asset('assets/images/user_icon.png', width: 30),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Image.asset('assets/images/meetingplan_icon.png', height: 50),
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TableCalendar(
                  locale: 'ko_KR',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) => _getEventsForDay(day),
                  calendarStyle: const CalendarStyle(
                    markerDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    todayDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                    selectedDecoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: _getEventsForDay(_selectedDay ?? _focusedDay).map((event) {
                    return ListTile(
                      title: Text(event['topic'] ?? ''),
                      subtitle: Text(event['location'] ?? ''),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MeetingRecordPage(
                              date: event['date'],
                              meetingId: event['id'],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ]),
    );
  }
}
