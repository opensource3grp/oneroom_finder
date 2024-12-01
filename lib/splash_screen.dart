import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/home_screen.dart';
import 'package:oneroom_finder/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth 추가
import 'dart:developer' as developer;

// 스플래시 화면
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateBasedOnLoginStatus();
  }

  Future<void> _navigateBasedOnLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final autoLogin = prefs.getBool('autoLogin') ?? false;

    await Future.delayed(const Duration(seconds: 5)); // 스플래시 화면 표시 시간

    if (autoLogin) {
      developer.log('자동 로그인 성공');
      _navigateToHome(); // 자동 로그인 시 홈 화면으로 이동
    } else {
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
      );
    }
  }

  void _navigateToHome() async {
    // 자동 로그인된 사용자 정보 가져오기
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data();
        final nickname = userData?['nickname'] ?? '알 수 없음';
        final job = userData?['job'] ?? '직업 없음';
        final uid = user.uid; // UID를 추가로 가져옵니다.

        // 홈 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              uid: uid, // uid를 전달합니다.
              nickname: nickname,
              job: job,
            ),
          ),
        );
      }
    } else {
      // 사용자가 로그인하지 않은 경우 로그인 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지 추가
            Image.asset('assets/logo.png', width: 100, height: 100),
            const SizedBox(height: 20),
            const Text(
              '원룸알리미',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange),
            ),
            const Text(
              '대학로의 모든 원룸 제공 서비스',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
