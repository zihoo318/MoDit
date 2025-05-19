import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'flask_api.dart';

import 'dart:async'; // 꼭 필요!
import 'package:just_audio/just_audio.dart';

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
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _nameController = TextEditingController();
  final db = FirebaseDatabase.instance.ref();

  List<Map<String, dynamic>> recordings = [];
  bool isRecording = false;
  bool _isPlaying = false; // ✅ 추가
  StreamSubscription? _progressSubscription; // 추가
  Duration recordDuration = Duration.zero;
  String? recordedFilePath;
  int? _playingIndex;
  String? _selectedTextUrl;
  Future<Map<String, dynamic>?>? _summaryFuture; // 요약 요청 Future를 저장
  Future<http.Response>? _summaryTextFuture; // 요약 텍스트용 캐시 Future
  String? _cachedTextUrl;
  Future<http.Response>? _textFuture;
  String? _cachedSummaryUrl;


  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _loadRecordings();
  }


  @override
  void dispose() {
    _progressSubscription?.cancel();
    _player.dispose(); // just_audio는 dispose()
    _nameController.dispose();
    super.dispose();
  }


  Future<int> getDurationMs(String filePath) async {
    final player = AudioPlayer();
    try {
      await player.setFilePath(filePath);
      final duration = player.duration;
      return duration?.inMilliseconds ?? 0;
    } finally {
      await player.dispose();
    }
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
            'timestamp': DateTime.tryParse(value['timestamp'] ?? '') ??
                DateTime.now(),
            'url': value['url'] ?? '',
            'text_url': value['text_url'] ?? '',
            'duration_ms': value['duration_ms'] ?? 0,
          };
        }).toList();
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inHours}:$minutes:$seconds';
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) return;

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/record_${DateTime
        .now()
        .millisecondsSinceEpoch}.m4a';
    recordedFilePath = filePath;

    await _recorder.openRecorder();
    await _recorder.startRecorder(toFile: filePath, codec: Codec.aacMP4);

    setState(() {
      isRecording = true;
      recordDuration = Duration.zero;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future.delayed(const Duration(seconds: 1), () {
              if (isRecording) {
                setState(() => recordDuration += const Duration(seconds: 1));
                setDialogState(() {});
              }
            });

            return AlertDialog(
              backgroundColor: const Color(0xFFF1ECFA),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Column(
                children: [
                  const Icon(Icons.mic, size: 40, color: Color(0xFF9F8DF1)),
                  const SizedBox(height: 8),
                  Text(_formatDuration(recordDuration),
                      style: const TextStyle(fontSize: 24)),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    setState(() => isRecording = false);
                    Navigator.pop(context);
                    _showSaveDialog();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE1D9F8)),
                  child: const Text('Stop'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            backgroundColor: const Color(0xFFF1ECFA),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('녹음 이름을 저장해주세요.'),
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

    final name = _nameController.text
        .trim()
        .isEmpty
        ? 'record_${DateTime
        .now()
        .millisecondsSinceEpoch}'
        : _nameController.text.trim();

    final api = Api();
    final result = await api.uploadVoiceFile(file, widget.groupId);

    if (result != null && result.containsKey('audio_url') &&
        result.containsKey('text_url')) {
      final uploadedUrl = result['audio_url'];
      final textUrl = result['text_url'];

      final newRef = db.child(
          'groupStudies/${widget.groupId}/recordings/${widget.meetingId}')
          .push();
      // duration 추정
      final durMs = await getDurationMs(file.path);

      await newRef.set({
        'name': name,
        'timestamp': DateTime.now().toIso8601String(),
        'url': uploadedUrl,
        'text_url': textUrl,
        'duration_ms': durMs,
      });


      setState(() {
        recordings.add({
          'name': name,
          'timestamp': DateTime.now(),
          'url': uploadedUrl,
          'text_url': textUrl,
          'duration_ms': durMs, // 추가
        });
      });

      await file.delete();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("녹음 파일 업로드에 실패했습니다.")),
      );
    }

    _nameController.clear();
  }

  void _showRecordPrompt() {
    showDialog(
      context: context,
      builder: (_) =>
          AlertDialog(
            backgroundColor: const Color(0xFFF1ECFA),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('녹음을 하시겠습니까?', textAlign: TextAlign.center),
                SizedBox(height: 12),
                Icon(Icons.mic, size: 36, color: Color(0xFF9F8DF1)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context),
                  child: const Text('No')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startRecording();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE1D9F8)),
                child: const Text('Start'),
              ),
            ],
          ),
    );
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
              const Text("미팅 일정 & 녹음",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1ECFA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(dateStr, style: const TextStyle(fontSize: 24)),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(
                        Icons.mic, size: 48, color: Color(0xFF9F8DF1)),
                    onPressed: _showRecordPrompt,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8BDF1).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: ListView.builder(
                    itemCount: recordings.length,
                    itemBuilder: (context, index) {
                      final r = recordings[index];
                      return Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.mic),
                              title: Text(r['name']),
                              subtitle: Text(
                                  DateFormat('yyyy.MM.dd HH:mm:ss').format(
                                      r['timestamp'])),
                              trailing: IconButton(
                                icon: Icon(
                                  _playingIndex == index && _isPlaying ? Icons
                                      .stop : Icons.play_arrow,
                                ),
                                onPressed: () async {
                                  if (_isPlaying) {
                                    await _player.stop();
                                    await _progressSubscription?.cancel();
                                    setState(() {
                                      _isPlaying = false;
                                      _playingIndex = null;
                                      _currentPosition = Duration.zero;
                                      _totalDuration = Duration.zero;
                                    });
                                    return;
                                  }

                                  await _progressSubscription?.cancel();
                                  await _player.setUrl(r['url']);
                                  await _player.play();

                                  _progressSubscription =
                                      _player.positionStream.listen((position) {
                                        if (!mounted) return;
                                        setState(() {
                                          _currentPosition = position;
                                        });
                                      });

                                  _player.durationStream.listen((duration) {
                                    if (duration != null && mounted) {
                                      setState(() {
                                        _totalDuration = duration;
                                      });
                                    }
                                  });

                                  setState(() {
                                    _isPlaying = true;
                                    _playingIndex = index;
                                  });
                                },
                              ),
                              onTap: () {
                                if (r.containsKey('text_url')) {
                                  final textUrl = r['text_url'];
                                  if (_cachedTextUrl != textUrl) {
                                    _cachedTextUrl = textUrl;
                                    _textFuture = http.get(Uri.parse(textUrl));
                                  }

                                  if (_cachedSummaryUrl != textUrl) {
                                    _cachedSummaryUrl = textUrl;
                                    _summaryFuture = Api().requestSummary(textUrl, widget.groupId);
                                    _summaryTextFuture = null; // 새로 받을 준비
                                  }

                                  setState(() {
                                    _selectedTextUrl = textUrl;
                                  });
                                }
                              },
                            ),
                            if (_playingIndex == index && _isPlaying)
                              Column(
                                children: [
                                  Slider(
                                    value: _currentPosition.inMilliseconds
                                        .clamp(0, _totalDuration.inMilliseconds)
                                        .toDouble(),
                                    max: _totalDuration.inMilliseconds
                                        .toDouble().clamp(1.0, double.infinity),
                                    onChanged: (value) {
                                      final newPosition = Duration(
                                          milliseconds: value.toInt());
                                      _player.seek(newPosition);
                                    },
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .spaceBetween,
                                      children: [
                                        Text(_formatDuration(_currentPosition)),
                                        Text(_formatDuration(_totalDuration)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1ECFA),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _selectedTextUrl == null
                      ? const Center(child: Text("녹음을 선택해주세요."))
                      : DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          labelColor: Color(0xFF5C4DB1),
                          unselectedLabelColor: Colors.grey,
                          tabs: [
                            Tab(text: "전체 텍스트"),
                            Tab(text: "요약본"),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              FutureBuilder<http.Response>(
                                future: _textFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  } else if (!snapshot.hasData ||
                                      snapshot.data!.statusCode != 200) {
                                    return const Text("전체 텍스트를 불러오는 데 실패했습니다.");
                                  } else {
                                    return SingleChildScrollView(
                                      child: Text(snapshot.data!.body,
                                          style: const TextStyle(fontSize: 14)),
                                    );
                                  }
                                },
                              ),
                              FutureBuilder<Map<String, dynamic>?>(
                                future: _summaryFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  } else if (!snapshot.hasData || snapshot.data!['summary_url'] == null) {
                                    return const Text("요약본을 불러오는 데 실패했습니다.");
                                  } else {
                                    final summaryUrl = snapshot.data!['summary_url'];
                                    return FutureBuilder<Map<String, dynamic>?>(
                                      future: _summaryFuture,
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        } else if (!snapshot.hasData || snapshot.data!['summary_url'] == null) {
                                          return const Text("요약본을 불러오는 데 실패했습니다.");
                                        } else {
                                          final summaryUrl = snapshot.data!['summary_url'];

                                          // ✅ 캐싱된 요약 텍스트 Future가 없을 때만 생성
                                          _summaryTextFuture ??= http.get(Uri.parse(summaryUrl));

                                          return FutureBuilder<http.Response>(
                                            future: _summaryTextFuture,
                                            builder: (context, summarySnapshot) {
                                              if (summarySnapshot.connectionState == ConnectionState.waiting) {
                                                return const Center(child: CircularProgressIndicator());
                                              } else if (!summarySnapshot.hasData || summarySnapshot.data!.statusCode != 200) {
                                                return const Text("요약본 텍스트를 불러오는 데 실패했습니다.");
                                              } else {
                                                return SingleChildScrollView(
                                                  child: Text(
                                                    summarySnapshot.data!.body,
                                                    style: const TextStyle(fontSize: 14),
                                                  ),
                                                );
                                              }
                                            },
                                          );
                                        }
                                      },
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}