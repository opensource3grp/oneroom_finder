import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 채팅방을 생성합니다.
  Future<void> createChatRoom(String postId, String authorId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('로그인이 필요합니다.');
    if (currentUser.uid == authorId) throw Exception('자신의 글에는 채팅을 할 수 없습니다.');

    // 고유한 채팅방 ID 생성
    final chatRoomId = '${postId}_${authorId}_${currentUser.uid}';
    
    // Firestore에 채팅방 정보 저장
    await _firestore.collection('chatRooms').doc(chatRoomId).set({
      'participants': [currentUser.uid, authorId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  /// 메시지를 전송합니다.
  Future<void> sendMessage(String chatRoomId, String message) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('로그인이 필요합니다.');

    // 메시지를 Firestore에 저장
    await _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'sender': currentUser.uid,
      'content': message,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 마지막 메시지 및 시간을 업데이트
    await _firestore.collection('chatRooms').doc(chatRoomId).update({
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  /// 특정 채팅방의 메시지를 스트리밍합니다.
  Stream<QuerySnapshot> getChatMessages(String chatRoomId) {
    return _firestore
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
