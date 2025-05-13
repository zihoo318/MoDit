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
  List<Map<String, dynamic>> groupMembers = []; // 그룹 멤버 리스트
  List<Map<String, String>> chatMessages = []; // 채팅 메시지 리스트

  @override
  void initState() {
    super.initState();
    _loadGroupMembers(); // 그룹 멤버 로드
  }

  // 그룹 멤버 로딩
  void _loadGroupMembers() async {
    final groupSnap = await db.child('groupStudies').child(widget.groupId).get();
    if (groupSnap.exists) {
      final data = groupSnap.value as Map;
      final members = Map<String, dynamic>.from(data['members'] ?? {});

      setState(() {
        groupMembers = members.entries
            .map((e) {
          return {
            'email': e.key, // 이메일
            'name': e.key.split('@')[0], // name을 이메일 앞부분으로 설정 (예시: ga@naver_com -> ga)
          };
        })
            .toList(); // List<Map<String, String>> 형식으로 변환
      });
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
            .map((e) {
          return {
            'senderId': e.value['senderId'] as String,
            'message': e.value['message'] as String,
            'timestamp': e.value['timestamp'] as String,
          };
        })
            .toList();
      });
    }
  }

  // 메시지 전송
  void _sendMessage() async {
    if (targetUserEmail.isEmpty) {
      // targetUserEmail이 비어 있으면 메시지 보내지 않도록 처리
      return;
    }
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
    if (targetUserEmail.isEmpty) {
      // targetUserEmail이 비어 있으면 알림 전송하지 않도록 처리
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    // 상대방에게 "공부하세요!" 알림 전송
    final chatRef = db.child('groupStudies').child(widget.groupId).child('chat').push();
    await chatRef.set({
      'senderId': widget.currentUserEmail,
      'receiverId': targetUserEmail,
      'message': '공부하세요!',
      'timestamp': timestamp,
    });

    // 알림을 보낸 사람에게 "알림을 보냈습니다" 알림 전송
    final reminderRef = db.child('groupStudies').child(widget.groupId).child('chat').push();
    await reminderRef.set({
      'senderId': widget.currentUserEmail,
      'receiverId': widget.currentUserEmail,
      'message': '알림을 보냈습니다!',
      'timestamp': timestamp,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
        automaticallyImplyLeading: false, // 뒤로 가기 버튼 제거
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
                    backgroundColor: Colors.grey, // 회색 동그라미
                    child: Text(
                      member['name']![0],
                      style: TextStyle(color: Colors.white),
                    ), // 이름의 첫 글자 표시
                  ),
                  title: Text(member['name']!), // 이름 표시
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
                            decoration: BoxDecoration(
                              color: Color(0xFFB8BDF1).withOpacity(0.3), // 채팅 배경색
                              borderRadius: BorderRadius.circular(30),
                            ),
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
                      // 전송 버튼 (색상 ECE6F0으로 설정)
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFECE6F0),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                        ),
                      ),
                      // 찌르기 버튼 (hand_icon.png 사용)
                      IconButton(
                        icon: Image.asset('assets/images/hand_icon.png'),
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
