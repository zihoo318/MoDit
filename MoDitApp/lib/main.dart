import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  //firebase 초기화(로그인, 회원가입 기능)
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
      title: 'Multi-Page App',
      theme: ThemeData(
        //fontFamily: 'dohyeon', // 전체 폰트 지정
        //primarySwatch: Colors.blue,
      ),
      themeMode: ThemeMode.system,
      initialRoute: '/home',
      routes: {
        //'/': (context) => temp_startPage(),
      },
    );
  }
}