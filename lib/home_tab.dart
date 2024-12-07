import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/post/post_card.dart';
import 'package:oneroom_finder/post/post_list_screen.dart';
import 'package:oneroom_finder/post/post_service.dart';
import 'package:oneroom_finder/post/room_details_screen.dart';

class HomeTab extends StatefulWidget {
  final Function onLikePressed;
  final Map<String, bool> likedPosts;

  const HomeTab(
      {Key? key, required this.onLikePressed, required this.likedPosts})
      : super(key: key);

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final PostService postService = PostService();
  late Map<String, bool> likedPosts;

  @override
  void initState() {
    super.initState();
    likedPosts = {}; // Initialize liked posts map
  }

  void _toggleLike(String postId, int currentLikes) async {
    final newLikeStatus = !(likedPosts[postId] ?? false);
    final updatedLikes = newLikeStatus ? currentLikes + 1 : currentLikes - 1;

    setState(() {
      likedPosts[postId] = newLikeStatus;
    });

    try {
      await postService.updatePostLikes(postId, updatedLikes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("금오공대"),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort), // 정렬 버튼
            onPressed: () {
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
        stream: postService.getPosts(),
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
              final postData = post.data() as Map<String, dynamic>;

              final postId = post.id;
              final title = postData['title'] ?? '제목 없음';
              final content = postData['content'] ?? '내용 없음';
              final location = postData['location'] ?? '위치 없음';
              final price = postData['price'] ?? '가격 정보 없음';
              final author = postData['author'] ?? '작성자 없음';
              final image = postData['image'] ?? '';
              final tag = postData['tag'] ?? '';
              final likes = postData['likes'] ?? 0;
              final status = postData['status'] ?? '거래 가능';
              final isLiked = likedPosts[postId] ?? false;

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
                    onTap: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomDetailsScreen(
                            postId: postId,
                            initialLikes: likes,
                            initialIsLiked: isLiked,
                          ),
                        ),
                      );

                      // 상세 화면에서 돌아왔을 때 좋아요 상태 업데이트
                      if (updated != null && updated is Map<String, dynamic>) {
                        setState(() {
                          likedPosts[postId] = updated['isLiked'] ?? isLiked;
                        });
                      }
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
                      review: review, // Firestore에서 commentsCount 가져오기
                      likes: likes,
                      postId: postId,
                      status: status,
                      isLiked: isLiked,
                      onLikePressed: () {
                        _toggleLike(postId, likes);
                      },
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
