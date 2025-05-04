import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class MeetingSchedulePage extends StatefulWidget {
  const MeetingSchedulePage({super.key});

  @override
  State<MeetingSchedulePage> createState() => _MeetingSchedulePageState();
}

class _MeetingSchedulePageState extends State<MeetingSchedulePage> {
  final _database = FirebaseDatabase.instance.ref('meetings');

  void _showAddMeetingDialog() {
    final dateController = TextEditingController();
    final participantsController = TextEditingController();
    final locationController = TextEditingController();
    final topicController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    dateController.text = DateFormat('yyyy.MM.dd').format(selectedDate);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('미팅 일정 추가'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: '날짜 선택'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      selectedDate = picked;
                      dateController.text = DateFormat('yyyy.MM.dd').format(picked);
                    }
                  },
                ),
                TextField(
                  controller: participantsController,
                  decoration: const InputDecoration(
                      labelText: '참여자 (쉼표로 구분)'),
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: '장소'),
                ),
                TextField(
                  controller: topicController,
                  decoration: const InputDecoration(labelText: '미팅 주제'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('등록'),
              onPressed: () async {
                final date = dateController.text;
                final location = locationController.text.trim();
                final topic = topicController.text.trim();
                final participants = participantsController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();

                if (date.isNotEmpty &&
                    location.isNotEmpty &&
                    topic.isNotEmpty &&
                    participants.isNotEmpty) {
                  await _database.push().set({
                    'date': date,
                    'location': location,
                    'participants': participants,
                    'topic': topic,
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경
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
                  // 상단바
                  Row(
                    children: [
                      const Icon(Icons.arrow_back),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today_outlined, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text('미팅 일정',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Text('MoDit',
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      const Icon(Icons.account_circle_outlined),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 실시간 데이터 스트림
                  Expanded(
                    child: StreamBuilder<DatabaseEvent>(
                      stream: _database.onValue,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                          return const Center(child: Text('등록된 일정이 없습니다.'));
                        }

                        final data = Map<String, dynamic>.from(
                          snapshot.data!.snapshot.value as Map,
                        );

                        final items = data.entries.toList()
                          ..sort((a, b) => b.value['date'].compareTo(a.value['date']));

                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index].value;
                            return _buildScheduleItem(
                              date: item['date'],
                              location: item['location'],
                              participants: List<String>.from(item['participants']),
                              topic: item['topic'],
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // 캘린더 이미지 버튼
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 80.0, right: 10.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/calendar');
                        },
                        child: Image.asset(
                          'assets/images/calendar_icon.png',
                          width: 40,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMeetingDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScheduleItem({
    required String date,
    required String location,
    required List<String> participants,
    required String topic,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                      .map((name) => Chip(
                            label: Text(name),
                            backgroundColor: Colors.blue.shade200,
                            labelStyle: const TextStyle(color: Colors.white),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                Text(topic, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
