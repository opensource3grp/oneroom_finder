import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatRoomScreen extends StatelessWidget {
  final String chatRoomId;
  final String userJob; // 직업을 전달받는 변수 추가

  const ChatRoomScreen(
      {super.key, required this.chatRoomId, required this.userJob});

  @override
  Widget build(BuildContext context) {
    final TextEditingController messageController = TextEditingController();
// 직업에 따른 배경색 설정
    Color messageColor = userJob == '학생' ? Colors.orange : Colors.blue;
    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅방'),
        backgroundColor: messageColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      '메시지가 없습니다.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final messageData = message.data() as Map<String, dynamic>;
                    final sender = messageData['sender'] ?? '알 수 없음';
                    final text = messageData['text'] ?? '';
                    final isMe = sender ==
                        FirebaseAuth.instance.currentUser?.displayName;

                    // 메시지의 배경 색상을 직업에 맞게 변경
                    Color messageBackgroundColor = isMe
                        ? messageColor // 내 메시지는 직업에 맞는 색
                        : Colors.grey[300]!; // 상대방 메시지 배경은 기본 색

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: messageBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: '메시지 입력...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.orange),
                  onPressed: () async {
                    final text = messageController.text.trim();
                    if (text.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('chatRooms')
                          .doc(chatRoomId)
                          .collection('messages')
                          .add({
                        'text': text,
                        'sender':
                            FirebaseAuth.instance.currentUser?.displayName ??
                                '알 수 없음',
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
