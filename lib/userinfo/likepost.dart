import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oneroom_finder/home_tab.dart';
import 'package:oneroom_finder/post/post_service.dart';
import 'package:oneroom_finder/post/room_details_screen.dart';

class LikePostDialog extends StatelessWidget {
  final String userId;
  final PostService postService = PostService();

  LikePostDialog({Key? key, required this.userId}) : super(key: key);

  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('관심있는 방'),
      content: SizedBox(
        width: double.maxFinite,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('likes')
              .where('userId', isEqualTo: userId)
              .snapshots(),
          builder: (context, likeSnapshot) {
            if (likeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!likeSnapshot.hasData || likeSnapshot.data!.docs.isEmpty) {
              return const Center(child: Text('좋아요한 매물이 없습니다.'));
            }

            final likedPostIds = likeSnapshot.data!.docs
                .map((doc) => (doc.data() as Map<String, dynamic>)['postId'])
                .toList();

            return StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .where(FieldPath.documentId, whereIn: likedPostIds)
                  .snapshots(),
              builder: (context, postSnapshot) {
                if (postSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!postSnapshot.hasData || postSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('게시글이 없습니다.'));
                }

                final posts = postSnapshot.data!.docs;

                return ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final postData =
                        posts[index].data() as Map<String, dynamic>;
                    final postId = posts[index].id;

                    final List<String> selectedOptions =
                        (postData['options'] as List<dynamic>? ?? [])
                            .map((option) => option['option'] as String)
                            .toList();

                    final parkingAvailable =
                        postData['parkingAvailable'] ?? 'No';
                    final moveInDate = postData['moveInDate'] ?? 'No';

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
                              builder: (context) => RoomDetailsScreen(
                                postId: postId,
                                selectedOptions: selectedOptions,
                                parkingAvailable: parkingAvailable,
                                moveInDate: moveInDate,
                              ),
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
                              '${postData['location'] ?? '위치 없음'}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
  }
}
