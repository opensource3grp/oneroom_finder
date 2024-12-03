import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/post/post_card.dart';
import 'package:oneroom_finder/post/post_list_screen.dart';
import 'package:oneroom_finder/post/post_service.dart';
import 'package:oneroom_finder/post/room_details_screen.dart';
import 'package:oneroom_finder/userinfo/recentlyviewed.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final PostService postService = PostService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("금오공대"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort), // 정렬 버튼
            onPressed: () {
              // PostListScreen으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PostListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: postService.getPosts(), // Firestore에서 게시글 스트림 가져오기
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postData = post.data() as Map<String,
                  dynamic>; // DocumentSnapshot의 data()를 Map으로 캐스팅

              final title = postData['title'] ?? '제목 없음';
              final content = postData['content'] ?? '내용 없음';
              final location = postData['location'] ?? '위치 없음';
              final price = postData['price'] ?? '가격 정보 없음';
              final author = postData['author'] ?? '작성자 없음';
              final image = postData['image'] ?? ''; // Image URL or path
              final tag = postData['tag'] ?? ''; // 추가: tag 정보
              final likes = postData['likes'] ?? 0; // likesCount 가져오기

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('posts')
                    .doc(post.id)
                    .collection('comments')
                    .snapshots(), // comments 하위 컬렉션 스트림
                builder: (context, commentSnapshot) {
                  int review = 0;
                  if (commentSnapshot.hasData) {
                    review = commentSnapshot.data!.docs.length; // 후기 개수
                  }
                  return GestureDetector(
                    onTap: () {
                      // 게시글 클릭 시 RoomDetailScreen으로 이동
                      RecentlyViewedManager.addPost(post.id);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RoomDetailsScreen(postId: post.id),
                        ),
                      );
                    },
                    child: PostCard(
                      tag: tag,
                      post: post,
                      title: title,
                      content: content,
                      location: location,
                      price: price,
                      author: author,
                      image: image,
                      review: review,
                      likes: likes,
                      postId: post.id,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
