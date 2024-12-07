import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oneroom_finder/chat_room/chat_create.dart';
import 'package:oneroom_finder/chat_room/chatroom_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageTab extends StatefulWidget {
  final String userJob;
  const MessageTab({super.key, required this.userJob});

  @override
  // ignore: library_private_types_in_public_api
  _MessageTabState createState() => _MessageTabState();
}

class _MessageTabState extends State<MessageTab> {
  bool isEditing = false;
  Set<String> selectedChatRooms = {};

// 메시지를 보내고, 채팅방의 lastMessageTime을 업데이트하는 함수
  Future<void> sendMessage(String chatRoomId, String message) async {
    // 메시지를 'messages' 컬렉션에 추가
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'message': message,
      'senderId': FirebaseAuth.instance.currentUser!.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 해당 채팅방의 'lastMessage'와 'lastMessageTime'을 업데이트
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomId)
        .update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor =
        widget.userJob == '공인중개사' ? Colors.blue : Colors.orange;
    Color avatarColor = primaryColor;
    Color floatingButtonColor = primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('메시지'),
        centerTitle: true,
        backgroundColor: primaryColor,
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                if (selectedChatRooms.isNotEmpty) {
                  for (String chatRoomId in selectedChatRooms) {
                    await FirebaseFirestore.instance
                        .collection('chatRooms')
                        .doc(chatRoomId)
                        .delete();
                  }
                  setState(() {
                    isEditing = false;
                    selectedChatRooms.clear();
                  });
                }
              },
            ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.done),
              onPressed: () {
                setState(() {
                  isEditing = false;
                  selectedChatRooms.clear();
                });
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chatRooms')
            .where('users',
                arrayContains:
                    FirebaseAuth.instance.currentUser!.uid) // 사용자가 포함된 채팅방만 조회
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                '대화방이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final chatRooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final chatRoomData = chatRoom.data() as Map<String, dynamic>;
              final chatRoomName = chatRoomData['name'] ?? '대화방';
              final lastMessage = chatRoomData['lastMessage'] ?? '';
              final lastMessageTime =
                  (chatRoomData['lastMessageTime'] as Timestamp?)?.toDate();
              final unreadCount = chatRoomData['unreadCount'] ?? 0;
              final createdTime =
                  (chatRoomData['createdAt'] as Timestamp?)?.toDate();

              return ListTile(
                title: Text(
                  chatRoomName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastMessage,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if (createdTime != null)
                      Text(
                        '생성일: ${DateFormat('yyyy/MM/dd HH:mm').format(createdTime)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                  ],
                ),
                leading: CircleAvatar(
                  backgroundColor: avatarColor,
                  child: Text(
                    chatRoomName.isNotEmpty ? chatRoomName[0] : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                trailing: isEditing
                    ? Icon(
                        selectedChatRooms.contains(chatRoom.id)
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: selectedChatRooms.contains(chatRoom.id)
                            ? primaryColor
                            : Colors.grey,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (lastMessageTime != null)
                            Text(
                              DateFormat('yyyy.MM.dd HH:mm')
                                  .format(lastMessageTime), // 포맷을 변경
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                onTap: () {
                  if (isEditing) {
                    setState(() {
                      if (selectedChatRooms.contains(chatRoom.id)) {
                        selectedChatRooms.remove(chatRoom.id);
                      } else {
                        selectedChatRooms.add(chatRoom.id);
                      }
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomScreen(
                            chatRoomId: chatRoom.id, userJob: widget.userJob),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateChatRoomDialog(),
          );
        },
        backgroundColor: floatingButtonColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}
