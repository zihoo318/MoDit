import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'pages/join.dart';
import 'pages/group_main_screen.dart';
import 'pages/study_time.dart';
import 'pages/study_first_page.dart';
import 'pages/meeting_calendar.dart';
import 'pages/meeting_record.dart';
import 'pages/note_screen.dart';
import 'pages/notice.dart';
import 'pages/chatting.dart';
import 'pages/flask_test.dart';
import 'pages/first_page.dart';
import 'pages/logo_screen.dart';

/// ✅ 백그라운드 푸시 알림 수신 핸들러
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('💬 백그라운드 메시지 수신됨: \${message.messageId}');
}

// ✅ navigatorKey를 사용해 어디서든 context 접근 가능하게 함
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Firebase Auth 익명 로그인 (푸시 식별자용)
  await FirebaseAuth.instance.signInAnonymously();

  // ✅ 백그라운드 메시지 핸들러 등록
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ 알림 권한 요청
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // ✅ 포그라운드 메시지 처리 리스너 등록
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📬 포그라운드 메시지 수신됨: \${message.notification?.title}");
    final body = message.notification?.body ?? '';
    final currentUser = FirebaseAuth.instance.currentUser;

    // 🔒 본인에게 온 알림이면 무시
    if (currentUser != null && (body.startsWith(currentUser.email ?? '') || body == '공부하세요!')) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              body,
              style: const TextStyle(color: Color(0xFF404040)),
            ),
            backgroundColor: const Color(0xFFECE6F0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  });

  runApp(const MoDitApp());
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
      home: const Home(), // ✅ 첫 진입화면
    );
  }
}
