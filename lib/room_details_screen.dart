import 'package:flutter/material.dart';

class RoomDetailsScreen extends StatelessWidget {
  final String location;

  const RoomDetailsScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$location의 원룸 상세 정보'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '위치: $location',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            const Text(
              '세부 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text('방 크기, 가격, 옵션 등을 표시합니다.'),
            const SizedBox(height: 16.0),
            const Text(
              '주변 편의시설',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            const Text('편의점, 카페, 식당 등 주변 시설 정보를 표시합니다.'),
          ],
        ),
      ),
    );
  }
}
