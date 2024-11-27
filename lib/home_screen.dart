import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oneroom_finder/post_create_screen.dart';
import 'post_service.dart';
import 'post_list_screen.dart';
import 'post_card.dart';

class HomeScreen extends StatefulWidget {
  final List<Map<String, String>> posts; // posts 추가

  const HomeScreen({super.key, required this.posts});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PostService postService = PostService();
  int _selectedIndex = 0;

  late List<Widget> _widgetOptions; // posts 전달을 위해 late로 초기화

  @override
  void initState() {
    super.initState();
    // posts 전달 대신 Firestore와 연동되도록 수정
    _widgetOptions = <Widget>[
      const HomeTab(), // Firestore에서 데이터를 가져오므로 posts 필요 없음
      const MessageTab(),
      const MapTab(),
      const MyPageTab(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {},
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
      body: _widgetOptions.elementAt(_selectedIndex),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostCreateScreen(postService: postService),
            ),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
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

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
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
                    tag: tag, // 추가: tag 전달
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

class MessageTab extends StatelessWidget {
  const MessageTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('메시지 탭'));
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
