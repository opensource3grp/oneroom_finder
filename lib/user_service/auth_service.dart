import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/user_service/signup_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 로그인 여부 체크
  Future<bool> isUserLoggedIn() async {
    final currentUser = _auth.currentUser;
    return currentUser != null;
  }

  static Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      // 로그인/회원가입 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginSignupScreen()),
      );
    } catch (e) {
      print("Logout failed: $e");
      // 로그아웃 실패 시 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("로그아웃에 실패했습니다: $e")),
      );
    }
  }

  // 로그인한 사용자 UID 반환
  String? getUserId() {
    return _auth.currentUser?.uid;
  }

  // 사용자 로그인
  Future<UserCredential?> signInWithEmailPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      print('로그인 실패: $e');
      return null;
    }
  }

  // 현재 로그인한 사용자 정보 반환
  User? get currentUser {
    return _auth.currentUser;
  }
}
