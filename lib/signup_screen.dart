import 'package:flutter/material.dart';
import 'package:oneroom_finder/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

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
                  '안녕하세요\n휴대폰 번호로 로그인해 주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                _buildPhoneNumberField(),
                _buildPasswordField(),
                _buildAutoLoginCheckbox(),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    developer.log('Login button clicked');
                    final prefs = await SharedPreferences.getInstance();
                    prefs.setBool('autoLogin', isAutoLogin);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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
                  '안녕하세요\n휴대폰 번호로 회원가입 해주세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                _buildPhoneNumberField(),
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
                  onPressed: () {
                    developer.log('Signup button clicked');
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
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

  Widget _buildPhoneNumberField() {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: '휴대폰 번호(숫자만 입력)',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildPasswordField() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        decoration: const InputDecoration(
          labelText: '비밀번호',
          border: OutlineInputBorder(),
        ),
        obscureText: true,
      ),
    );
  }

  Widget _buildPasswordConfirmField() {
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
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(item),
                ))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTextField(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildAutoLoginCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
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
