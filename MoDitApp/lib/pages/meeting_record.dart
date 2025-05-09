// meeting_record.dart with sidebar and top bar
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MeetingRecordScreen extends StatefulWidget {
  final DateTime selectedDate;
  const MeetingRecordScreen({super.key, required this.selectedDate});

  @override
  State<MeetingRecordScreen> createState() => _MeetingRecordScreenState();
}

class _MeetingRecordScreenState extends State<MeetingRecordScreen> {
  List<Map<String, dynamic>> recordings = [];
  bool isRecording = false;
  Duration recordDuration = Duration.zero;
  late final TextEditingController _nameController;

  final List<String> members = ['가을', '윤지', '유진', '지후'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  void _showRecordPrompt() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF1ECFA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('녹음을 하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startRecording();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE1D9F8)),
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _startRecording() {
    setState(() {
      isRecording = true;
      recordDuration = Duration.zero;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future.delayed(const Duration(seconds: 1), () {
            if (isRecording) {
              setState(() => recordDuration += const Duration(seconds: 1));
              setDialogState(() {});
            }
          });

          return AlertDialog(
            backgroundColor: const Color(0xFFF1ECFA),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                const Icon(Icons.mic, size: 40, color: Color(0xFF9F8DF1)),
                Text(_formatDuration(recordDuration), style: const TextStyle(fontSize: 24))
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  setState(() => isRecording = false);
                  Navigator.pop(context);
                  _showSaveDialog();
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE1D9F8)),
                child: const Text('Stop'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF1ECFA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('노트 이름을 저장해주세요.'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(hintText: '예: 회의녹음_1'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              setState(() {
                recordings.add({
                  'name': _nameController.text,
                  'timestamp': DateTime.now(),
                });
                _nameController.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inHours}:$minutes:$seconds';
  }

  Widget _buildSidebar() {
    return Container(
      width: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDCDFFD), Color(0xFFF2DAFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("MoDit", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF9496DB))),
          ),
          _buildSidebarItem(Icons.grid_view_rounded, "메뉴"),
          _buildSidebarItem(Icons.alarm, "공부 시간"),
          _buildSidebarItem(Icons.calendar_month_outlined, "미팅 일정 & 녹음", active: true),
          _buildSidebarItem(Icons.book, "과제 관리"),
          _buildSidebarItem(Icons.announcement, "공지사항"),
          _buildSidebarItem(Icons.chat, "채팅"),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String title, {bool active = false}) {
    return Container(
      color: active ? const Color(0xFFCAD0FF) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: active ? const Color(0xFF6C79FF) : Colors.grey),
        title: Text(title, style: TextStyle(color: active ? const Color(0xFF6C79FF) : Colors.grey)),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Text("그룹스터디이름", style: TextStyle(fontSize: 18)),
          const Spacer(),
          ...members.map((e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Chip(label: Text(e)),
              )),
          const SizedBox(width: 12),
          const CircleAvatar(backgroundColor: Colors.white, radius: 20, child: Icon(Icons.person)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy. MM. dd.').format(widget.selectedDate);

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDCDFFD), Color(0xFFF2DAFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1ECFA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(dateStr, style: const TextStyle(fontSize: 24)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.mic, color: Color(0xFF9F8DF1)),
                        onPressed: _showRecordPrompt,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ListView.builder(
                        itemCount: recordings.length,
                        itemBuilder: (context, index) {
                          final r = recordings[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.mic),
                              title: Text(r['name'] ?? '이름 없음'),
                              subtitle: Text(r['timestamp'].toString()),
                              trailing: const Icon(Icons.download),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
