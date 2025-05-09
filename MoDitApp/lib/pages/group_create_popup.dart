// ✅ group_create_popup.dart (수정된 전체 파일)
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

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  void _loadFriends() async {
    final currentUserId = widget.currentUserEmail.replaceAll('.', '_');
    final snapshot = await db.child('user').child(currentUserId).child('friends').get();
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(60)),
      backgroundColor: const Color(0xFFECE6F0),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('그룹 스터디 이름을 설정하세요',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: groupNameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text('그룹에 추가할 친구를 선택하세요',
                  style: TextStyle(fontSize: 14)),
              const SizedBox(height: 10),
              ...selectedFriends.entries.map((e) => CheckboxListTile(
                value: e.value,
                title: Text(e.key.replaceAll('_', '.')),
                onChanged: (val) {
                  setState(() {
                    selectedFriends[e.key] = val!;
                  });
                },
              )),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('선택 완료', style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        ),
      ),
    );
  }
}