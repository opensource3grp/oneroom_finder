import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'comment.dart';
import 'post_service.dart';

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

  Future<void> _deletePost(BuildContext context) async {
    try {
      await PostService().deletePost(postId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 삭제되었습니다.')),
      );
      Navigator.of(context).pop(); // 삭제 후 이전 화면으로 이동
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 삭제 중 오류 발생: $e')),
      );
    }
  }

  Future<void> _showEditDialog(
      BuildContext context, String currentTitle, String currentContent) async {
    final titleController = TextEditingController(text: currentTitle);
    final contentController = TextEditingController(text: currentContent);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('게시글 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '제목'),
                ),
                const SizedBox(height: 8.0),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(labelText: '내용'),
                  maxLines: 4,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                final newTitle = titleController.text.trim();
                final newContent = contentController.text.trim();
                if (newTitle.isNotEmpty && newContent.isNotEmpty) {
                  await PostService().updatePost(postId, newTitle, newContent);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('게시글이 수정되었습니다.')),
                  );
                  Navigator.of(context).pop(); // 수정 후 다이얼로그 닫기
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
                  );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('원룸 상세 정보'),
        backgroundColor: Colors.orange,
        actions: [
          // 우측 상단에 세로 점 3개 (게시글 수정 및 삭제)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                // 수정 버튼 클릭
                showDialog(
                  context: context,
                  builder: (context) {
                    return StreamBuilder<DocumentSnapshot>(
                      stream: fetchPostDetails(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Center(child: Text('오류가 발생했습니다.'));
                        }

                        final post =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final currentTitle = post['title'] ?? '';
                        final currentContent = post['content'] ?? '';

                        return AlertDialog(
                          title: const Text('게시글 수정'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller:
                                      TextEditingController(text: currentTitle),
                                  decoration:
                                      const InputDecoration(labelText: '제목'),
                                ),
                                const SizedBox(height: 8.0),
                                TextField(
                                  controller: TextEditingController(
                                      text: currentContent),
                                  decoration:
                                      const InputDecoration(labelText: '내용'),
                                  maxLines: 4,
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('취소'),
                            ),
                            TextButton(
                              onPressed: () async {
                                final newTitle = currentTitle;
                                final newContent = currentContent;
                                if (newTitle.isNotEmpty &&
                                    newContent.isNotEmpty) {
                                  await PostService()
                                      .updatePost(postId, newTitle, newContent);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('게시글이 수정되었습니다.')),
                                  );
                                  Navigator.of(context).pop(); // 수정 후 다이얼로그 닫기
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('제목과 내용을 입력해주세요.')),
                                  );
                                }
                              },
                              child: const Text('수정'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              } else if (value == 'delete') {
                // 삭제 버튼 클릭
                _deletePost(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('게시글 수정'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('게시글 삭제'),
                ),
              ];
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: fetchPostDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

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

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '위치 : ${post['location']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '작성자: $author',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
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
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // 댓글 입력 및 리스트 추가
                  CommentInputField(postId: postId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
