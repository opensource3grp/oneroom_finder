import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:oneroom_finder/userinfo/recentlyviewed.dart';
import 'room_details_screen.dart';

class PostSearchDelegate extends SearchDelegate<String> {
  PostSearchDelegate();

  @override
  String get searchFieldLabel => '검색어를 입력하세요...';

  @override
  TextStyle get searchFieldStyle =>
      const TextStyle(color: Colors.black, fontSize: 18);

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: Colors.black),
        onPressed: () {
          query = ''; // 검색어 지우기
          showSuggestions(context); // 제안 다시 보이기
        },
      ),
      IconButton(
        icon: const Icon(Icons.search, color: Colors.black),
        onPressed: () {
          // 검색 버튼 클릭 시
          showResults(context); // 검색 결과 보여주기
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: () {
        close(context, ''); // 검색 종료
      },
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              '검색 결과가 없습니다.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }

        final results = snapshot.data!.docs.where((post) {
          final postData = post.data() as Map<String, dynamic>;
          final title = postData['title'] ?? '';
          final content = postData['content'] ?? '';

          // 검색어가 제목이나 내용에 포함되었는지 확인
          return title.contains(query) || content.contains(query);
        }).toList();

        if (results.isEmpty) {
          return const Center(
            child: Text(
              '검색 결과가 없습니다.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final post = results[index];
            final postData = post.data() as Map<String, dynamic>;
            final title = postData['title'] ?? '제목 없음';
            final postId = post.id; // 게시물 ID 가져오기

            return ListTile(
              title: Text(title),
              onTap: () {
                // 클릭 시 상세 페이지로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RoomDetailsScreen(postId: postId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
