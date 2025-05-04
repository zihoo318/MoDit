import 'package:flutter/material.dart';

class ChattingScreen extends StatefulWidget {
  const ChattingScreen({super.key});

  @override
  State<ChattingScreen> createState() => _ChattingScreenState();
}

class _ChattingScreenState extends State<ChattingScreen> {
  final List<_ChatBubble> _messages = [
    const _ChatBubble("뭐해? 공부하자 지금", Color(0xCC4C92D7)),
    const _ChatBubble("나 밥 먹고 시작하게 같이 ㄱ?", Color(0x996495ED), alignRight: true),
    const _ChatBubble("ㅋㅋㅋ 할거 쌍많다 드가", Color(0xCC4C92D7)),
    const _ChatBubble("알겠어 밥먹고 연락함", Color(0x996495ED), alignRight: true),
  ];

  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatBubble(_controller.text.trim(), const Color(0x996495ED), alignRight: true));
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ 배경
          Positioned.fill(
            child: Image.asset(
              'assets/images/background1.png',
              fit: BoxFit.cover,
            ),
          ),
          // ✅ 오른쪽 상단의 user_icon만 따로 배치
          const Positioned(
            top: 20,
            right: 20,
            child: Image(
              image: AssetImage('assets/images/user_icon.png'),
              width: 50,
            ),
          ),
          // ✅ 나머지 채팅 UI
          Column(
            children: [
              const SizedBox(height: 45), // 상단 여백
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(width: 30),
                    Container(
                      width: 300,
                      height: 650,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEDFF),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          _UserCircle("가을", Color(0xFF4C92D7)),
                          SizedBox(height: 16),
                          _UserCircle("윤지", Color(0xFF6495ED)),
                          SizedBox(height: 16),
                          _UserCircle("유진", Color(0xFF7DB5EB)),
                          SizedBox(height: 16),
                          _UserCircle("지후", Color(0xFF7DB5EB)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.asset('assets/images/user_icon.png', width: 50),
                                const SizedBox(width: 8),
                                const Text(
                                  "조유진",
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1B178F),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Image.asset('assets/images/hand_icon.png', width: 32),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.only(top: 16),
                                children: _messages,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 700),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: const Color(0xB3DBEDFF),
                                      border: Border.all(color: Color(0xFF1B178F), width: 3),
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: TextField(
                                      controller: _controller,
                                      decoration: const InputDecoration(
                                        hintText: "메시지를 입력하세요...",
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _sendMessage,
                                  child: Container(
                                    height: 70,
                                    width: 90,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0x996495ED),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: const Text(
                                      "전송",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserCircle extends StatelessWidget {
  final String name;
  final Color color;

  const _UserCircle(this.name, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String message;
  final Color color;
  final bool alignRight;

  const _ChatBubble(this.message, this.color, {this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          message,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
