import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 로그인 여부 체크
  Future<bool> isUserLoggedIn() async {
    final currentUser = _auth.currentUser;
    return currentUser != null;
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

  // 사용자 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 현재 로그인한 사용자 정보 반환
  User? get currentUser {
    return _auth.currentUser;
  }
}
