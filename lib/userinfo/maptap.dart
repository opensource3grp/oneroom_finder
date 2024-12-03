import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/post/room_details_screen.dart';

// MapTab 클래스
class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '지도 탭',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}

class MyPageTab extends StatelessWidget {
  const MyPageTab({super.key});

  @override
  Widget build(BuildContext context) {
    //final post = snapshot.data!.data() as Map<String, dynamic>;
    final userId = FirebaseAuth
        .instance.currentUser?.uid; // 유저 ID를 지정 (로그인 상태에서 가져오도록 구현 필요)
    //final String? nickname = post['nickname'];
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('사용자 정보를 불러올 수 없습니다.'));
        }
        final user = snapshot.data!.data() as Map<String, dynamic>;
        final nickname = user['nickname'];
        //final joinDate
        return ListView(
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              nickname,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildMenuItem(context, '내 게시글', Icons.article, () {
              _showUserPosts(context, userId!);
            }),
            _buildMenuItem(context, '최근 본 방', Icons.history, () {
              _showListDialog(context, '최근 본 방', user['recentRooms'] ?? []);
            }),
            _buildMenuItem(context, '관심있는 방', Icons.favorite, () {
              _showListDialog(context, '관심있는 방', user['favoriteRooms'] ?? []);
            }),
            _buildMenuItem(context, '구매 내역', Icons.shopping_cart, () {
              _showListDialog(context, '구매 내역', user['purchaseHistory'] ?? []);
            }),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.orange),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  void _showListDialog(BuildContext context, String title, List<String> items) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(items[index]));
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  // 사용자 게시글을 표시하는 다이얼로그
  void _showUserPosts(BuildContext context, String userId) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('내 게시글'),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .where('authorId', isEqualTo: userId) // authorId로 필터링
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('게시글이 없습니다.'),
                  );
                }

                final posts = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final postData =
                        posts[index].data() as Map<String, dynamic>;
                    final postId = posts[index].id;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12.0),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RoomDetailsScreen(postId: postId),
                            ),
                          );
                        },
                        leading: postData['imageUrl'] != null &&
                                postData['imageUrl'].isNotEmpty
                            ? Image.network(
                                postData['imageUrl'],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox(
                                width: 100,
                                height: 100,
                                child: Icon(Icons.image, color: Colors.grey),
                              ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (postData['tag'] != null &&
                                postData['tag'].isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  postData['tag'],
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              postData['title'] ?? '제목 없음',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${postData['location'] ?? '위치 없음'} | ${postData['price'] ?? '가격 없음'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '작성자: ${postData['author'] ?? '작성자 없음'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                            Text(
                              postData['content'] ?? '내용 없음',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '후기 ${postData['review'] ?? 0}개',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  '좋아요 ${postData['likes'] ?? 0}개',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.favorite_border,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    // 좋아요 버튼 클릭 동작 구현
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
}
