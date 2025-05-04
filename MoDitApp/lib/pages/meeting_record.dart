import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class MeetingRecordPage extends StatefulWidget {
  final String date;
  final String meetingId;

  const MeetingRecordPage({Key? key, required this.date, required this.meetingId}) : super(key: key);

  @override
  State<MeetingRecordPage> createState() => _MeetingRecordPageState();
}

class _MeetingRecordPageState extends State<MeetingRecordPage> {
  bool showRecordingPopup = false;
  bool isRecording = false;
  bool showNameInputPopup = false;
  String noteName = '';
  Duration elapsed = Duration.zero;
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker((elapsedTime) {
      if (isRecording) {
        setState(() {
          elapsed = elapsedTime;
        });
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void startRecording() {
    setState(() {
      showRecordingPopup = false;
      isRecording = true;
      elapsed = Duration.zero;
    });
    _ticker.start();
  }

  void stopRecording() {
    _ticker.stop();
    setState(() {
      isRecording = false;
      showNameInputPopup = true;
    });
  }

  void saveNoteToFirebase() {
    final recordRef = FirebaseDatabase.instance
        .ref('meetings/${widget.meetingId}/records')
        .push();

    recordRef.set({
      'name': noteName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background1.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(widget.date, style: const TextStyle(fontSize: 18)),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Image.asset('assets/images/meetingplan_icon.png', width: 24),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Image.asset('assets/images/microphone_icon.png', width: 24),
                            onPressed: () {
                              setState(() {
                                showRecordingPopup = true;
                              });
                            },
                          ),
                          const SizedBox(width: 10),
                          Text("MoDit", style: TextStyle(color: Colors.blue[800], fontSize: 16)),
                          const SizedBox(width: 4),
                          Image.asset('assets/images/user_icon.png', width: 24),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "새 노트",
                        border: UnderlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<DatabaseEvent>(
                      stream: FirebaseDatabase.instance
                          .ref('meetings/${widget.meetingId}/records')
                          .onValue,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                          return const Center(child: Text('저장된 녹음이 없습니다.'));
                        }

                        final Map<dynamic, dynamic> recordsMap =
                            snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

                        final records = recordsMap.entries.map((e) {
                          final value = Map<String, dynamic>.from(e.value);
                          return {
                            'name': value['name'],
                            'timestamp': value['timestamp'],
                          };
                        }).toList();

                        return ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            final record = records[index];
                            return ListTile(
                              title: Text(record['name']),
                              subtitle: Text(record['timestamp']),
                              leading: const Icon(Icons.mic),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (showRecordingPopup)
            Center(
              child: _buildPopup(
                content: Column(
                  children: [
                    const Text("녹음을 하시겠습니까?"),
                    const SizedBox(height: 8),
                    Image.asset('assets/images/microphone_icon.png', width: 32),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _popupButton("Start", () => startRecording()),
                        _popupButton("No", () {
                          setState(() {
                            showRecordingPopup = false;
                          });
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (isRecording)
            Center(
              child: _buildPopup(
                content: Column(
                  children: [
                    Image.asset('assets/images/microphone_icon.png', width: 32),
                    const SizedBox(height: 8),
                    Text(formatDuration(elapsed), style: const TextStyle(fontSize: 18)),
                    const SizedBox(height: 8),
                    _popupButton("Stop", () => stopRecording()),
                  ],
                ),
              ),
            ),

          if (showNameInputPopup)
            Center(
              child: _buildPopup(
                content: Column(
                  children: [
                    const Text("노트 이름을 저장해주세요."),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (val) => noteName = val,
                        decoration: const InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _popupButton("저장", () {
                      saveNoteToFirebase();
                      setState(() {
                        showNameInputPopup = false;
                      });
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPopup({required Widget content}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 250, // 👈 팝업 최대 높이 지정
          minHeight: 100,
        ),
        padding: const EdgeInsets.all(16),
        width: 240,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(child: content), // 👈 스크롤 가능하도록
      ),
    );
  }

  Widget _popupButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade200,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

class Ticker {
  final void Function(Duration elapsed) callback;
  Duration _elapsed = Duration.zero;
  bool _active = false;

  Ticker(this.callback);

  void start() {
    _active = true;
    _tick();
  }

  void stop() {
    _active = false;
  }

  void _tick() async {
    final start = DateTime.now();
    while (_active) {
      await Future.delayed(const Duration(seconds: 1));
      _elapsed = DateTime.now().difference(start);
      callback(_elapsed);
    }
  }

  void dispose() {
    _active = false;
  }
}
