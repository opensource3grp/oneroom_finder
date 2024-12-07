import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/chat_room/chatroom_screen.dart';
import 'package:oneroom_finder/post/editpost_dialog.dart';
import 'comment.dart';
import 'post_service.dart';
import 'package:provider/provider.dart';
import 'package:oneroom_finder/post/like_status.dart';

class RoomDetailsScreen extends StatefulWidget {
  final String postId;
  final int initialLikes; // 좋아요 초기 값
  final bool initialIsLiked; // 초기 좋아요 상태
  final PostService postService = PostService();

  RoomDetailsScreen({
    super.key,
    required this.postId,
    this.initialLikes = 0,
    this.initialIsLiked = false,
  });

  @override
  _RoomDetailsScreenState createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // 초기값을 Provider에 설정
    final likeStatus = Provider.of<LikeStatus>(context, listen: false);
    likeStatus.setLikeStatus(widget.initialLikes, widget.initialIsLiked);

    FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .get()
        .then((postSnapshot) {
      if (postSnapshot.exists) {
        final postData = postSnapshot.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(postData['likedBy'] ?? []);
        final likeStatus = Provider.of<LikeStatus>(context, listen: false);
        likeStatus.setLikeStatus(postData['likesCount'] ?? 0,
            likedBy.contains(FirebaseAuth.instance.currentUser?.uid));
        // 좋아요 상태 변경 후 UI에 반영하기
        setState(() {}); // UI 갱신
      }
    });
  }

  Stream<DocumentSnapshot> fetchPostDetails() {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId) // 특정 게시물 조회
        .snapshots();
  }

  Stream<QuerySnapshot> fetchAvailablePosts() {
    return FirebaseFirestore.instance
        .collection('posts')
        .where('status', isEqualTo: '거래 가능') // 거래 가능 상태인 게시물만 가져오기
        .snapshots();
  }

  // 사용자 정보를 Firestore에서 가져오는 메서드
  Future<Map<String, dynamic>?> fetchUserDetails(String userId) async {
    if (userId.isEmpty) {
      print('No author ID provided');
      return null; // 또는 적절한 기본값을 반환
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return userDoc.data();
      } else {
        print('User document does not exist for userId: $userId');
        return null;
      }
    } catch (e) {
      print("Error fetching user details: $e");
      return null;
    }
  }

  // Firestore에서 채팅방 생성/조회
  Future<String> getOrCreateChatRoom(String userId, String authorId) async {
    final chatRoomsCollection =
        FirebaseFirestore.instance.collection('chatRooms');

    // 기존 채팅방 확인
    final querySnapshot = await chatRoomsCollection
        .where('participants', arrayContains: userId)
        .get();

    for (var doc in querySnapshot.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(authorId)) {
        return doc.id; // 기존 채팅방 ID 반환
      }
    }

    // 채팅방 생성
    final newChatRoom = await chatRoomsCollection.add({
      'participants': [userId, authorId],
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    return newChatRoom.id; // 새로 생성된 채팅방 ID 반환
  }

  // 상대적 시간 포맷
  String formatRelativeTime(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays >= 1) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid; // 사용자 uid 생성
    final likeStatus = Provider.of<LikeStatus>(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context,
            {'likes': likeStatus.likes, 'isLiked': likeStatus.isLiked});
        return true; // 뒤로가기를 허용
      },
      child: StreamBuilder<DocumentSnapshot>(
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
          final String authorId = post['authorId'] ?? ''; // 작성자 ID
          final Timestamp? createdAtTimestamp = post['createdAt']; // null 가능성
          final DateTime createdAt = createdAtTimestamp?.toDate() ??
              DateTime.now(); // null일 경우 현재 시간으로 대체
          final String relativeTime = formatRelativeTime(createdAt);
          final String status = post['status'] ?? '거래 가능';
          final int comment = post['review'] ?? 0;
          final String? imageUrl = post['image'];
          final String location = post['location'] ?? '위치 정보 없음'; // 위치 정보 기본값

          return FutureBuilder<Map<String, dynamic>?>(
            future: fetchUserDetails(authorId),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (userSnapshot.hasError || !userSnapshot.hasData) {
                return const Center(child: Text('사용자 정보를 가져오는데 실패했습니다.'));
              }

              final userData = userSnapshot.data!;
              final String nickname = userData['nickname'] ?? '닉네임 없음';
              final String job = userData['job'] ?? '직업 없음';
              final String author = '$nickname($job)';

              return Scaffold(
                appBar: AppBar(
                  title: Text(post['title'] ?? '제목 없음'),
                  actions: [
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          showDialog(
                            context: context,
                            builder: (context) => EditPostDialog(
                                postId: widget.postId, post: post),
                          );
                        } else if (value == 'delete') {
                          widget.postService
                              .deletePost(context, widget.postId)
                              .then((_) {
                            Navigator.of(context).pop();
                          }).catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('게시글 삭제 중 오류 발생: $e')),
                            );
                          });
                        } else if (value == 'change_status') {
                          showDialog(
                            context: context,
                            builder: (context) {
                              String updateStatus = status;
                              return AlertDialog(
                                title: const Text('게시글 상태 변경'),
                                content: StatefulBuilder(
                                  builder: (context, setState) {
                                    return DropdownButton<String>(
                                      value: updateStatus.isEmpty
                                          ? post['status'] ?? '거래 가능'
                                          : updateStatus,
                                      items: ['거래 가능', '거래 중', '거래 완료']
                                          .map((status) => DropdownMenuItem(
                                                value: status,
                                                child: Text(status),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          updateStatus = value!;
                                        });
                                      },
                                    );
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await PostService.setStatus(
                                          widget.postId, updateStatus);
                                      Navigator.of(context).pop();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                '게시글 상태가 "$updateStatus"로 변경되었습니다.')),
                                      );
                                    },
                                    child: const Text('저장'),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('게시글 상태를 변경할 권한이 없습니다.'),
                            ),
                          );
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
                          const PopupMenuItem<String>(
                            value: 'change_status',
                            child: Text('게시글 상태 변경'),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '상태: $status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                status == '거래 완료' ? Colors.red : Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tag,
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.blue),
                            ),
                            Row(
                              children: [
                                Text(
                                  '작성자: $author',
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  relativeTime,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          location,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (imageUrl != null)
                          Image.network(imageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover)
                        else
                          const Placeholder(
                              fallbackHeight: 200,
                              fallbackWidth: double.infinity),
                        const SizedBox(height: 16),
                        Text(
                          content,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                if (userId != null) {
                                  try {
                                    final newLikes = await widget.postService
                                        .toggleLike(
                                            widget.postId, userId, context);

                                    setState(() {
                                      likeStatus.toggleLike(
                                          widget.postId, userId, context);
                                      likeStatus.updateLikes(newLikes);
                                    });

                                    ScaffoldMessenger.of(context)
                                        .clearSnackBars();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          likeStatus.isLiked
                                              ? '좋아요를 눌렀습니다.'
                                              : '좋아요를 취소했습니다.',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  } catch (e) {
                                    widget.postService
                                        .showErrorDialog(context, e.toString());
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('좋아요는 로그인 후 이용 가능합니다.')),
                                  );
                                }
                              },
                              child: Icon(
                                Icons.thumb_up,
                                color: likeStatus.isLiked
                                    ? Colors.orange
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${likeStatus.likes}명이 좋아합니다.'),
                            const Spacer(),
                            const Icon(Icons.comment, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text('$comment개의 후기'),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                if (userId == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('로그인이 필요합니다.')),
                                  );
                                  return;
                                }

                                try {
                                  final chatRoomId = await getOrCreateChatRoom(
                                      userId, authorId);

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatRoomScreen(
                                        chatRoomId: chatRoomId,
                                        userJob: job,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('채팅방 생성 오류: $e')),
                                  );
                                }
                              },
                              child: const Text("1:1 채팅"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const Text(
                          '후기 입력',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        CommentInputField(
                          postId: widget.postId,
                          isCommentAllowed: status == '거래 완료',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
