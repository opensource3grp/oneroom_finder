import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:oneroom_finder/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'splash_screen.dart'; // 스플래시 화면 클래스 파일 가져오기

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await SharedPreferences.getInstance();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
