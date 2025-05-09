import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChattingScreen extends StatefulWidget {
  final String groupName;

  const ChattingScreen({super.key, required this.groupName});

  @override
  State<ChattingScreen> createState() => _ChattingScreenState();
}

class _ChattingScreenState extends State<ChattingScreen> {
  final TextEditingController _controller = TextEditingController();
  List<String> _members = [];
  String? _selectedMember;
  List<_ChatBubble> _messages = [];

  String? _currentUserEmail;
  DatabaseReference? _chatRef;
  StreamSubscription<DatabaseEvent>? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserAndGroupMembers();
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    super.dispose();
  }

  String _sanitizeEmail(String email) => email.replaceAll('.', '_dot_');

  String get _chatKey {
    final sanitizedSender = _sanitizeEmail(_currentUserEmail!);
    final sanitizedReceiver = _sanitizeEmail(_selectedMember!);
    return sanitizedSender.compareTo(sanitizedReceiver) < 0
        ? '${sanitizedSender}_$sanitizedReceiver'
        : '${sanitizedReceiver}_$sanitizedSender';
  }

  Future<void> _loadCurrentUserAndGroupMembers() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _currentUserEmail = user.email;
    final ref = FirebaseDatabase.instance.ref('users');
    final snapshot = await ref.get();

    if (snapshot.exists) {
      final usersData = snapshot.value as Map<dynamic, dynamic>;

      for (var entry in usersData.entries) {
        final userData = entry.value as Map<dynamic, dynamic>;
        final groupStudies = userData['groupStudies'];
        if (groupStudies != null && groupStudies[widget.groupName] != null) {
          final group = groupStudies[widget.groupName];
          List<String> members = [];

          if (group is List) {
            members = group.where((e) => e != null).map((e) => e.toString()).toList();
          } else if (group is Map) {
            members = group.entries.map((e) => e.value.toString()).toList();
          }

          setState(() {
            _members = members;
            _selectedMember = _members.firstWhere((m) => m != _currentUserEmail, orElse: () => '');
          });

          _subscribeToMessages();
          break;
        }
      }
    }
  }

  void _subscribeToMessages() {
    _chatSubscription?.cancel(); // 이전 구독 제거
    _messages.clear();

    if (_currentUserEmail == null || _selectedMember == null || _selectedMember!.isEmpty) return;

    final chatPath = 'chats/$widget.groupName/$_chatKey';
    _chatRef = FirebaseDatabase.instance.ref(chatPath);

    _chatSubscription = _chatRef!.onChildAdded.listen((event) {
      final messageData = event.snapshot.value as Map<dynamic, dynamic>;
      final sender = messageData['sender'];
      final receiver = messageData['receiver'];
      final text = messageData['message'];

      if ((sender == _currentUserEmail && receiver == _selectedMember) ||
          (sender == _selectedMember && receiver == _currentUserEmail)) {
        setState(() {
          _messages.add(
            _ChatBubble(
              text,
              const Color(0x996495ED),
              alignRight: sender == _currentUserEmail,
            ),
          );
        });
      }
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || _currentUserEmail == null || _selectedMember == null) return;

    final message = {
      'message': text,
      'sender': _currentUserEmail,
      'receiver': _selectedMember,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final chatPath = 'chats/${widget.groupName}/$_chatKey';
    FirebaseDatabase.instance.ref(chatPath).push().set(message);

    setState(() {
      _messages.add(
        _ChatBubble(text, const Color(0x996495ED), alignRight: true),
      );
    });

    _controller.clear();
  }

  Widget _buildMemberList() {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEDFF),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _members.map((email) {
          final isSelected = email == _selectedMember;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMember = email;
                  _subscribeToMessages();
                });
              },
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4C92D7) : const Color(0xFF7DB5EB),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  email.split('@')[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChatArea() {
    if (_selectedMember == null || _selectedMember!.isEmpty) {
      return const Center(child: Text("멤버를 선택하세요"));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/user_icon.png', width: 50),
              const SizedBox(width: 8),
              Text(
                _selectedMember!,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: Color(0xFF1B178F)),
              ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background1.png',
              fit: BoxFit.cover,
            ),
          ),
          const Positioned(
            top: 20,
            right: 20,
            child: Image(
              image: AssetImage('assets/images/user_icon.png'),
              width: 50,
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 45),
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(width: 30),
                    _buildMemberList(),
                    Expanded(child: _buildChatArea()),
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
