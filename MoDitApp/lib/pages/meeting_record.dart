import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MeetingRecordWidget extends StatefulWidget {
  final DateTime selectedDate;
  final String groupId;
  final String meetingId;

  const MeetingRecordWidget({
    super.key,
    required this.selectedDate,
    required this.groupId,
    required this.meetingId,
  });

  @override
  State<MeetingRecordWidget> createState() => _MeetingRecordWidgetState();
}

class _MeetingRecordWidgetState extends State<MeetingRecordWidget> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final TextEditingController _nameController = TextEditingController();
  final db = FirebaseDatabase.instance.ref();

  List<Map<String, dynamic>> recordings = [];
  bool isRecording = false;
  Duration recordDuration = Duration.zero;
  String? recordedFilePath;

  @override
  void initState() {
    super.initState();
    _player.openPlayer();
    _loadRecordings();
  }

  @override
  void dispose() {
    _player.closePlayer();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadRecordings() async {
    final snapshot = await db
        .child('groupStudies/${widget.groupId}/recordings/${widget.meetingId}')
        .get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        recordings = data.entries.map((entry) {
          final value = Map<String, dynamic>.from(entry.value);
          return {
            'name': value['name'] ?? '이름 없음',
            'timestamp': DateTime.tryParse(value['timestamp'] ?? '') ?? DateTime.now(),
            'url': value['url'] ?? '',
          };
        }).toList();
      });
    }
  }

  void _showRecordPrompt() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF1ECFA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('녹음을 하시겠습니까?', textAlign: TextAlign.center),
            SizedBox(height: 12),
            Icon(Icons.mic, size: 36, color: Color(0xFF9F8DF1)),
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

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/record_${DateTime.now().millisecondsSinceEpoch}.aac';
    recordedFilePath = filePath;

    await _recorder.openRecorder();
    await _recorder.startRecorder(toFile: filePath, codec: Codec.aacADTS);

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
              _stopRecordingAndSave();
              Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _stopRecordingAndSave() async {
    await _recorder.stopRecorder();
    await _recorder.closeRecorder();
    setState(() => isRecording = false);

    if (recordedFilePath == null) return;

    final file = File(recordedFilePath!);
    if (!file.existsSync()) return;

    final name = _nameController.text.trim().isEmpty
        ? 'record_${DateTime.now().millisecondsSinceEpoch}'
        : _nameController.text.trim();

    final fakeUrl = 'file://${file.path}';

    final newRef = db.child('groupStudies/${widget.groupId}/recordings/${widget.meetingId}').push();
    await newRef.set({
      'name': name,
      'timestamp': DateTime.now().toIso8601String(),
      'url': fakeUrl,
    });

    setState(() {
      recordings.add({
        'name': name,
        'timestamp': DateTime.now(),
        'url': fakeUrl,
      });
    });

    _nameController.clear();
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
                    title: Text(r['name']),
                    subtitle: Text(DateFormat('yyyy.MM.dd HH:mm:ss').format(r['timestamp'])),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => launchUrl(Uri.parse(r['url'])),
                    ),
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
