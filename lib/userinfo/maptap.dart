import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/userinfo/likepost.dart';
import 'package:oneroom_finder/userinfo/mypage_screen.dart';
import 'package:oneroom_finder/userinfo/userpost.dart';

// MapTab 클래스
class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '지도 탭',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

class MyPageTab extends StatelessWidget {
  const MyPageTab({super.key});

  @override
  Widget build(BuildContext context) {
    //final post = snapshot.data!.data() as Map<String, dynamic>;
    final userId = FirebaseAuth
        .instance.currentUser?.uid; // 유저 ID를 지정 (로그인 상태에서 가져오도록 구현 필요)
    //final String? nickname = post['nickname'];
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('사용자 정보를 불러올 수 없습니다.'));
        }
        final user = snapshot.data!.data() as Map<String, dynamic>;
        final nickname = user['nickname'];
        //final joinDate
        return ListView(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              nickname,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildMenuItem(context, '내 게시글', Icons.article, () {
              showDialog(
                context: context,
                builder: (context) => UserPostsDialog(userId: userId!),
              );
            }),
            _buildMenuItem(context, '관심있는 방', Icons.favorite, () {
              showDialog(
                context: context,
                builder: (context) => LikePostDialog(userId: userId!),
              );
            }),
            _buildMenuItem(context, '구매 내역', Icons.shopping_cart, () {
              _showListDialog(context, '구매 내역', user['purchaseHistory'] ?? []);
            }),
            _buildMenuItem(context, '마이페이지', Icons.person, () {
              showDialog(
                context: context,
                builder: (context) => MyPageScreen(userId: userId!),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  void _showListDialog(BuildContext context, String title, List<String> items) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(items[index]));
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
}
