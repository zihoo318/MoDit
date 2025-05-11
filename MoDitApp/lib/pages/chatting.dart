import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ChattingPage extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;

  const ChattingPage({required this.groupId, required this.currentUserEmail, super.key});

  @override
  _ChattingPageState createState() => _ChattingPageState();
}

class _ChattingPageState extends State<ChattingPage> {
  final db = FirebaseDatabase.instance.ref();
  late String targetUserEmail;
  late String targetUserName;
  final TextEditingController messageController = TextEditingController();
  List<Map<String, String>> groupMembers = [];
  List<Map<String, String>> chatMessages = [];

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
  }

  // 그룹 멤버 로딩
  void _loadGroupMembers() async {
    final groupSnap = await db.child('groupStudies').child(widget.groupId).get();
    if (groupSnap.exists) {
      final data = groupSnap.value as Map; // Firebase에서 가져온 데이터를 Map<String, dynamic>으로 변환
      final members = Map<String, dynamic>.from(data['members'] ?? {}); // members 객체 추출

      // setState(() {
      //   groupMembers = members.entries
      //       .map((e) => {
      //     'email': e.key, // 이메일을 사용
      //     'name': e.value['name'] ?? e.key.replaceAll('_', '.') // name이 없으면 이메일을 사용
      //   })
      //       .toList(); // List<Map<String, String>> 형식으로 변환
      // });
    }

  }






  // 채팅 메시지 로딩
  void _loadChatMessages() async {
    final chatSnap = await db.child('groupStudies').child(widget.groupId).child('chat').get();
    if (chatSnap.exists) {
      final data = Map<String, dynamic>.from(chatSnap.value as Map);
      setState(() {
        chatMessages = data.entries
            .where((e) =>
        (e.value['senderId'] == widget.currentUserEmail && e.value['receiverId'] == targetUserEmail) ||
            (e.value['senderId'] == targetUserEmail && e.value['receiverId'] == widget.currentUserEmail))
            .map((e) => {
          'senderId': e.value['senderId'] as String,
          'message': e.value['message'] as String,
          'timestamp': e.value['timestamp'] as String,
        })
            .toList();
      });
    }
  }

  // 메시지 전송
  void _sendMessage() async {
    final message = messageController.text.trim();
    if (message.isNotEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final chatRef = db.child('groupStudies').child(widget.groupId).child('chat').push();
      await chatRef.set({
        'senderId': widget.currentUserEmail,
        'receiverId': targetUserEmail,
        'message': message,
        'timestamp': timestamp,
      });
      setState(() {
        chatMessages.add({
          'senderId': widget.currentUserEmail,
          'message': message,
          'timestamp': timestamp,
        });
      });
      messageController.clear();
    }
  }

  // 찌르기 아이콘 (알림 메시지 전송)
  void _sendReminderMessage() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final chatRef = db.child('groupStudies').child(widget.groupId).child('chat').push();
    await chatRef.set({
      'senderId': widget.currentUserEmail,
      'receiverId': targetUserEmail,
      'message': '공부하세요!',
      'timestamp': timestamp,
    });

    // 상대방을 찔렀습니다 알림
    final reminderRef = db.child('groupStudies').child(widget.groupId).child('chat').push();
    await reminderRef.set({
      'senderId': widget.currentUserEmail,
      'receiverId': widget.currentUserEmail,
      'message': '상대방을 찔렀습니다!',
      'timestamp': timestamp,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
      ),
      body: Row(
        children: [
          // 그룹 멤버 목록
          Container(
            width: 150,
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: ListView.builder(
              itemCount: groupMembers.length,
              itemBuilder: (context, index) {
                final member = groupMembers[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(0xFFD9D9D9), // 회색 동그라미
                  ),
                  title: Text(member['name']!), // name 표시
                  onTap: () {
                    setState(() {
                      targetUserEmail = member['email']!;
                      targetUserName = member['name']!;
                      _loadChatMessages();
                    });
                  },
                );
              },
            ),
          ),
          // 채팅 영역
          Expanded(
            child: Column(
              children: [
                // 채팅 대화 내용
                Expanded(
                  child: ListView.builder(
                    itemCount: chatMessages.length,
                    itemBuilder: (context, index) {
                      final chat = chatMessages[index];
                      final isSender = chat['senderId'] == widget.currentUserEmail;
                      return ListTile(
                        title: Align(
                          alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            color: isSender ? Color(0xFFB8BDF1).withOpacity(0.3) : Colors.grey[200], // B8BDF1 색과 투명도
                            child: Text(chat['message']!),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // 메시지 입력 및 전송
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: const InputDecoration(hintText: '메시지를 입력하세요'),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                      IconButton(
                        icon: const Icon(Icons.thumb_up),
                        onPressed: _sendReminderMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
