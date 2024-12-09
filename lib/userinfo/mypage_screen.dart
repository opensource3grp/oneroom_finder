import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oneroom_finder/post/user_service/auth_service.dart';

class MyPageScreen extends StatefulWidget {
  final String userId;
  const MyPageScreen({super.key, required this.userId});
  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String? _nickname;
  bool _isLoading = true;
  late String _job;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>? ?? {};
        setState(() {
          _nickname = data['nickname'] ?? '닉네임 없음';
          _job = data['job'] ?? '학생';
          _isLoading = false;
        });
      } else {
        throw 'User document does not exist';
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('데이터를 불러오는 중 오류 발생: $e')),
      );
    }
  }

  Future<void> _changeNickname() async {
    TextEditingController nicknameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('닉네임 변경'),
          content: TextField(
            controller: nicknameController,
            maxLength: 20,
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
                if (newNickname.isEmpty || newNickname.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('닉네임은 최소 3자 이상 입력해주세요.')),
                  );
                  return;
                }
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
      return Scaffold(
        appBar: AppBar(title: const Text('마이페이지')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            CircleAvatar(
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
