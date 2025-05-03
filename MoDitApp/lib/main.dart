import 'package:flutter/material.dart';
import 'pages/first_page.dart'; // HomeScreen이 정의된 파일
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MoDitApp()); // 이름 바꿔도 되고 그대로 사용해도 됨
}

class MoDitApp extends StatelessWidget {
  const MoDitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(), // ← first_page.dart 안의 HomeScreen
    );
  }
}
