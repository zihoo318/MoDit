import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class MeetingCalendarScreen extends StatefulWidget {
  const MeetingCalendarScreen({super.key});

  @override
  State<MeetingCalendarScreen> createState() => _MeetingCalendarScreenState();
}

class _MeetingCalendarScreenState extends State<MeetingCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          SizedBox.expand(
            child: Image.asset(
              'assets/background1.png',
              fit: BoxFit.cover,
            ),
          ),

          // 전체 내용
          SafeArea(
            child: Column(
              children: [
                // 상단 바
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '〈 미팅 일정',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Image.asset('assets/user_icon.png', width: 30),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 중앙 타이틀 아이콘
                Image.asset('assets/meetingplan_icon.png', height: 50),

                const SizedBox(height: 10),

                // 달력 표시
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TableCalendar(
                        locale: 'en_US',
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
                        calendarStyle: const CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                      ),
                    ),
                  ),
                ),

                // 하단 아이콘
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Image.asset('assets/calendar_icon.png', width: 40),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
