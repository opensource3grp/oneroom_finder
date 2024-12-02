import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oneroom_finder/post/post_create_screen.dart';
import 'post/post_service.dart';
import 'post/post_list_screen.dart';
import 'post/post_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_room/chat_create.dart';
import 'post/post_search.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import 'post/room_details_screen.dart';

class HomeScreen extends StatefulWidget {
  //final List<Map<String, String>> posts; // posts 추가
  final String nickname; // 닉네임
  final String job; // 직업
  final String uid;

  const HomeScreen({
    super.key,
    //required this.posts,
    required this.nickname, // nickname 추가
    required this.job,
    required this.uid, // job 추가
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PostService postService = PostService();
  int _selectedIndex = 0;
  //String searchQuery = '';
  late String uid;

  @override
  void initState() {
    super.initState();
    // // posts 전달 대신 Firestore와 연동되도록 수정
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   // 위젯이 완전히 렌더링된 후에 실행할 코드
    //   developer.log(
    //       'HomeScreen loaded with nickname: ${widget.nickname}, job: ${widget.job}');
    // });
    // FirebaseAuth를 사용해 uid 가져오기
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      uid = currentUser.uid;
      developer.log('Current User UID: $uid');
    } else {
      developer.log('No user is logged in.');
      // 로그인이 안된 경우 처리
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // uid를 로그에 출력하거나 다른 곳에서 사용 가능
    developer.log('UID is being used in HomeScreen: $uid');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '원룸 알리미',
          style: TextStyle(color: Colors.orange),
        ),
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // Open the search bar
              showSearch(
                context: context,
                delegate: PostSearchDelegate(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.message), label: '메시지'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: '지도'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      // 각 탭에 해당하는 화면을 표시하는 부분 추가
      body: _selectedIndex == 0
          ? HomeTab() // 홈 화면
          : _selectedIndex == 1
              ? MessageTab() // 메시지 탭
              : _selectedIndex == 2
                  ? MapTab() // 지도 탭
                  : MyPageTab(), // 마이페이지 탭
      // 홈탭에만 플로팅 버튼을 추가
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PostCreateScreen(postService: postService),
                  ),
                );
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add),
            )
          : null, // 다른 탭에서는 플로팅 버튼 숨김
    );
  }
}

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

class MessageTab extends StatefulWidget {
  const MessageTab({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MessageTabState createState() => _MessageTabState();
}

class _MessageTabState extends State<MessageTab> {
  bool isEditing = false;
  Set<String> selectedChatRooms = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('메시지'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                if (selectedChatRooms.isNotEmpty) {
                  for (String chatRoomId in selectedChatRooms) {
                    await FirebaseFirestore.instance
                        .collection('chatRooms')
                        .doc(chatRoomId)
                        .delete();
                  }
                  setState(() {
                    isEditing = false;
                    selectedChatRooms.clear();
                  });
                }
              },
            ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.done),
              onPressed: () {
                setState(() {
                  isEditing = false;
                  selectedChatRooms.clear();
                });
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chatRooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                '대화방이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          final chatRooms = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final chatRoomData = chatRoom.data() as Map<String, dynamic>;
              final chatRoomName = chatRoomData['name'] ?? '대화방';
              final lastMessage = chatRoomData['lastMessage'] ?? '';
              final lastMessageTime =
                  (chatRoomData['lastMessageTime'] as Timestamp?)?.toDate();
              final unreadCount = chatRoomData['unreadCount'] ?? 0;
              final createdTime =
                  (chatRoomData['createdAt'] as Timestamp?)?.toDate();

              return ListTile(
                title: Text(
                  chatRoomName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastMessage,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    if (createdTime != null)
                      Text(
                        '생성일: ${DateFormat('yyyy/MM/dd HH:mm').format(createdTime)}',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                      ),
                  ],
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text(
                    chatRoomName.isNotEmpty ? chatRoomName[0] : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                trailing: isEditing
                    ? Icon(
                        selectedChatRooms.contains(chatRoom.id)
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: selectedChatRooms.contains(chatRoom.id)
                            ? Colors.orange
                            : Colors.grey,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (lastMessageTime != null)
                            Text(
                              DateFormat('yyyy.MM.dd HH:mm')
                                  .format(lastMessageTime), // 포맷을 변경
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$unreadCount',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                onTap: () {
                  if (isEditing) {
                    setState(() {
                      if (selectedChatRooms.contains(chatRoom.id)) {
                        selectedChatRooms.remove(chatRoom.id);
                      } else {
                        selectedChatRooms.add(chatRoom.id);
                      }
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ChatRoomScreen(chatRoomId: chatRoom.id),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateChatRoomDialog(),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ChatRoomScreen extends StatelessWidget {
  final String chatRoomId;

  const ChatRoomScreen({super.key, required this.chatRoomId});

  @override
  Widget build(BuildContext context) {
    final TextEditingController messageController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅방'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      '메시지가 없습니다.',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final messageData = message.data() as Map<String, dynamic>;
                    final sender = messageData['sender'] ?? '알 수 없음';
                    final text = messageData['text'] ?? '';
                    final isMe = sender ==
                        FirebaseAuth.instance.currentUser?.displayName;
                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 15),
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.orange : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          text,
                          style: TextStyle(
                              color: isMe ? Colors.white : Colors.black),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: '메시지 입력...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.orange),
                  onPressed: () async {
                    final text = messageController.text.trim();
                    if (text.isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('chatRooms')
                          .doc(chatRoomId)
                          .collection('messages')
                          .add({
                        'text': text,
                        'sender':
                            FirebaseAuth.instance.currentUser?.displayName ??
                                '알 수 없음',
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('지도 탭'));
  }
}

class MyPageTab extends StatelessWidget {
  const MyPageTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 20),
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.orange,
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 20),
        const Text(
          '사용자 이름',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 30),
        _buildMenuItem(context, '최근 본 방', Icons.history, () {
          // 최근 본 방 화면으로 이동
        }),
        _buildMenuItem(context, '관심있는 방', Icons.favorite, () {
          // 관심있는 방 화면으로 이동
        }),
        _buildMenuItem(context, '내 정보', Icons.person, () {
          // 내 정보 화면으로 이동
        }),
        _buildMenuItem(context, '구매 내역', Icons.shopping_cart, () {
          // 구매 내역 화면으로 이동
        }),
      ],
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
}
