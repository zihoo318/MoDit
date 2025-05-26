import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:moditapp/pages/note_screen.dart';
import 'pages/first_page.dart';
import 'package:moditapp/pages/login.dart';
import 'package:moditapp/pages/splash_screen.dart';
import 'firebase_options.dart';
import 'pages/first_page.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('MoDitLog: Background message received: ${message.messageId}');
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  print('MoDitLog: >> Entered main()');

  try {
    print('MoDitLog: Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('MoDitLog: Firebase initialized.');

    print('MoDitLog: Starting anonymous sign-in...');
    await FirebaseAuth.instance.signInAnonymously();
    print('MoDitLog: Anonymous sign-in complete. UID: ${FirebaseAuth.instance.currentUser?.uid}');

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    print('MoDitLog: Initializing local notifications...');
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print('MoDitLog: Local notifications initialized.');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    print('MoDitLog: Requesting push notification permission...');
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('MoDitLog: Push notification permission granted.');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("MoDitLog: Foreground message received: ${message.notification?.title}");

      final notification = message.notification;
      final android = notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'modit_channel_id',

              'MoDit Notification',
              channelDescription: 'Shows notifications while the app is active',

              importance: Importance.max,
              priority: Priority.high,
              color: const Color(0xFFB8BDF1),
            ),
          ),
        );
      }
    });


    print('MoDitLog: All initialization complete. Running app...');
    runApp(const MoDitApp());
  } catch (e) {
    print('MoDitLog: ERROR in main(): $e');
  }
}


class MoDitApp extends StatelessWidget {
  const MoDitApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('MoDitLog: Building MoDitApp...');
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'MoDitApp',
      theme: ThemeData(
        fontFamily: 'nanum_round',
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],

      home: SplashScreen(), // You can add logs in SplashScreen too
        //home: HomeScreen(currentUserEmail: 'yu@naver.com', currentUserName: '유진',),
    );
  }
}