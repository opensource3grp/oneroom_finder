import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_card.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  _PostListScreenState createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _postStream;
  String _selectedFilter = '최신순'; // Default filter option

  @override
  void initState() {
    super.initState();
    _updatePostStream();
  }

  // Update the post stream based on the selected filter
  void _updatePostStream() {
    Query postsQuery = _firestore.collection('posts');

// 필터에 맞는 쿼리 조건 추가
    if (_selectedFilter == '거래 가능') {
      postsQuery = postsQuery
          .where('status', isEqualTo: null)
          .where('status', isNotEqualTo: '거래 완료');
    } else if (_selectedFilter == '거래 완료') {
      postsQuery = postsQuery.where('status', isEqualTo: '거래 완료');
    }

    switch (_selectedFilter) {
      case '최신순':
        postsQuery = postsQuery.orderBy('createAt', descending: true);
        break;
      case '양도':
        postsQuery = postsQuery.where('tag', isEqualTo: '양도');
        break;
      case '매매':
        postsQuery = postsQuery.where('tag', isEqualTo: '매매');
        break;
      case '후기많은순':
        // 후기 많은 순 정렬은 이후 처리
        break;
    }

    _postStream = postsQuery.snapshots();
  }

  Future<void> _handleLikePressed(
      String postId, bool isLiked, int currentLikes) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);

      // Toggle the like status
      await postRef.update({
        'likes': isLiked ? currentLikes - 1 : currentLikes + 1,
      });
    } catch (e) {
      print('Error updating like count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 목록'),
        actions: [
          DropdownButton<String>(
            value: _selectedFilter,
            icon: const Icon(Icons.filter_list),
            onChanged: (String? newValue) {
              setState(() {
                _selectedFilter = newValue!;
                _updatePostStream();
              });
            },
            items: ['최신순', '후기많은순', '양도', '매매', '거래 가능', '거래 완료']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _postStream,
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

          List<QueryDocumentSnapshot> posts = snapshot.data!.docs;

          if (_selectedFilter == '후기많은순') {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _getPostsWithReviewCounts(posts),
              builder: (context, futureSnapshot) {
                if (futureSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final sortedPosts = futureSnapshot.data ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: sortedPosts.length,
                  itemBuilder: (context, index) {
                    final post = sortedPosts[index];
                    return PostCard(
                      tag: post['tag'] ?? '',
                      post: post['postDoc'],
                      title: post['title'] ?? '제목 없음',
                      content: post['content'] ?? '내용 없음',
                      location: post['location'] ?? '위치 없음',
                      price: post['price'] ?? '가격 정보 없음',
                      author: post['author'] ?? '작성자 없음',
                      image: post['image'] ?? '',
                      review: post['review'] ?? 0,
                      likes: post['likes'] ?? 0,
                      postId: post['postDoc'].id,
                      status: post['status'] ?? '거래 가능',
                      isLiked: post['isLiked'] ?? false,
                      onLikePressed: () {
                        _handleLikePressed(post['postDoc'].id,
                            post['isLiked'] ?? false, post['likes']);
                      },
                    );
                  },
                );
              },
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final postData = posts[index].data() as Map<String, dynamic>;
                return PostCard(
                  tag: postData['tag'] ?? '',
                  post: posts[index],
                  title: postData['title'] ?? '제목 없음',
                  content: postData['content'] ?? '내용 없음',
                  location: postData['location'] ?? '위치 없음',
                  price: postData['price'] ?? '가격 정보 없음',
                  author: postData['author'] ?? '작성자 없음',
                  image: postData['image'] ?? '',
                  review: postData['review'] ?? 0,
                  likes: postData['likes'] ?? 0,
                  postId: posts[index].id,
                  status: postData['status'] ?? '거래 가능',
                  isLiked: postData['isLiked'] ?? false,
                  onLikePressed: () {
                    _handleLikePressed(posts[index].id,
                        postData['isLiked'] ?? false, postData['likes']);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getPostsWithReviewCounts(
      List<QueryDocumentSnapshot> posts) async {
    final List<Map<String, dynamic>> postsWithCounts = [];

    for (var post in posts) {
      final postData = post.data() as Map<String, dynamic>;
      final commentsSnapshot =
          await _firestore.collection('posts/${post.id}/comments').get();
      final review = commentsSnapshot.docs.length;

      postsWithCounts.add({
        'postDoc': post,
        'title': postData['title'],
        'content': postData['content'],
        'location': postData['location'],
        'price': postData['price'],
        'author': postData['author'],
        'image': postData['image'],
        'tag': postData['tag'],
        'review': review,
        'isLiked': postData['isLiked'] ?? false,
        'likes': postData['likes'] ?? 0,
        'createAt': postData['createAt'],
      });
    }

    if (_selectedFilter == '후기많은순') {
      postsWithCounts.sort((a, b) {
        return b['review'].compareTo(a['review']);
      });
    }
    return postsWithCounts;
  }
}
