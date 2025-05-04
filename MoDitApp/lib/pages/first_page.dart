
import 'package:flutter/material.dart';

void main() {
  runApp(const MoDitApp());
}

class MoDitApp extends StatelessWidget {
  const MoDitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<String> groupRooms = ["그룹스터디룸1", "그룹스터디룸2", "그룹스터디룸3", "그룹스터디룸4"];
  final List<String> friends = ["가을", "윤지", "유진", "지후"];

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
            child: SizedBox(
              width: 300,
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
                    onPressed: () {
                      Navigator.of(context).pop();
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
            child: SizedBox(
              width: 300,
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
                      showSelectMembersDialog();
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
          ),
        );
      },
    );
  }

  void showSelectMembersDialog() {
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
              child: SizedBox(
                width: 300,
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
                      onPressed: () {
                        Navigator.of(context).pop();
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
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'MoDit',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6B9EFF)),
                  ),
                  Image.asset('assets/images/user_icon.png', width: 30),
                ],
              ),
            ),
            // 버튼
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
            // 그룹 리스트
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
                  return Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD7EBFF),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(groupRooms[index]),
                      ),
                      const SizedBox(height: 8),
                      Image.asset('assets/images/note_icon.png', width: 50),
                      const SizedBox(height: 4),
                      const Text('이름설정'),
                    ],
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
