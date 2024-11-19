import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/post_create_screen.dart';
import 'room_details_screen.dart';
import 'post_service.dart';

class HomeScreen extends StatelessWidget {
  final PostService postService = PostService(); // PostService 인스턴스

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('원룸 알리미'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: postService.getPosts(), // Firebase에서 게시글 가져오기
        builder: (context, snapshot) {
          // 로딩 상태 처리
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 에러 처리
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // 게시글이 없을 경우
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                '게시글이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final posts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final title = post['title'] ?? '제목 없음';
              final content = post['content'] ?? '내용 없음';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  onTap: () {
                    // 게시글 상세 보기 화면으로 이동
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomDetailsScreen(
                          postId: post.id,
                          location: '',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 게시글 작성 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostCreateScreen(postService: postService),
            ),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
