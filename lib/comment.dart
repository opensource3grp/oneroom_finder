import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommentInputField extends StatefulWidget {
  final String postId;

  const CommentInputField({super.key, required this.postId});

  @override
  _CommentInputFieldState createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  final TextEditingController _commentController = TextEditingController();

  // 댓글 추가 기능
  void _addComment() async {
    final comment = _commentController.text.trim();

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글을 입력하세요.')),
      );
      return;
    }

    // Firestore에 댓글 추가 (중복 허용)
    final postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    // 기존 댓글 리스트를 받아와서 추가
    postRef.get().then((doc) {
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> currentComments = List.from(data['comments'] ?? []);

        // 새 댓글 추가
        currentComments.add(comment);

        // 업데이트
        postRef.update({'comments': currentComments});
      }
    });

    _commentController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('댓글이 추가되었습니다.')),
    );
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
