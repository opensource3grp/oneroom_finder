import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/post/post_service.dart';

class CommentInputField extends StatefulWidget {
  final String postId;

  const CommentInputField({super.key, required this.postId});

  @override
  _CommentInputFieldState createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  final TextEditingController _commentController = TextEditingController();
  final PostService postService = PostService();
  Future<void> _addComment() async {
    final comment = _commentController.text.trim();

    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글을 입력하세요.')),
      );
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('로그인 상태를 확인해주세요.');
      }
      final nickname = currentUser.displayName ?? 'null';
      final commentRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc();

      await commentRef.set({
        'content': comment,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': currentUser.uid,
        'nickname': nickname,
      });
      await postService.incrementComments(widget.postId);
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 추가되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 추가 중 오류 발생: $e')),
      );
    }
  }

  Future<void> _deleteComment(String commentId, String commentUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('로그인 상태를 확인해주세요.');
      }

      if (currentUser.uid != commentUserId) {
        throw Exception('삭제 권한이 없습니다.');
      }
      final commentRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId);

      await commentRef.delete();
      await _updateCommentCount();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 삭제 중 오류 발생: $e')),
      );
    }
  }

  Future<void> _editComment(
      String commentId, String newContent, String commentUserId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || currentUser.uid != commentUserId) {
        throw Exception('수정 권한이 없습니다.');
      }
      final commentRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .doc(commentId);

      await commentRef.update({'content': newContent});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('댓글이 수정되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 수정 중 오류 발생: $e')),
      );
    }
  }

  Future<void> _updateCommentCount() async {
    try {
      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(widget.postId);

      // 댓글 수를 가져옵니다.
      final commentsSnapshot = await postRef.collection('comments').get();
      final commentCount = commentsSnapshot.docs.length;

      // 댓글 수를 업데이트합니다.
      await postRef.update({'review': commentCount});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('댓글 수 업데이트 중 오류 발생: $e')),
      );
    }
  }

  Future<void> _showEditDialog(
      String commentId, String currentContent, String commentUserId) async {
    final editController = TextEditingController(text: currentContent);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('댓글 수정'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              hintText: '수정할 내용을 입력하세요...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                final newContent = editController.text.trim();
                if (newContent.isNotEmpty) {
                  _editComment(commentId, newContent, commentUserId);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('수정'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 댓글 입력 필드
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
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
          ),
        ),

        // 댓글 리스트
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 300, // 댓글 리스트의 최대 높이 설정
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .doc(widget.postId)
                .collection('comments')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('오류가 발생했습니다: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('아직 댓글이 없습니다. 첫 번째 댓글을 추가해보세요!'),
                );
              }

              final comments = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  final content = comment['content'] as String? ?? '내용 없음';
                  final commentId = comment.id;
                  final commentUserId = comment['userId'] as String? ?? '';
                  final nickname = comment['nickname'] as String? ?? 'null';
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(nickname[0]),
                    ),
                    title: Text(content),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditDialog(commentId, content, commentUserId);
                        } else if (value == 'delete') {
                          _deleteComment(commentId, commentUserId);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('수정'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('삭제'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
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
