// signup_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth 추가
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 추가
import 'package:oneroom_finder/user_service/welcome_splash_screen.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});
  @override
  // ignore: library_private_types_in_public_api
  _LoginSignupScreenState createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  bool isLogin = true;
  String? selectedJob;
  bool isAutoLogin = false;

  final List<String> jobOptions = ['학생', '공인중개사'];

  final TextEditingController emailController =
      TextEditingController(); // 이메일 컨트롤러
  final TextEditingController passwordController =
      TextEditingController(); // 비밀번호 컨트롤러
  final TextEditingController passwordConfirmController =
      TextEditingController();
  final TextEditingController nicknameController =
      TextEditingController(); // 닉네임 컨트롤러

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final nickname = userDoc.data()?['nickname'] ?? '알 수 없음';
      final job = userDoc.data()?['job'] ?? '직업 없음';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomeSplashScreen(
            uid: user.uid,
            nickname: nickname,
            job: job,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('원룸알리미'),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLogin) _buildLoginForm() else _buildSignupForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        const Text(
          '안녕하세요\n이메일로 로그인해 주세요',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        _buildEmailField(),
        _buildPasswordField(),
        _buildAutoLoginCheckbox(),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _login,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('로그인'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              isLogin = false;
            });
          },
          child: const Text('회원가입'),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      children: [
        const Text(
          '안녕하세요\n이메일로 회원가입 해주세요',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
        _buildEmailField(),
        _buildPasswordField(),
        _buildPasswordConfirmField(),
        _buildTextField('닉네임'),
        _buildDropdownField('직업 선택', jobOptions, selectedJob, (value) {
          setState(() {
            selectedJob = value;
          });
        }),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _signup,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('회원가입'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              isLogin = true;
            });
          },
          child: const Text('로그인으로 돌아가기'),
        ),
      ],
    );
  }

  Future<void> _login() async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userId = userCredential.user?.uid;
      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final nickname = userDoc.data()?['nickname'] ?? '알 수 없음';
        final job = userDoc.data()?['job'] ?? '직업 없음';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeSplashScreen(
              uid: userId,
              nickname: nickname,
              job: job,
            ),
          ),
        );
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            _showErrorSnackBar('존재하지 않는 사용자입니다.');
            break;
          case 'wrong-password':
            _showErrorSnackBar('잘못된 비밀번호입니다.');
            break;
          case 'email-already-in-use':
            _showErrorSnackBar('이미 가입된 이메일입니다.');
            break;
          default:
            _showErrorSnackBar('로그인 실패: ${e.message}');
        }
      } else {
        _showErrorSnackBar('알 수 없는 오류 발생: $e');
      }
    }
  }

  Future<void> _signup() async {
    if (passwordController.text.trim() !=
        passwordConfirmController.text.trim()) {
      _showErrorSnackBar('비밀번호가 일치하지 않습니다.');
      return;
    }

    if (nicknameController.text.trim().isEmpty || selectedJob == null) {
      _showErrorSnackBar('닉네임과 직업을 입력해 주세요.');
      return;
    }

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final userId = userCredential.user?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'nickname': nicknameController.text.trim(),
          'job': selectedJob,
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeSplashScreen(
              uid: userId,
              nickname: nicknameController.text.trim(),
              job: selectedJob ?? '직업 없음',
            ),
          ),
        );
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            _showErrorSnackBar('이미 가입된 이메일입니다.');
            break;
          default:
            _showErrorSnackBar('회원가입 실패: ${e.message}');
        }
      } else {
        _showErrorSnackBar('알 수 없는 오류 발생: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildEmailField() {
    // 이메일 입력 필드 생성
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: emailController,
        decoration: const InputDecoration(
          labelText: '이메일',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.emailAddress,
      ),
    );
  }

  Widget _buildPasswordField() {
    // 비밀번호 입력 필드 생성
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: passwordController,
        decoration: const InputDecoration(
          labelText: '비밀번호',
          border: OutlineInputBorder(),
        ),
        obscureText: true,
      ),
    );
  }

//비밀번호 확인 필드
  Widget _buildPasswordConfirmField() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: passwordConfirmController,
        decoration: const InputDecoration(
          labelText: '비밀번호 확인',
          border: OutlineInputBorder(),
        ),
        obscureText: true,
      ),
    );
  }

// 닉네임 입력 필드 생성
  Widget _buildTextField(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        controller: nicknameController,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items,
      String? selectedItem, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        value: selectedItem,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildAutoLoginCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: isAutoLogin,
          onChanged: (value) {
            setState(() {
              isAutoLogin = value ?? false;
            });
          },
        ),
        const Text('자동 로그인'),
      ],
    );
  }
}
