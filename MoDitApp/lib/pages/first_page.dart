import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'study_first_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> groupRooms = [];
  List<String> friends = [];

  final uid = FirebaseAuth.instance.currentUser!.uid;
  final dbRef = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _loadGroupStudies();
  }

  void _loadFriends() async {
    final snapshot = await dbRef.child('users/$uid/friends').get();
    if (snapshot.exists) {
      final friendMap = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        friends = friendMap.values.map((e) => e.toString()).toList();
      });
    }
  }

  void _loadGroupStudies() async {
    final snapshot = await dbRef.child('users/$uid/groupStudies').get();
    if (snapshot.exists) {
      final groupMap = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        groupRooms = groupMap.entries.map((e) {
          return {
            'name': e.key,
            'members': List<String>.from(e.value as List),
          };
        }).toList();
      });
    } else {
      setState(() {
        groupRooms = [];
      });
    }
  }

  void showAddFriendDialog() {
    final TextEditingController emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFD7EBFF),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("추가할 친구의 이메일을 입력하세요"),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final friendEmail = emailController.text.trim();
                    final usersSnapshot = await dbRef.child('users').get();
                    String? friendUid;
                    for (final entry in usersSnapshot.children) {
                      final data = Map<String, dynamic>.from(entry.value as Map);
                      if (data['email'] == friendEmail) {
                        friendUid = entry.key;
                        break;
                      }
                    }

                    if (friendUid != null) {
                      await dbRef.child('users/$uid/friends/$friendUid').set(friendEmail);
                      Navigator.of(context).pop();
                      _loadFriends();
                    } else {
                      Navigator.of(context).pop();
                      _showAlert("해당 이메일의 사용자를 찾을 수 없습니다.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9EB8E3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("저장"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showCreateGroupStudyDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: const Color(0xFFD7EBFF),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("그룹 스터디 이름을 설정하세요"),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showSelectMembersDialog(nameController.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9EB8E3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text("저장"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showSelectMembersDialog(String groupName) {
    final Map<String, bool> selectedFriends = {
      for (var f in friends) f: false,
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: const Color(0xFFD7EBFF),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("그룹 스터디에 참여할 친구들을 선택해주세요"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: selectedFriends.keys.map((friend) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: selectedFriends[friend],
                            onChanged: (val) {
                              setState(() {
                                selectedFriends[friend] = val!;
                              });
                            },
                          ),
                          Text(friend),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final selected = selectedFriends.entries
                          .where((e) => e.value)
                          .map((e) => e.key)
                          .toList();

                      await dbRef.child('users/$uid/groupStudies/$groupName').set(selected);
                      Navigator.of(context).pop();
                      _loadGroupStudies(); // 🔄 여기서 새로 불러오기
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9EB8E3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("선택 완료"),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showAlert(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("확인"),
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
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: showAddFriendDialog,
                      icon: const Icon(Icons.add),
                      label: const Text("친구 추가"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: showCreateGroupStudyDialog,
                      icon: const Icon(Icons.add),
                      label: const Text("그룹스터디 추가"),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: groupRooms.length,
                    itemBuilder: (context, index) {
                      final group = groupRooms[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudyFirstPage(
                                groupName: group['name'],
                                members: group['members'],
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD7EBFF),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(group['name'], style: const TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(height: 8),
                            Image.asset('assets/images/note_icon.png', width: 50),
                            const SizedBox(height: 4),
                            const Text('이름설정'),
                          ],
                        ),
                      );
                    },
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
