import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'room_details_screen.dart';
import 'post_service.dart';

class HomeScreen extends StatelessWidget {
  final PostService post = PostService();

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('원룸 알리미'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: post.getPosts(), //firebase에서 데이터 들고옴
        builder: (context, snapshot) {
          //대기해야할때??
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          //에러 Handler
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          //게시글이 없는 경우
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('게시글이 없습니다.'));
          }
          final posts = snapshot.data!.docs;
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(posts[index]['title'] ?? '제목 없음'),
                onTap: () {
                  //게시글 내용으로 이동됨
                },
              );
            },
          );
        },
      ),
      //게시글 작성
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await post.createPost('제목', '내용');
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
