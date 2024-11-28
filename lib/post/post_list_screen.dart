import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_card.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
      case '후기많은순':
        _postStream = _firestore
            .collection('posts')
            .orderBy('reviewsCount', descending: true) // Sort by reviews count
            .snapshots();
        break;
      case '최신순':
        _postStream = _firestore
            .collection('posts')
            .orderBy('createdAt', descending: true) // Sort by creation date
            .snapshots();
        break;
      case '인기순':
        _postStream = _firestore
            .collection('posts')
            .orderBy('popularity',
                descending:
                    true) // Sort by popularity (assuming 'popularity' field exists)
            .snapshots();
        break;
      case '팝니다순':
        _postStream = _firestore
            .collection('posts')
            .where('forSale', isEqualTo: true) // Filter posts marked for sale
            .snapshots();
        break;
      case '삽니다순':
        _postStream = _firestore
            .collection('posts')
            .where('forSale', isEqualTo: false) // Filter posts marked as buying
            .snapshots();
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
          // Sorting Dropdown Button in the AppBar
          DropdownButton<String>(
            value: _selectedSort,
            icon: const Icon(Icons.sort),
            onChanged: (String? newValue) {
              setState(() {
                _selectedSort = newValue!;
                _updatePostStream(); // Update the stream when sorting method changes
              });
            },
            items: ['최신순', '후기많은순', '인기순', '팝니다순', '삽니다순']
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

          final posts = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postData = post.data() as Map<String, dynamic>;

              final title = postData['title'] ?? '제목 없음';
              final content = postData['content'] ?? '내용 없음';
              final location = postData['location'] ?? '위치 없음';
              final price = postData['price'] ?? '가격 정보 없음';
              final author = postData['author'] ?? '작성자 없음';
              final image = postData['image'] ?? '';
              final tag = postData['tag'] ?? '';

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('posts')
                    .doc(post.id)
                    .collection('comments')
                    .snapshots(), // comments 하위 컬렉션 스트림
                builder: (context, commentSnapshot) {
                  int reviewsCount = 0;
                  if (commentSnapshot.hasData) {
                    reviewsCount = commentSnapshot.data!.docs.length; // 후기 개수
                  }

                  return PostCard(
                    tag: tag,
                    post: post,
                    title: title,
                    content: content,
                    location: location,
                    price: price,
                    author: author,
                    image: image,
                    reviewsCount: reviewsCount,
                    postId: post.id,
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
