import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

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
  StreamSubscription<DatabaseEvent>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
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

  void _listenToMessages(String receiverEmail) {
    _messageSubscription?.cancel();
    _messageSubscription = db.child('groupStudies').child(widget.groupId).child('chat').onValue.listen((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final loaded = data.entries.where((e) {
          final v = e.value as Map;
          final msg = v['message']?.toString() ?? '';
          final isPoke = msg == '공부하세요!' || msg == '상대방을 찔렀습니다';

          final sender = v['senderId'].toString().replaceAll('.', '_');
          final receiver = v['receiverId'].toString().replaceAll('.', '_');
          final currentUser = widget.currentUserEmail.replaceAll('.', '_');
          final target = receiverEmail.replaceAll('.', '_');

          return !isPoke && ((sender == currentUser && receiver == target) || (sender == target && receiver == currentUser));
        }).map((e) {
          final v = e.value as Map;
          return {
            'senderId': v['senderId'],
            'message': v['message'],
            'timestamp': v['timestamp'],
          };
        }).toList()
          ..sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

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

      final userSnap = await db.child('user').child(widget.currentUserEmail.replaceAll('.', '_')).get();
      final senderName = userSnap.child('name').value?.toString() ?? widget.currentUserEmail;

      // 🔒 수신자에게만 푸시 전송
      await _sendPushNotification("$senderName: $message", targetUserEmail);

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

    // 🔒 수신자에게만 푸시 전송
    await _sendPushNotification("공부하세요!", targetUserEmail);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFECE6F0),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
          content: const Text(
            "상대방에게 '공부하세요!' 알림을 보냈습니다.",
            style: TextStyle(color: Color(0xFF404040)),
          ),
        ),
      );
    }
  }

  Future<void> _sendPushNotification(String message, String toEmail) async {
    if (toEmail == widget.currentUserEmail) return;

    final userKey = toEmail.replaceAll('.', '_');
    final userSnap = await db.child('user').child(userKey).get();
    final token = userSnap.child('fcmToken').value?.toString();
    if (token == null) return;

    final body = {
      'token': token,
      'title': '모딧에서 알림!',
      'body': message,
    };

    try {
      final res = await http.post(
        Uri.parse('http://192.168.219.108:8080/send_push'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      print("🔔 알림 전송 결과: \${res.statusCode} / \${res.body}");
    } catch (e) {
      print("❌ 알림 전송 예외: \$e");
    }
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
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
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
              _listenToMessages(targetUserEmail);
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
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
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
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
        reverse: false,
        itemCount: chatMessages.length,
        itemBuilder: (context, index) {
          final chat = chatMessages[index];
          final isSender = chat['senderId'] == widget.currentUserEmail;
          return Align(
            alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFB8BDF1).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(chat['message'], style: const TextStyle(color: Color(0xFF404040))),
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
            decoration: BoxDecoration(color: const Color(0xFFECE6F0), borderRadius: BorderRadius.circular(30)),
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
