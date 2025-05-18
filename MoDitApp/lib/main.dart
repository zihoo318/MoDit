import 'package:flutter/material.dart';
import 'package:moditapp/pages/group_main_screen.dart';
import 'pages/first_page.dart'; // HomeScreen이 정의된 파일
import 'pages/logo_screen.dart';
import 'pages/meeting_calendar.dart';
import 'pages/meeting_record.dart';
import 'pages/notice.dart';
import 'pages/study_first_page.dart';
import 'pages/study_time.dart';
import 'package:moditapp/pages/chatting.dart';
import 'package:moditapp/pages/join.dart';
import 'pages/home.dart';
import 'pages/login.dart'; // 👈 login.dart 임포트 추가
import 'pages/note_screen.dart';
import 'pages/flask_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      title: 'MoDitApp',
      theme: ThemeData(
        fontFamily: 'nanum_round', // 전체 폰트 지정
      ),
      localizationsDelegates: const [ // 한글 showDatePicker() 사용을 위해 추가함
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      home: HomeScreen(
      //   groupId: '-OPqe387N6zi4K4UK3IT',
         currentUserEmail: 'yun@naver.com',
        currentUserName: 'yujin',
       ),
    );
    //home: NoteScreen());
  }
}
