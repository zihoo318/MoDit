import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MeetingRecordWidget extends StatefulWidget {
  final DateTime selectedDate;
  const MeetingRecordWidget({super.key, required this.selectedDate});

  @override
  State<MeetingRecordWidget> createState() => _MeetingRecordWidgetState();
}

class _MeetingRecordWidgetState extends State<MeetingRecordWidget> {
  List<Map<String, dynamic>> recordings = [];
  bool isRecording = false;
  Duration recordDuration = Duration.zero;
  late final TextEditingController _nameController;

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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('녹음을 하시겠습니까?', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Icon(Icons.mic, size: 36, color: Color(0xFF9F8DF1)),
          ],
        ),
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

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('yyyy. MM. dd.').format(widget.selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔷 상단 텍스트 + 날짜/마이크 중앙 정렬
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("미팅 일정 & 녹음", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1ECFA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(dateStr, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.mic, size: 48, color: Color(0xFF9F8DF1)),
                    onPressed: _showRecordPrompt,
                  ),
                ],
              ),
            ],
          ),
        ),

        // 🔷 녹음 목록
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFB8BDF1).withOpacity(0.3),
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
                    subtitle: Text(DateFormat('yyyy.MM.dd HH:mm:ss').format(r['timestamp'])),
                    trailing: const Icon(Icons.download),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
