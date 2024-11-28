// signup_screen.dart

import 'package:flutter/material.dart';
import 'package:oneroom_finder/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth 추가

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  _LoginSignupScreenState createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  bool isLogin = true;
  String? selectedJob;
  bool isAutoLogin = false;

  final List<String> jobOptions = ['학생', '공인중개사'];
  
  final TextEditingController emailController = TextEditingController(); // 이메일 컨트롤러
  final TextEditingController passwordController = TextEditingController(); // 비밀번호 컨트롤러
  final TextEditingController nicknameController = TextEditingController(); // 닉네임 컨트롤러

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
              if (isLogin) ...[
                const Text(
                  '안녕하세요\n이메일로 로그인해 주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                _buildEmailField(), // 이메일 입력 필드
                _buildPasswordField(), // 비밀번호 입력 필드
                _buildAutoLoginCheckbox(),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    developer.log('Login button clicked');
                    try {
                      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setBool('autoLogin', isAutoLogin);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen(posts: [])),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인 실패: $e')));
                    }
                  },
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
              ] else ...[
                const Text(
                  '안녕하세요\n이메일로 회원가입 해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                _buildEmailField(), // 이메일 입력 필드
                _buildPasswordField(), // 비밀번호 입력 필드
                _buildPasswordConfirmField(), // 비밀번호 확인 필드
                _buildTextField('닉네임'), // 닉네임 입력 필드
                _buildDropdownField('직업 선택', jobOptions, selectedJob, (value) {
                  setState(() {
                    selectedJob = value;
                  });
                }),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    developer.log('Signup button clicked');
                    try {
                      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                      // 추가적으로 사용자 정보를 Firestore에 저장하는 로직을 추가할 수 있습니다.
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeScreen(posts: [])),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('회원가입 실패: $e')));
                    }
                  },
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() { // 이메일 입력 필드 생성
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

  Widget _buildPasswordField() { // 비밀번호 입력 필드 생성
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

  Widget _buildPasswordConfirmField() { // 비밀번호 확인 필드 생성
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        decoration: const InputDecoration(
          labelText: '비밀번호 확인',
          border: OutlineInputBorder(),
        ),
        obscureText: true,
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? selectedItem, ValueChanged<String?> onChanged) { // 드롭다운 필드 생성
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child:
          DropdownButtonFormField<String>(
            decoration:
            InputDecoration(labelText:
            label, border:
            const OutlineInputBorder()),
            value:
            selectedItem,
            items:
            items.map((item) =>
            DropdownMenuItem(value:
            item, child:
            Text(item))).toList(),
            onChanged:
            onChanged,
          ));
  }

  Widget _buildTextField(String label) { // 일반 텍스트 필드 생성
    return Padding(
      padding:
      const EdgeInsets.only(top:
      10),
      child:
      TextFormField(decoration:
      InputDecoration(labelText:
      label, border:
      const OutlineInputBorder()),));
  }

  Widget _buildAutoLoginCheckbox() { // 자동 로그인 체크박스 생성
    return Row(mainAxisAlignment:
    MainAxisAlignment.start, children:[
      Checkbox(value:isAutoLogin,onChanged:(value){
        setState(() {
          isAutoLogin =
          value ?? false;
        });
      },),const
      Text('자동 로그인'),],);
  }
}