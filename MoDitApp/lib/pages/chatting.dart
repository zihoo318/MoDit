import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'flask_api.dart';


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
  final ScrollController _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    _loadGroupMembers();
  }

  @override
  void didUpdateWidget(covariant ChattingPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 새 메시지 추가 시 자동 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _loadGroupMembers() async {
    final groupSnap = await db.child('groupStudies')
        .child(widget.groupId)
        .get();
    if (groupSnap.exists) {
      final data = Map<String, dynamic>.from(groupSnap.value as Map);
      final members = Map<String, dynamic>.from(data['members'] ?? {});
      final List<Map<String, dynamic>> loaded = [];

      for (var emailKey in members.keys) {
        final userSnap = await db.child('user').child(emailKey).get();
        final name = userSnap
            .child('name')
            .value
            ?.toString() ?? emailKey.split('@')[0];
        loaded.add({'email': emailKey, 'name': name});
      }

      setState(() {
        groupMembers = loaded;
        if (groupMembers.isNotEmpty) {
          targetUserEmail = groupMembers[0]['email']!;
          targetUserName = groupMembers[0]['name']!;
          _listenToMessages(targetUserEmail); // ✅ 첫 친구 채팅 불러오기
        }
      });
    }
  }

  void _listenToMessages(String receiverEmail) {
    _messageSubscription?.cancel();
    _messageSubscription = db
        .child('groupStudies')
        .child(widget.groupId)
        .child('chat')
        .onValue
        .listen((event) {
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

          return !isPoke && ((sender == currentUser && receiver == target) ||
              (sender == target && receiver == currentUser));
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

        // ✅ 메시지 추가 후 자동 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  Future<void> _sendMessage() async {
    if (targetUserEmail.isEmpty) return;
    final message = messageController.text.trim();
    if (message.isNotEmpty) {
      final timestamp = DateTime
          .now()
          .millisecondsSinceEpoch
          .toString();
      final chatRef = db.child('groupStudies').child(widget.groupId).child(
          'chat').push();
      await chatRef.set({
        'senderId': widget.currentUserEmail,
        'receiverId': targetUserEmail,
        'message': message,
        'timestamp': timestamp,
      });
      print("파베에 저장되는 receiverId: $targetUserEmail");

      final userSnap = await db.child('user').child(
          widget.currentUserEmail.replaceAll('.', '_')).get();
      final senderName = userSnap
          .child('name')
          .value
          ?.toString() ?? widget.currentUserEmail;

      // 🔒 수신자에게만 푸시 전송
      await _sendPushNotification("$senderName: $message", targetUserEmail);

      messageController.clear();
    }
  }

  Future<void> _sendReminderMessage() async {
    if (targetUserEmail.isEmpty) return;

    final reminderRef = db.child('groupStudies').child(widget.groupId).child(
        'reminder').push();
    await reminderRef.set({
      'senderId': widget.currentUserEmail,
      'receiverId': targetUserEmail,
      'message': '공부하세요!',
      'timestamp': DateTime
          .now()
          .millisecondsSinceEpoch
          .toString(),
    });

    // 🔒 수신자에게만 푸시 전송
    await _sendPushNotification("공부하세요!", targetUserEmail);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false, // 팝업 바깥 클릭으로 닫히지 않도록
        builder: (_) =>
            Center(
              child: Animate(
                effects: const [
                  ScaleEffect(curve: Curves.elasticOut,
                      duration: Duration(milliseconds: 500)),
                  FadeEffect(duration: Duration(milliseconds: 300)),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECE6F0), // ✅ 여기 배경색 변경!
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Text(
                    "상대방에게 '공부하세요!' 알림을 보냈습니다.",
                    style: TextStyle(fontSize: 16, color: Color(0xFF404040)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
      );

      // 팝업 자동 닫기
      Future.delayed(const Duration(seconds: 2), () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<void> _sendPushNotification(String message, String toEmail) async {
    if (toEmail == widget.currentUserEmail) return;

    final userKey = toEmail.replaceAll('.', '_');
    final userSnap = await db.child('user').child(userKey).get();
    final token = userSnap
        .child('fcmToken')
        .value
        ?.toString();
    if (token == null) return;

    final body = {
      'token': token,
      'title': '모딧에서 알림!',
      'body': message,
    };

    print("[FCM] 전송 대상: $toEmail");
    print("[FCM] 토큰: $token");
    print("[FCM] 요청 바디: $body");
    try {
      final res = await http.post(
        Uri.parse('${Api.baseUrl}/send_push'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      print("🔔 알림 전송 결과: ${res.statusCode} / ${res.body}");
    } catch (e) {
      print("❌ 알림 전송 예외: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FE), // ← 연보라 배경 적용
      body: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔼 채팅 텍스트 위로 조금 올리기
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      "채팅",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 0),
                Expanded(child: _buildUserList()),
              ],
            ),

            // 오른쪽 채팅 UI
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
          return GestureDetector(
            onTap: () {
              setState(() {
                targetUserEmail = member['email']!;
                targetUserName = member['name']!;
              });
              _listenToMessages(targetUserEmail);
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, scale, child) {
                return AnimatedScale(
                  scale: 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    title: Center(
                      child: CircleAvatar(
                        backgroundColor: const Color(0xFFD9D9D9),
                        child: Text(
                          member['name']!,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }


  Widget _buildChatArea() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 40, 12, 12),
        // 왼쪽은 0, 위는 조금 내리고, 오른쪽 & 아래는 그대로
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(child: _buildMessages()), // ✅ 이건 Expanded로 감싸야 스크롤됨
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTopBar() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFFB8BDF1).withOpacity(0.3),
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15), topRight: Radius.circular(15)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFFFFFFFF),
            backgroundImage: AssetImage('assets/images/user_icon2.png'),
          ),
          const SizedBox(width: 10),
          Text(targetUserName.isEmpty ? '' : targetUserName,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w500)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              _sendReminderMessage();
              setState(() {}); // 트리거용
            },
            child: Animate(
              effects: const [ShakeEffect()],
              key: ValueKey(DateTime
                  .now()
                  .millisecondsSinceEpoch), // 매번 새로 흔들림
              child: Row(
                children: [
                  Image.asset('assets/images/hand_icon.png', width: 40),
                  const SizedBox(width: 8),
                  const Text('찌르기'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
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
              child: Animate(
                effects: const [
                  FadeEffect(duration: Duration(milliseconds: 300)),
                  SlideEffect(begin: Offset(0, 0.1), end: Offset(0, 0)),
                ],
                child: Text(
                  chat['message'],
                  style: const TextStyle(color: Color(0xFF404040)),
                ),
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
            decoration: BoxDecoration(color: const Color(0xFFECE6F0),
                borderRadius: BorderRadius.circular(30)),
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