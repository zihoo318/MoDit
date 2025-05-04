import 'package:flutter/material.dart';
import 'fileSelectPopup.dart';
import 'homeworkCheck.dart';

class HomeworkManagerScreen extends StatelessWidget {
  const HomeworkManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/background1.png', fit: BoxFit.cover),
          ),
          Positioned(
            top: 20,
            right: 20,
            child: Image.asset('assets/images/user_icon.png', width: 100),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset('assets/images/homework_icon.png', width: 120),
                ),
                const SizedBox(height: 40),
                const Text("2025. 04. 25.", style: TextStyle(fontSize: 40)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEDFF),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("그룹과제", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      _GroupTaskRow(task: "어쩌고"),
                      SizedBox(height: 20),
                      _GroupTaskRow(task: "저쩌고"),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _UserTaskBox(name: "가을", tasks: ["어쩌고", "저쩌고"], color: Color(0xFF4C92D7)),
                    _UserTaskBox(name: "윤지", tasks: ["어쩌고", "저쩌고"], color: Color(0xFF6495ED)),
                    _UserTaskBox(name: "유진", tasks: ["어쩌고", "저쩌고"], color: Color(0xFF7DB5EB)),
                    _UserTaskBox(name: "지후", tasks: ["어쩌고", "저쩌고"], color: Color(0xFF7DB5EB)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTaskRow extends StatefulWidget {
  final String task;

  const _GroupTaskRow({required this.task});

  @override
  State<_GroupTaskRow> createState() => _GroupTaskRowState();
}

class _GroupTaskRowState extends State<_GroupTaskRow> {
  bool isSubmitted = false;
  String? selectedFile;

  final List<String> fileOptions = ['파일 이름1', '파일 이름2', '파일 이름3'];

  void _showFileSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => FileSelectPopup(
        fileOptions: fileOptions,
        onFileSelected: (file) {
          setState(() {
            isSubmitted = true;
            selectedFile = file;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isSubmitted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const HomeworkCheckScreen(userName: "가을")),
          );
        }
      },
      child: Row(
        children: [
          Image.asset('assets/images/heart_icon.png', width: 40),
          const SizedBox(width: 10),
          Text(widget.task, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: _showFileSelectionDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("제출", style: TextStyle(fontWeight: FontWeight.bold)),
                    if (isSubmitted) const SizedBox(width: 6),
                    if (isSubmitted) const Icon(Icons.check, size: 18, color: Colors.green),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTaskBox extends StatelessWidget {
  final String name;
  final List<String> tasks;
  final Color color;

  const _UserTaskBox({required this.name, required this.tasks, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEDFF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 14),
          ...tasks.map((t) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Image.asset('assets/images/heart_icon.png', width: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t,
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              ],
            ),
          )),
        ],
      ),
    );
  }
}
