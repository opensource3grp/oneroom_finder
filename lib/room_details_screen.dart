import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoomDetailsScreen extends StatelessWidget {
  final String postId;

  const RoomDetailsScreen({super.key, required this.postId});
  Future<Map<String, dynamic>> fetchPostDetails() async {
    final docSnapshot =
        await FirebaseFirestore.instance.collection('posts').doc(postId).get();

    if (!docSnapshot.exists) {
      throw Exception('Post not found');
    }

    return docSnapshot.data() as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('원룸 상세 정보'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchPostDetails(),
        builder: (context, snapshot) {
          // 대기 중일 때 로딩 표시
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 에러 발생 시 표시
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // 게시글 데이터 가져오기
          final post = snapshot.data!;
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
                // 게시글 제목
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                // 작성자 정보
                Text(
                  '작성자: $author',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16.0),
                // 게시글 내용
                Text(
                  content,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16.0),
                // 좋아요 정보
                Row(
                  children: [
                    const Icon(Icons.thumb_up, color: Colors.orange),
                    const SizedBox(width: 8.0),
                    Text('$likes명이 좋아합니다.'),
                  ],
                ),
                const SizedBox(height: 24.0),
                const Divider(),
                // 댓글 섹션
                const Text(
                  '댓글',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                if (comments.isEmpty)
                  const Text('아직 댓글이 없습니다.')
                else
                  ...comments.map((comment) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.comment, color: Colors.grey),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(comment.toString()),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                const Divider(),
                // 댓글 작성 입력 필드
                const SizedBox(height: 8.0),
                CommentInputField(postId: postId),
              ],
            ),
          );
        },
      ),
    );
  }
}

class CommentInputField extends StatefulWidget {
  final String postId;

  const CommentInputField({super.key, required this.postId});

  @override
  _CommentInputFieldState createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  final TextEditingController _commentController = TextEditingController();

  void _addComment() async {
    final comment = _commentController.text.trim();

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글을 입력하세요.')),
      );
      return;
    }

    // Firestore에 댓글 추가
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    await postRef.update({
      'comments': FieldValue.arrayUnion([comment]),
    });

    _commentController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('댓글이 추가되었습니다.')),
    );

    setState(() {}); // 화면 갱신
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: '댓글을 입력하세요...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        IconButton(
          onPressed: _addComment,
          icon: const Icon(Icons.send, color: Colors.orange),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
