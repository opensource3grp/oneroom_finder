import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class RoomDetailsScreen extends StatelessWidget {
  final String? postId;
  final Map<String, dynamic>? post;
  final Function(int, Map<String, dynamic>) updatePost; // 업데이트 함수 추가

  const RoomDetailsScreen({
    super.key,
    required this.post,
    required this.postId,
    required this.updatePost, // Receive updatePost in the constructor
  });

  Future<Map<String, dynamic>> fetchPostDetails() async {
    if (post != null) {
      return post!;
    } else if (postId != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();
      if (!docSnapshot.exists) {
        throw Exception('Post not found');
      }
      return docSnapshot.data() as Map<String, dynamic>;
    } else {
      throw Exception('게시글 정보가 부족합니다.');
    }
  }

  Future<void> _toggleLike(int currentLikes) async {
    if (postId != null) {
      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);
      await postRef.update({
        'likes': currentLikes + 1,
      });
    }

    // 로컬 데이터 업데이트
    final updatedPost = Map<String, dynamic>.from(post!);
    updatedPost['likes'] = currentLikes + 1;

    updatePost(0, updatedPost); // HomeScreen에서 0번 인덱스 게시물 업데이트
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final postData = snapshot.data ?? post!;
          final String title = postData['title'] ?? '제목 없음';
          final String location = postData['location'] ?? '위치 없음';
          final String price = postData['price'] ?? '가격 없음';
          final String author = postData['author'] ?? '익명';
          final String detail = postData['detail'] ?? '상세 정보 없음';
          final int likes = postData['likes'] ?? 0;
          final List<dynamic> comments = postData['comments'] ?? [];
          final File? image = postData['image'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('위치: $location'),
                Text('가격: $price',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                Text('작성자: $author',
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Text(detail, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                if (image != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Image.file(image, fit: BoxFit.cover),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        _toggleLike(likes); // 하트 버튼 눌렀을 때
                      },
                      child: Icon(
                        likes > 0 ? Icons.favorite : Icons.favorite_border,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$likes명이 좋아합니다.'), // 좋아요 카운트 표시
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const Text(
                  '댓글',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(comment.toString()),
                          ),
                        ],
                      ),
                    );
                  }),
                const Divider(),
                const SizedBox(height: 8),
                if (postId != null) CommentInputField(postId: postId!),
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
  // ignore: library_private_types_in_public_api
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
    // ignore: use_build_context_synchronously
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
