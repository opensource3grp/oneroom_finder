import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/comment.dart';

class RoomDetailsScreen extends StatelessWidget {
  final String postId;

  const RoomDetailsScreen({super.key, required this.postId});

  // Firestore에서 데이터를 실시간으로 가져오기 위해 StreamBuilder 사용
  Stream<DocumentSnapshot> fetchPostDetails() {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('원룸 상세 정보'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: fetchPostDetails(),
        builder: (context, snapshot) {
          // 대기 중일 때 로딩 표시
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 에러 발생 시 표시
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('게시글이 존재하지 않습니다.'));
          }

          final post = snapshot.data!.data() as Map<String, dynamic>;
          final String tag = post['tag'] ?? '태그 없음';
          final String title = post['title'] ?? '제목 없음';
          final String content = post['content'] ?? '내용 없음';
          final String author = post['author'] ?? '익명';
          final int likes = post['likes'] ?? 0;
          final List<dynamic> comments = post['comments'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tag),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text('위치 : ${post['location']}'),
                const SizedBox(height: 8.0),
                Text(
                  '작성자: $author',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16.0),
                Text(
                  content,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    const Icon(Icons.thumb_up, color: Colors.orange),
                    const SizedBox(width: 8.0),
                    Text('$likes명이 좋아합니다.'),
                  ],
                ),
                const SizedBox(height: 24.0),
                const Divider(),
                const Text(
                  '댓글',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                comments.isEmpty
                    ? const Text('아직 댓글이 없습니다.')
                    : Column(
                        children: comments
                            .map((comment) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.comment,
                                          color: Colors.grey),
                                      const SizedBox(width: 8.0),
                                      Expanded(
                                        child: Text(comment.toString()),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      ),
                const Divider(),
                const SizedBox(height: 8.0),
                CommentInputField(postId: postId), // 댓글 작성 입력 필드
              ],
            ),
          );
        },
      ),
    );
  }
}
