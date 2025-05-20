import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChattingPage extends StatefulWidget {
  final String groupId;
  final String currentUserEmail;

  const ChattingPage({
    required this.groupId,
    required this.currentUserEmail,
    super.key,
  });

  @override
  _ChattingPageState createState() => _ChattingPageState();
}

class _ChattingPageState extends State<ChattingPage> {
  final db = FirebaseDatabase.instance.ref();
  late String targetUserEmail;
  String targetUserName = '';
  final TextEditingController messageController = TextEditingController();
  List<Map<String, dynamic>> groupMembers = [];
  List<Map<String, dynamic>> chatMessages = [];

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
    _listenToMessages();
  }

  void _loadGroupMembers() async {
    final groupSnap = await db.child('groupStudies').child(widget.groupId).get();
    if (groupSnap.exists) {
      final data = Map<String, dynamic>.from(groupSnap.value as Map);
      final members = Map<String, dynamic>.from(data['members'] ?? {});

      final List<Map<String, dynamic>> loaded = [];
      for (var emailKey in members.keys) {
        final userSnap = await db.child('user').child(emailKey).get();
        final name = userSnap.child('name').value?.toString() ?? emailKey.split('@')[0];
        loaded.add({'email': emailKey, 'name': name});
      }

      setState(() {
        groupMembers = loaded;
      });
    }
  }

  void _listenToMessages() {
    db.child('groupStudies').child(widget.groupId).child('chat').onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists && targetUserEmail.isNotEmpty) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final loaded = data.entries.where((e) {
          final v = e.value as Map;
          final msg = v['message']?.toString() ?? '';
          final isPoke = msg == '공부하세요!' || msg == '상대방을 찔렀습니다';
          return !isPoke &&
              ((v['senderId'] == widget.currentUserEmail && v['receiverId'] == targetUserEmail) ||
                  (v['senderId'] == targetUserEmail && v['receiverId'] == widget.currentUserEmail));
        }).map((e) {
          final v = e.value as Map;
          return {
            'senderId': v['senderId'],
            'message': v['message'],
            'timestamp': v['timestamp'],
          };
        }).toList();

        setState(() => chatMessages = loaded);
      }
    });
  }

  Future<void> _sendMessage() async {
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

      await _sendPushNotification(message);

      messageController.clear();
    }
  }

  Future<void> _sendReminderMessage() async {
    if (targetUserEmail.isEmpty) return;

    final reminderRef = db.child('groupStudies').child(widget.groupId).child('reminder').push();
    await reminderRef.set({
      'senderId': widget.currentUserEmail,
      'receiverId': targetUserEmail,
      'message': '공부하세요!',
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    await _sendPushNotification('공부하세요!');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          "상대방에게 '공부하세요!' 알림을 보냈습니다.",
          style: TextStyle(color: Color(0xFF404040)),
        ),
        backgroundColor: const Color(0xFFECE6F0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendPushNotification(String message) async {
    final userKey = targetUserEmail.replaceAll('.', '_');
    final userSnap = await db.child('user').child(userKey).get();
    final token = userSnap.child('fcmToken').value?.toString();
    if (token == null) return;

    final body = {
      'to': token,
      'notification': {
        'title': '새 메시지',
        'body': message,
      },
      'priority': 'high',
    };

    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=YOUR_SERVER_KEY', // ✅ FCM 서버 키로 교체
      },
      body: json.encode(body),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _buildUserList(),
            _buildChatArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return Container(
      width: 180,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListView.builder(
        itemCount: groupMembers.length,
        itemBuilder: (context, index) {
          final member = groupMembers[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),
            title: Center(
              child: CircleAvatar(
                backgroundColor: const Color(0xFFD9D9D9),
                child: Text(member['name']!, style: const TextStyle(color: Colors.black87)),
              ),
            ),
            onTap: () {
              setState(() {
                targetUserEmail = member['email']!;
                targetUserName = member['name']!;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildChatArea() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            _buildTopBar(),
            _buildMessages(),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFFB8BDF1).withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFD9D9D9),
            backgroundImage: AssetImage('assets/images/user_icon2.png'),
          ),
          const SizedBox(width: 10),
          Text(targetUserName.isEmpty ? '' : targetUserName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
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
    );
  }

  Widget _buildMessages() {
    return Expanded(
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
                  color: const Color(0xFFB8BDF1).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(chat['message']),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Padding(
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
              color: const Color(0xFFECE6F0),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
