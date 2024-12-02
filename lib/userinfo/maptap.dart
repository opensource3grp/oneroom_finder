import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'usermodel.dart';

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

// MyPageTab 클래스
class MyPageTab extends StatelessWidget {
  const MyPageTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel>(context);

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
          user.nickname,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          '가입 날짜: ${user.joinDate.year}-${user.joinDate.month}-${user.joinDate.day}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 30),
        _buildMenuItem(context, '최근 본 방', Icons.history, () {
          _showListDialog(context, '최근 본 방', user.recentRooms);
        }),
        _buildMenuItem(context, '관심있는 방', Icons.favorite, () {
          _showListDialog(context, '관심있는 방', user.favoriteRooms);
        }),
        _buildMenuItem(context, '구매 내역', Icons.shopping_cart, () {
          _showListDialog(context, '구매 내역', user.purchaseHistory);
        }),
      ],
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
