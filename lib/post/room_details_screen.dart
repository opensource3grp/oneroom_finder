import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/chat_room/chatroom_screen.dart';
import 'package:oneroom_finder/post/editpost_dialog.dart';
import 'comment.dart';
import 'package:oneroom_finder/post/post_service.dart';

class RoomDetailsScreen extends StatelessWidget {
  final String postId;
  final List<String> selectedOptions;
  final bool parkingAvailable; // 주차 가능 여부
  final bool moveInDate; // 입주 가능 여부
  final PostService postService = PostService();

  RoomDetailsScreen({
    super.key,
    required this.postId,
    required this.selectedOptions,
    required this.parkingAvailable,
    required this.moveInDate,
  });

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

  Widget _iconWithText(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 30),
        const SizedBox(height: 5),
        Text(text),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid; // 사용자 uid 생성

    return StreamBuilder<DocumentSnapshot>(
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
        final String floor = post['floor'] ?? '층수 정보 없음';
        final String maintenanceFee = post['maintenanceFee'] ?? '관리비 정보 없음';
        final bool parkingAvailable = post['parkingAvailable'] ?? false;
        final bool moveInDate = post['moveInDate'] ?? false;

        // 선택된 옵션 리스트를 가져오기
        List<String> selectedOptions = [];
        if (post['options'] != null && post['options'] is List) {
          selectedOptions = (post['options'] as List)
              .map((option) {
                if (option is Map<String, dynamic> &&
                    option.containsKey('option')) {
                  return option['option'] as String; // Map에서 'option' 값을 가져옴
                }
                return ''; // 값이 없으면 빈 문자열 반환
              })
              .where((option) => option.isNotEmpty)
              .toList(); // 빈 문자열 제외
        } else {
          selectedOptions = []; // 데이터가 없으면 빈 리스트로 설정
        }

        final Map<String, IconData> optionIcons = {
          '냉장고': Icons.kitchen,
          '에어컨': Icons.ac_unit,
          '세탁기': Icons.local_laundry_service,
          'Wi-Fi': Icons.wifi,
          'TV': Icons.tv,
          '책상': Icons.desk,
          '가스레인지': Icons.fireplace,
          '침대': Icons.bed,
        };

        // 작성자 정보 가져오기
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
                          builder: (context) =>
                              EditPostDialog(postId: postId, post: post),
                        );
                      } else if (value == 'delete') {
                        postService.deletePost(context, postId).then((_) {
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
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await PostService.setStatus(
                                        postId, updateStatus);
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
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
                      // 상태 표시 추가
                      Text(
                        '상태: $status', // 상태를 표시
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: status == '거래 완료' ? Colors.red : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _iconWithText(Icons.local_parking,
                              "주차: ${parkingAvailable ? '주차 가능' : '주차 불가능'}"),
                          _iconWithText(Icons.apartment, "층수: $floor"),
                          _iconWithText(Icons.calendar_today,
                              "즉시 입주: ${moveInDate ? '즉시 입주 가능' : '즉시 입주 불가능'}"),
                        ],
                      ),
                      const SizedBox(height: 20),

                      //관리비정보
                      Text(
                        '관리비 : $maintenanceFee',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      //옵션정보
                      const Text(
                        '옵션 정보',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      // 선택된 옵션의 아이콘 표시
                      if (selectedOptions.isNotEmpty)
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: selectedOptions.map((option) {
                            final icon = optionIcons[option] ??
                                Icons.help; // 아이콘이 없으면 기본 아이콘 사용
                            return _iconWithText(icon, option); // 아이콘과 텍스트 표시
                          }).toList(),
                        )
                      else
                        const Text(
                          '선택된 옵션이 없습니다.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      const SizedBox(height: 20),
                      // 내용
                      Text(
                        '상세설명: $content',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      // 좋아요와 후기
                      Row(
                        children: [
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
                                  const SnackBar(content: Text('로그인이 필요합니다.')),
                                );
                                return;
                              }

                              try {
                                // 채팅방 생성/조회
                                final chatRoomId =
                                    await getOrCreateChatRoom(userId, authorId);

                                // 채팅 화면으로 이동
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
                        postId: postId,
                        isCommentAllowed: status == '거래 완료',
                      ),
                      // 찜하기 버튼
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {},
                        child: Text('이 집이 마음에 드시나요?'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
