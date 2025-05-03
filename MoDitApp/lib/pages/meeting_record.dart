import 'package:flutter/material.dart';

class MeetingRecordPage extends StatefulWidget {
  const MeetingRecordPage({Key? key}) : super(key: key);

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

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background1.png'),
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
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("2025. 04. 25.", style: TextStyle(fontSize: 18)),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Image.asset('assets/meetingplan_icon.png', width: 24),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Image.asset('assets/microphone_icon.png', width: 24),
                            onPressed: () {
                              setState(() {
                                showRecordingPopup = true;
                              });
                            },
                          ),
                          const SizedBox(width: 10),
                          Text("MoDit", style: TextStyle(color: Colors.blue[800], fontSize: 16)),
                          const SizedBox(width: 4),
                          Image.asset('assets/user_icon.png', width: 24),
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
                ],
              ),
            ),
          ),
        ),

        // 녹음 시작 여부 팝업
        if (showRecordingPopup)
          Center(
            child: _buildPopup(
              content: Column(
                children: [
                  const Text("녹음을 하시겠습니까?"),
                  const SizedBox(height: 8),
                  Image.asset('assets/microphone_icon.png', width: 32),
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

        // 녹음 중 팝업
        if (isRecording)
          Center(
            child: _buildPopup(
              content: Column(
                children: [
                  Image.asset('assets/microphone_icon.png', width: 32),
                  const SizedBox(height: 8),
                  Text(formatDuration(elapsed), style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  _popupButton("Stop", () => stopRecording()),
                ],
              ),
            ),
          ),

        // 노트 이름 저장 팝업
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
                    setState(() {
                      showNameInputPopup = false;
                    });
                    // 여기서 노트 저장 처리 가능
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPopup({required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: 220,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: content,
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
