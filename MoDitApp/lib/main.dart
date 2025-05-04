import 'package:flutter/material.dart';
import 'package:moditapp/pages/chatting.dart';
import 'package:moditapp/pages/homeworkManager.dart';
import 'package:moditapp/pages/homwork.dart';
import 'package:moditapp/pages/join.dart';
import 'pages/home.dart';
import 'pages/login.dart'; // 👈 login.dart 임포트 추가
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoDitApp',
      theme: ThemeData(),
      home: const HomeworkManagerScreen(), // 👈 앱 첫 화면을 LoginScreen으로 설정
    );
  }
}
