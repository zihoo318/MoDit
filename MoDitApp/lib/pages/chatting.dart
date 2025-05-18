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
  String targetUserName = '';
  final TextEditingController messageController = TextEditingController();
  List<Map<String, dynamic>> groupMembers = [];
  List<Map<String, String>> chatMessages = [];

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
    _createChatIfNotExist();
  }

  void _loadGroupMembers() async {
    final groupSnap = await db.child('groupStudies').child(widget.groupId).get();
    if (groupSnap.exists) {
      final data = Map<String, dynamic>.from(groupSnap.value as Map);
      final members = Map<String, dynamic>.from(data['members'] ?? {});
      setState(() {
        groupMembers = members.entries.map((e) {
          return {
            'email': e.key,
            'name': e.key.split('@')[0],
          };
        }).toList();
      });
    }
  }

  void _createChatIfNotExist() async {
    final chatSnap = await db.child('groupStudies').child(widget.groupId).child('chat').get();
    if (!chatSnap.exists) {
      await db.child('groupStudies').child(widget.groupId).child('chat').set({});
    }
  }

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
        }).toList();
      });
    }
  }

  void _sendMessage() async {
    if (targetUserEmail.isEmpty) return;
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

  void _sendReminderMessage() async {
    if (targetUserEmail.isEmpty) return;

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    final chatRef = db.child('groupStudies').child(widget.groupId).child('chat').push();
    await chatRef.set({
      'senderId': widget.currentUserEmail,
      'receiverId': targetUserEmail,
      'message': '공부하세요!',
      'timestamp': timestamp,
    });

    final reminderRef = db.child('groupStudies').child(widget.groupId).child('chat').push();
    await reminderRef.set({
      'senderId': widget.currentUserEmail,
      'receiverId': widget.currentUserEmail,
      'message': '상대방을 찔렀습니다',
      'timestamp': timestamp,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("상대방에게 '공부하세요!' 알림을 보냈습니다."),
        backgroundColor: Color(0xFFECE6F0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // ✅ 왼쪽 회색 멤버 박스
            Container(
              width: 180,
              margin: const EdgeInsets.only(left: 12, top: 12, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: groupMembers.length,
                      itemBuilder: (context, index) {
                        final member = groupMembers[index];
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 0),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFD9D9D9),
                                child: Text(
                                  member['name']!,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
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
                ],
              ),
            ),

            // ✅ 오른쪽 채팅 영역 (4방향 radius 적용)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 12, right: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    // ✅ 상단 AppBar
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFFB8BDF1).withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFD9D9D9),
                            child: Image.asset('assets/images/user_icon2.png', width: 30),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            targetUserName.isEmpty ? '' : targetUserName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: _sendReminderMessage,
                            child: Row(
                              children: [
                                Image.asset('assets/images/hand_icon.png', width: 40),
                                const SizedBox(width: 8),
                                const Text('찌르기'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ 채팅 메시지 + 입력창
                    Expanded(
                      child: Column(
                        children: [
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
                                        color: Color(0xFFB8BDF1).withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(chat['message']!),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
