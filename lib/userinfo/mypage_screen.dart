import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:oneroom_finder/home_screen.dart';
import 'package:oneroom_finder/user_service/auth_service.dart';
//import 'package:oneroom_finder/user_service/signup_screen.dart';

class MyPageScreen extends StatefulWidget {
  final String userId;
  const MyPageScreen({super.key, required this.userId});
  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String? _nickname; // 닉네임 저장 변수
  bool _isLoading = true; // 데이터 로딩 상태
  late String _job; // 직업 저장 변수

  // final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Firestore에서 사용자 데이터 가져오기
  Future<void> _fetchUserData() async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _nickname = data['nickname'] ?? '닉네임 없음';
          _job = data['job'] ?? '학생'; // 직업 정보 가져오기
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching user data: $e');
    }
  }

  // 닉네임 변경 다이얼로그
  Future<void> _changeNickname() async {
    TextEditingController nicknameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('닉네임 변경'),
          content: TextField(
            controller: nicknameController,
            decoration: const InputDecoration(hintText: '새 닉네임 입력'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                final newNickname = nicknameController.text.trim();
                if (newNickname.isNotEmpty) {
                  try {
                    await _firestore
                        .collection('users')
                        .doc(widget.userId)
                        .update({'nickname': newNickname});
                    setState(() {
                      _nickname = newNickname;
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('닉네임이 "$newNickname"으로 변경되었습니다.')),
                    );
                  } catch (e) {
                    print('Error updating nickname: $e');
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('변경'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 직업에 따른 색상 설정
    Color appBarColor = _job == '학생' ? Colors.orange : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: appBarColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile_placeholder.png'),
            ),
            const SizedBox(height: 16),
            Text(
              '닉네임: $_nickname',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _changeNickname,
              child: const Text('닉네임 변경'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                AuthService.logout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
