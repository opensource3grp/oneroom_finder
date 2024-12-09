import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/post/post_card.dart';
import 'package:oneroom_finder/post/post_list_screen.dart';
import 'package:oneroom_finder/post/room_details_screen.dart';
import 'package:oneroom_finder/userinfo/userpost.dart';

class MapService extends StatefulWidget {
  @override
  _MapService createState() => _MapService();
}

class _MapService extends State<MapService> {
  String? selectedLocation; // 선택된 위치 저장
  List<Map<String, dynamic>> filteredPosts = []; // 필터링된 게시글 저장
  Map<String, int> locationCounts = {'신평': 0, '학교 앞': 0, '옥계': 0}; // 위치별 게시글 수

  @override
  void initState() {
    super.initState();
    fetchPostCounts(); // 초기 위치별 게시글 개수
    fetchFilteredPosts(); // 초기 데이터 로드
  }

  // Firestore에서 위치별 게시글 수 가져오기
  Future<void> fetchPostCounts() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('posts').get();

      final counts = {'신평': 0, '학교 앞': 0, '옥계': 0};
      for (var doc in querySnapshot.docs) {
        final location = doc['location'] ?? '';
        if (counts.containsKey(location)) {
          counts[location] = counts[location]! + 1;
        }
      }

      setState(() {
        locationCounts = counts;
      });
    } catch (e) {
      print('게시글 데이터를 가져오는 중 오류 발생: $e');
    }
  }

  // Firestore에서 게시글 데이터 가져오기
  Future<void> fetchFilteredPosts() async {
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('posts').get();

      List<Map<String, dynamic>> posts = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id, // 문서 ID (상세 페이지에서 사용)
          'title': doc['title'] ?? '',
          'content': doc['content'] ?? '',
          'location': doc['location'] ?? '',
          'options': doc['options'] ?? [], // 게시글 옵션
          'parkingAvailable': doc['parkingAvailable'] ?? false,
          'moveInDate': doc['moveInDate'] ?? '', // 입주 가능 날짜
        };
      }).toList();

      setState(() {
        if (selectedLocation == null) {
          // 위치 선택 안 했을 경우 모든 데이터 표시
          filteredPosts = posts;
        } else {
          // 선택된 위치에 맞는 데이터만 필터링
          filteredPosts = posts
              .where((post) => post['location'] == selectedLocation)
              .toList();
        }
      });

      print('필터링된 게시글: $filteredPosts'); // 필터링된 데이터 출력
    } catch (e) {
      print('데이터를 가져오는 중 오류 발생: $e');
    }
  }

  // 위치 클릭 시 해당 위치의 게시글 목록을 보여주는 Dialog 열기
  void _onLocationSelected(String location) {
    setState(() {
      selectedLocation = location;
    });
    print('선택된 위치: $selectedLocation'); // 디버깅 로그
    fetchFilteredPosts(); // 선택된 위치에 따라 데이터 필터링

    // 위치에 해당하는 게시글을 다이얼로그로 띄우기
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$selectedLocation 게시글'), // 선택된 위치 제목 표시
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('posts').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('게시글이 없습니다.'));
                }

                final posts = snapshot.data!.docs.map((doc) {
                  return {
                    'id': doc.id, // 문서 ID
                    'title': doc['title'] ?? '',
                    'content': doc['content'] ?? '',
                    'location': doc['location'] ?? '',
                    'options': doc['options'] ?? [],
                    'parkingAvailable': doc['parkingAvailable'] ?? false,
                    'moveInDate': doc['moveInDate'] ?? '',
                  };
                }).toList();

                // selectedLocation이 null이 아니면 필터링
                final filteredPosts = selectedLocation == null
                    ? posts
                    : posts
                        .where((post) => post['location'] == selectedLocation)
                        .toList();

                return ListView.builder(
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    final postData = filteredPosts[index];
                    final postId = postData['id'];

                    // selectedOptions를 postData에서 가져오는 로직
                    List<String> selectedOptions = [];
                    if (postData['options'] != null &&
                        postData['options'] is List) {
                      selectedOptions = (postData['options'] as List)
                          .map((option) {
                            if (option is Map<String, dynamic> &&
                                option.containsKey('option')) {
                              return option['option']
                                  as String; // Map에서 'option' 값을 가져옴
                            }
                            return ''; // 값이 없으면 빈 문자열 반환
                          })
                          .where((option) => option.isNotEmpty)
                          .toList(); // 빈 문자열 제외
                    }

                    final parkingAvailable =
                        postData['parkingAvailable'] == false;
                    final moveInDate = postData['moveInDate'] == false;

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width; // 화면 가로 길이
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('위치별 게시글 보기'),
      ),
      body: Stack(
        children: [
          // 지도 배경
          Positioned.fill(
            child: Image.asset(
              'assets/map.png',
              fit: BoxFit.cover,
            ),
          ),
          // 신평 오버레이
          Positioned(
            left: screenWidth * 0.1, // 화면 너비의 10%
            top: screenHeight * 0.55, // 화면 높이의 20%
            child: GestureDetector(
              onTap: () => _onLocationSelected('신평'), // 위치 클릭 시 해당 위치의 게시글 표시
              child: _buildLocationOverlay('신평', locationCounts['신평']),
            ),
          ),
          // 학교 앞 오버레이
          Positioned(
            left: screenWidth * 0.65, // 화면 너비의 65%
            top: screenHeight * 0.28, // 화면 높이의 28%
            child: GestureDetector(
              onTap: () => _onLocationSelected('학교 앞'), // 위치 클릭 시 해당 위치의 게시글 표시
              child: _buildLocationOverlay('학교 앞', locationCounts['학교 앞']),
            ),
          ),
          // 옥계 오버레이
          Positioned(
            left: screenWidth * 0.9, // 화면 너비의 40%
            top: screenHeight * 0.25, // 화면 높이의 40%
            child: GestureDetector(
              onTap: () => _onLocationSelected('옥계'), // 위치 클릭 시 해당 위치의 게시글 표시
              child: _buildLocationOverlay('옥계', locationCounts['옥계']),
            ),
          ),
        ],
      ),
    );
  }

  // 위치 오버레이 위젯
  Widget _buildLocationOverlay(String location, int? count) {
    return Column(
      children: [
        Icon(
          Icons.location_on,
          color: Colors.red,
          size: 40,
        ),
        Text(
          '$location: ${count ?? 0}개',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
