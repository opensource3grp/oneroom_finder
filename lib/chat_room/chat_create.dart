import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateChatRoomDialog extends StatelessWidget {
  const CreateChatRoomDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController chatRoomNameController =
        TextEditingController();

    return AlertDialog(
      title: const Text('채팅방 생성'),
      content: TextField(
        controller: chatRoomNameController,
        decoration: const InputDecoration(hintText: '채팅방 이름을 입력하세요'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () async {
            final chatRoomName = chatRoomNameController.text.trim();
            if (chatRoomName.isNotEmpty) {
              await FirebaseFirestore.instance.collection('chatRooms').add({
                'name': chatRoomName,
                'lastMessage': '',
                'lastMessageTime': FieldValue.serverTimestamp(),
                'users': [
                  FirebaseAuth.instance.currentUser!.uid
                ], // 현재 사용자의 ID를 users 배열에 추가
                'createdAt': FieldValue.serverTimestamp(), // 생성 시간
                'unreadCount': 0, // 읽지 않은 메시지 개수
              });
              Navigator.of(context).pop();
            }
          },
          child: const Text('생성'),
        ),
      ],
    );
  }
}
