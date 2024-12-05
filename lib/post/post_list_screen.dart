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
  String _selectedSort = '최신순'; // Default sorting option

  @override
  void initState() {
    super.initState();
    _updatePostStream();
  }

  // Update the post stream based on the selected sorting option
  void _updatePostStream() {
    switch (_selectedSort) {
      case '최신순':
        _postStream = _firestore
            .collection('posts')
            .orderBy('createAt', descending: true) // Sort by creation date
            .snapshots();
        break;
      case '인기순':
        _postStream = _firestore
            .collection('posts')
            .orderBy('likesCount', descending: true) // Sort by likes
            .snapshots();
        break;
      case '팝니다만':
        _postStream = _firestore
            .collection('posts')
            .where('tag', isEqualTo: '팝니다') // Filter posts by "팝니다" tag
            .snapshots();
        break;
      case '삽니다만':
        _postStream = _firestore
            .collection('posts')
            .where('tag', isEqualTo: '삽니다') // Filter posts by "삽니다" tag
            .snapshots();
        break;
      case '후기많은순':
        _postStream = _firestore.collection('posts').snapshots();
        break;
      default:
        _postStream = _firestore.collection('posts').snapshots();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 목록'),
        actions: [
          DropdownButton<String>(
            value: _selectedSort,
            icon: const Icon(Icons.sort),
            onChanged: (String? newValue) {
              setState(() {
                _selectedSort = newValue!;
                _updatePostStream();
              });
            },
            items: ['최신순', '후기많은순', '인기순', '팝니다만', '삽니다만']
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

          if (_selectedSort == '후기많은순') {
            // 후기 개수를 가져와서 내림차순 정렬
            // 모든 게시물에 대해 후기 수를 미리 계산하고 likesCount와 reviewsCount를 함께 전달
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
                      likes: post['likes'] ?? 0, // 좋아요 수 추가
                      postId: post['postDoc'].id,
                      status: post['status'] ?? '거래 가능',
                    );
                  },
                );
              },
            );
          } else {
            // 정렬된 게시글 목록 표시
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final postData = posts[index].data() as Map<String, dynamic>;
                print('Likes Count for Post: ${postData['likes']}');
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
                  likes: postData['likes'] ?? 0, // 좋아요 수 추가
                  postId: posts[index].id,
                  status: postData['status'] ?? '거래 가능',
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
        //'reviewsCount': postData[reviewsCount] ?? 0,
        'likes': postData['likes'] ?? 0,
        'createAt': postData['createAt'],
      });
    }

    // 인기순 정렬 부분 수정
    if (_selectedSort == '인기순') {
      postsWithCounts.sort((a, b) {
        print('Sorting: ${a['likes']} vs ${b['likes']}');
        return (b['likes'] as int)
            .compareTo(a['likes'] as int); // likes를 int로 캐스팅하여 비교
      });
    }

    // 후기 많은 순, 최신순 등 나머지 정렬
    if (_selectedSort == '최신순') {
      postsWithCounts.sort((a, b) {
        return b['createAt'].compareTo(a['createAt']); // 생성일자 기준 내림차순
      });
    } else if (_selectedSort == '후기많은순') {
      postsWithCounts.sort((a, b) {
        return b['review'].compareTo(a['review']); // 후기 수 기준 내림차순
      });
    }
    print('Sorted Posts: ${postsWithCounts.map((e) => e['likes']).toList()}');
    return postsWithCounts;
  }
}
