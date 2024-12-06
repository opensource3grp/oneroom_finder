import 'package:flutter/material.dart';
import 'package:oneroom_finder/home_screen.dart';

// 환영 메시지 스플래시 화면
class WelcomeSplashScreen extends StatefulWidget {
  final String nickname;
  final String job;
  final String uid;

  const WelcomeSplashScreen({
    super.key,
    required this.nickname,
    required this.job,
    required this.uid,
  });

  @override
  State<WelcomeSplashScreen> createState() => _WelcomeSplashScreenState();
}

class _WelcomeSplashScreenState extends State<WelcomeSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHomeAfterDelay();
  }

  Future<void> _navigateToHomeAfterDelay() async {
    // 5초 후 홈 화면으로 이동
    await Future.delayed(const Duration(seconds: 5));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          uid: widget.uid,
          nickname: widget.nickname,
          job: widget.job,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '반갑습니다, ${widget.job} ${widget.nickname}님!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '잠시만 기다려주세요...',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
