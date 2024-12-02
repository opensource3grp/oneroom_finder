import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'comment.dart';
import 'post_service.dart';
//import 'package:intl/intl.dart';

class RoomDetailsScreen extends StatelessWidget {
  final String postId;
  final PostService postService = PostService();

  RoomDetailsScreen({super.key, required this.postId});

  Stream<DocumentSnapshot> fetchPostDetails() {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
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
    final userId = FirebaseAuth.instance.currentUser?.uid; //사용자 uid 생성
    return Scaffold(
      appBar: AppBar(
        title: const Text('원룸 상세 정보'),
        backgroundColor: Colors.orange,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                // 수정 버튼 클릭 시 다이얼로그 열기
                showDialog(
                  context: context,
                  builder: (context) {
                    return StreamBuilder<DocumentSnapshot>(
                      stream: fetchPostDetails(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Center(child: Text('오류가 발생했습니다.'));
                        }

                        final post =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final TextEditingController titleController =
                            TextEditingController(text: post['title'] ?? '');
                        final TextEditingController contentController =
                            TextEditingController(text: post['content'] ?? '');

                        String? type = post['type'] ?? '월세';
                        String? roomType = post['roomType'] ?? '원룸';
                        String? location = post['location'] ?? '위치 정보 없음';
                        String? currentImageUrl = post['imageUrl'];
                        File? newImage;

                        return StatefulBuilder(
                          builder: (context, setState) {
                            return AlertDialog(
                              title: const Text('게시글 수정'),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextField(
                                      controller: titleController,
                                      decoration: const InputDecoration(
                                          labelText: '제목'),
                                    ),
                                    const SizedBox(height: 8.0),
                                    TextField(
                                      controller: contentController,
                                      decoration: const InputDecoration(
                                          labelText: '내용'),
                                      maxLines: 4,
                                    ),
                                    const SizedBox(height: 8.0),
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: '거래 유형',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: type,
                                      items: ['월세', '전세']
                                          .map((item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          type = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8.0),
                                    DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: '타입 선택',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: roomType,
                                      items: ['원룸', '투룸', '쓰리룸']
                                          .map((item) => DropdownMenuItem(
                                                value: item,
                                                child: Text(item),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          roomType = value;
                                        });
                                      },
                                    ),
                                    const SizedBox(height: 8.0),
                                    TextButton(
                                      onPressed: () async {
                                        final pickedFile = await ImagePicker()
                                            .pickImage(
                                                source: ImageSource.gallery);
                                        if (pickedFile != null) {
                                          setState(() {
                                            newImage = File(pickedFile.path);
                                          });
                                        }
                                      },
                                      child: const Text('사진 변경'),
                                    ),
                                    if (newImage != null)
                                      Image.file(newImage!, height: 100)
                                    else if (currentImageUrl != null)
                                      Image.network(currentImageUrl,
                                          height: 100),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final newTitle = titleController.text;
                                    final newContent = contentController.text;

                                    if (newTitle.isNotEmpty &&
                                        newContent.isNotEmpty) {
                                      await PostService().updatePost(
                                        postId,
                                        newTitle,
                                        newContent,
                                        type,
                                        roomType,
                                        newImage,
                                        location,
                                      );
                                      // ignore: use_build_context_synchronously
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('게시글이 수정되었습니다.')),
                                      );
                                      // ignore: use_build_context_synchronously
                                      Navigator.of(context).pop(); // 다이얼로그 닫기
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text('제목과 내용을 입력해주세요.')),
                                      );
                                    }
                                  },
                                  child: const Text('수정'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                );
              } else if (value == 'delete') {
                // 삭제 버튼 클릭 시 처리
                postService.deletePost(context, postId).then((_) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop();
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('게시글이 삭제되었습니다.')),
                  );
                }).catchError((e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('게시글 삭제 중 오류 발생: $e')),
                  );
                });
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
              ];
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
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
          final Timestamp? createdAtTimestamp = post['createdAt']; //null 가능성
          final DateTime createdAt = createdAtTimestamp?.toDate() ??
              DateTime.now(); // null일 경우 현재 시간으로 대체
          final String relativeTime = formatRelativeTime(createdAt);
          final int likes = post['likes'] ?? 0;
          final int comment = post['review'] ?? 0;
          //final int reviewsCount = post['reviewsCount'] ?? 0; // 후기 개수
          final String? imageUrl = post['image'];
          final String location = post['location'] ?? '위치 정보 없음'; // 위치 정보 기본값

          // 여기서 authorId 값을 출력
          print('Author ID: $authorId'); // 추가한 부분

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

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 태그와 작성자
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
                      // 위치 정보
                      Text(
                        location,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      // 제목
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 게시물 이미지
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
                      // 내용
                      Text(
                        content,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      // 좋아요와 후기
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (userId != null) {
                                try {
                                  await postService.toggleLike(
                                      postId, userId, context);
                                } catch (e) {
                                  postService.showErrorDialog(
                                      context, e.toString());
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('좋아요는 로그인 후 이용 가능합니다.')),
                                );
                              }
                            },
                            child: const Icon(Icons.thumb_up,
                                color: Colors.orange),
                          ),
                          const SizedBox(width: 8),
                          Text('$likes명이 좋아합니다.'),
                          const Spacer(),
                          const Icon(Icons.comment, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text('$comment개의 후기'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      // 후기 입력란
                      const Text(
                        '후기 입력',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CommentInputField(postId: postId),
                    ],
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
