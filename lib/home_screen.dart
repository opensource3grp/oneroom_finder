import 'package:flutter/material.dart';
import 'package:oneroom_finder/chat_room/message_tab.dart';
import 'package:oneroom_finder/home_tab.dart';
import 'package:oneroom_finder/post/post_create_screen.dart';
import 'package:oneroom_finder/user_service/auth_service.dart';
import 'post/post_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post/post_search.dart';
import 'package:oneroom_finder/userinfo/maptap.dart';
import 'dart:developer' as developer;

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
  final MapTab maptap = MapTab();
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
    // 직업에 따라 색상 지정
    Color appBarTextColor =
        widget.job == '학생' ? Colors.orange : Colors.blue; // 글자 색상
    Color selectedItemColor = widget.job == '학생' ? Colors.orange : Colors.blue;
    Color floatingActionButtonColor =
        widget.job == '학생' ? Colors.orange : Colors.blue;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // 직업에 따른 색상 변경
        title: Text(
          '원룸 알리미',
          style: TextStyle(color: appBarTextColor),
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                AuthService.logout(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.black),
                    SizedBox(width: 8),
                    Text("로그아웃"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: selectedItemColor, // 직업에 따른 색상 변경
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
              ? MessageTab(userJob: widget.job) // 메시지 탭
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
              backgroundColor: floatingActionButtonColor,
              child: const Icon(Icons.add),
            )
          : null, // 다른 탭에서는 플로팅 버튼 숨김
    );
  }
}
