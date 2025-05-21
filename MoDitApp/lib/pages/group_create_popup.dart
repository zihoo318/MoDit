import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class GroupCreatePopup extends StatefulWidget {
  final String currentUserEmail;
  const GroupCreatePopup({required this.currentUserEmail, super.key});

  @override
  State<GroupCreatePopup> createState() => _GroupCreatePopupState();
}

class _GroupCreatePopupState extends State<GroupCreatePopup> {
  final db = FirebaseDatabase.instance.ref();
  final TextEditingController groupNameController = TextEditingController();
  final Map<String, bool> selectedFriends = {};
  final ScrollController _scrollController = ScrollController(); // ✅ ScrollController 추가

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _scrollController.dispose(); // ✅ 메모리 누수 방지
    super.dispose();
  }

  void _loadFriends() async {
    final currentUserId = widget.currentUserEmail.replaceAll('.', '_');
    final snapshot = await db.child('user').child(currentUserId).child('friends').get();
    if (!mounted) return; // ✅ dispose 이후 setState 방지

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        for (var key in data.keys) {
          selectedFriends[key] = false;
        }
      });
    }
  }

  void _saveGroup() async {
    final groupName = groupNameController.text.trim();
    if (groupName.isEmpty) return;

    final Map<String, bool> memberMap = {};
    selectedFriends.forEach((key, value) {
      if (value) memberMap[key] = true;
    });

    final currentUserId = widget.currentUserEmail.replaceAll('.', '_');
    memberMap[currentUserId] = true;

    if (memberMap.length < 2) return;

    await db.child('groupStudies').push().set({
      'name': groupName,
      'members': memberMap,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '👥 그룹 스터디 만들기',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D0A64)),
                    ),
                    const SizedBox(height: 16),
                    const Divider(thickness: 1, color: Color(0xFF0D0A64)),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('그룹 스터디 이름',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Color(0xFFD3D3E2), width: 1),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: groupNameController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '스터디 이름을 입력하세요',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('그룹에 초대할 친구 선택',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: Scrollbar(
                        thumbVisibility: true,
                        controller: _scrollController, // ✅ ScrollController 연결
                        child: ListView(
                          controller: _scrollController, // ✅ ListView에도 연결
                          shrinkWrap: true,
                          children: selectedFriends.entries.map((e) {
                            return CheckboxListTile(
                              value: e.value,
                              title: Text(e.key.replaceAll('_', '.')),
                              onChanged: (val) {
                                setState(() {
                                  selectedFriends[e.key] = val!;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: _saveGroup,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0D0A64),
                          side: const BorderSide(color: Color(0xFF0D0A64), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('선택 완료'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
