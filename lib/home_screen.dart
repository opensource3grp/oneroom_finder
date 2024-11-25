import 'package:flutter/material.dart';
import 'package:oneroom_finder/post_service.dart';
import 'room_details_screen.dart';
import 'post_create_screen.dart'; // 게시물 생성 화면을 위한 임포트
import 'dart:io';

class HomeScreen extends StatefulWidget {
  final List<Map<String, dynamic>> posts; // posts를 외부에서 전달받도록 정의

  const HomeScreen({super.key, required this.posts});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // posts를 직접 업데이트 할 수 있게 변경
  void _updatePost(int index, Map<String, dynamic> updatedPost) {
    setState(() {
      widget.posts[index] = updatedPost;
    });
  }

  @override
  Widget build(BuildContext context) {
    // PostService 인스턴스 생성
    PostService postService = PostService();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          '원룸알리미',
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
      body: HomeTab(
        posts: widget.posts,
        updatePost: _updatePost, // 게시물 업데이트 함수 전달
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 게시물 생성 화면으로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostCreateScreen(
                postService: postService, // PostService 전달
              ),
            ),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
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
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  final List<Map<String, dynamic>> posts;
  final Function(int, Map<String, dynamic>)
      updatePost; // Define the updatePost type

  const HomeTab({
    super.key,
    required this.posts,
    required this.updatePost, // Receive updatePost in the constructor
  });

  @override
  // ignore: library_private_types_in_public_api
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Map<String, dynamic>> posts = [
    {
      'title': '원룸 (월세)',
      'location': '학교앞',
      'price': '200/33',
      'author': '공인중개사',
      'detail': '관리비 5만원',
      'image': null,
      'isFavorite': false,
    },
    {
      'title': '투룸 (전세)',
      'location': '학교앞',
      'price': '200/45',
      'author': '학생',
      'detail': '관리비 5만원',
      'image': null,
      'isFavorite': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildListingCard(
          post['title'] ?? '',
          post['location'] ?? '',
          post['price'] ?? '',
          post['author'] ?? '',
          post['detail'] ?? '',
          post['image'],
          post['isFavorite'],
          () {
            setState(() {
              posts[index]['isFavorite'] = !post['isFavorite'];
            });
          },
          () {
            // 게시물을 클릭하면 상세 정보 화면으로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RoomDetailsScreen(
                  post: post,
                  postId: '',
                  updatePost: widget.updatePost,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildListingCard(
    String title,
    String location,
    String price,
    String author,
    String detail,
    File? image,
    bool isFavorite,
    VoidCallback onFavoritePressed,
    VoidCallback onCardPressed,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onCardPressed,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (price.isNotEmpty)
                Text(price,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '$title/$location/$detail',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text('작성자 : $author',
                  style: const TextStyle(color: Colors.redAccent)),
              if (image != null) ...[
                const SizedBox(height: 8),
                Image.file(image,
                    width: double.infinity, height: 150, fit: BoxFit.cover),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '후기 0개',
                    style: TextStyle(color: Colors.grey),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.redAccent,
                    ),
                    onPressed: onFavoritePressed,
                  ),
                ],
              ),
            ],
          ),
        ),
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
