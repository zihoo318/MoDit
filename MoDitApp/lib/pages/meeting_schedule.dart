import 'package:flutter/material.dart';

class MeetingSchedulePage extends StatelessWidget {
  const MeetingSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background1.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 제목 + 아이콘
                  Row(
                    children: [
                      const Icon(Icons.arrow_back),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '미팅 일정',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Text(
                        'MoDit',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.account_circle_outlined),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 일정 리스트
                  Expanded(
                    child: ListView(
                      children: [
                        _buildScheduleItem(
                          date: '2025. 04. 25.',
                          location: '한성대학교 상상관',
                          participants: ['가을', '윤지', '유진'],
                          topic: '피그마 UI 회의',
                        ),
                        const SizedBox(height: 16),
                        _buildScheduleItem(
                          date: '2025. 04. 20.',
                          location: '한성대학교 상상관',
                          participants: ['윤지', '유진', '지후'],
                          topic: '주제 선정',
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Image.asset(
                        'assets/images/calendar_icon.png',
                        width: 40,
                        height: 40,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem({
    required String date,
    required String location,
    required List<String> participants,
    required String topic,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('assets/images/location_icon.png', width: 20),
                  const SizedBox(width: 8),
                  Text(location),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: participants
                    .map(
                      (name) => Chip(
                    label: Text(name),
                    backgroundColor: Colors.blue.shade200,
                    labelStyle: const TextStyle(color: Colors.white),
                  ),
                )
                    .toList(),
              ),
              const SizedBox(height: 8),
              Text(
                topic,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
