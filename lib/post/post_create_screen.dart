import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 이미지 선택
//import 'dart:io'; // 이미지 파일 관련
import 'post_service.dart'; // PostService import
import 'package:firebase_auth/firebase_auth.dart'; // FirebaseAuth import
import 'package:cloud_firestore/cloud_firestore.dart'; // FirebaseFirestore import

class PostCreateScreen extends StatefulWidget {
  final PostService postService;

  const PostCreateScreen({super.key, required this.postService});

  @override
  _PostCreateScreenState createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String selectedTag = '삽니다';
  String? title; // 타입 선택을 위한 변수
  String? type; // 거래 유형 선택을 위한 변수
  String? roomLocation;
  final List<String> tags = ['삽니다', '팝니다'];
  File? selectedImage; // 선택된 이미지 파일

  final ImagePicker _picker = ImagePicker();
  String? nickname; // 로그인한 사용자의 닉네임
  String? job; // 로그인한 사용자의 직업

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // 로그인한 사용자의 정보를 Firestore에서 가져오는 함수
  Future<void> _loadUserInfo() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        if (userDoc.exists) {
          setState(() {
            nickname = userDoc['nickname'] ?? '알 수 없음';
            job = userDoc['job'] ?? '직업 없음';
          });
        } else {
          // 문서가 존재하지 않을 경우
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('사용자 정보를 찾을 수 없습니다.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사용자가 로그인하지 않았습니다.')),
        );
      }
    } catch (e) {
      // 예외 발생 시 오류 메시지 출력
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('회원 정보를 불러오는 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 작성'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        // Wrap the Column with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '태그 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              DropdownButton<String>(
                value: selectedTag,
                items: tags.map((tag) {
                  return DropdownMenuItem(
                    value: tag,
                    child: Text(tag),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedTag = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 타입 선택 (원룸, 투룸, 쓰리룸)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '타입 선택',
                  border: OutlineInputBorder(),
                ),
                value: title,
                items: ['원룸', '투룸', '쓰리룸']
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    title = value;
                  });
                },
              ),
              const SizedBox(height: 10),

              // 거래 유형 (월세, 전세)
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
              const SizedBox(height: 16),
              // 위치 선택
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: '타입 선택',
                  border: OutlineInputBorder(),
                ),
                value: roomLocation,
                items: ['옥계', '신평', '학교 앞']
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    roomLocation = value;
                  });
                },
              ),
              const SizedBox(height: 10),

              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '내용',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              /*
              // 닉네임과 직업 자동 표시
              if (nickname != null && job != null) ...[
                Text(
                  '작성자: $nickname',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '직업: $job',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
              const SizedBox(height: 16),
              */
              // 이미지 선택 버튼
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _selectImage,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: const Text('이미지 선택'),
                  ),
                  if (selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: GestureDetector(
                        onDoubleTap: () {
                          setState(() {
                            selectedImage = null; // 더블클릭 시 이미지 삭제
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('이미지가 삭제되었습니다.')),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: SizedBox(
                              width: 150, // 이미지의 너비
                              height: 150, // 이미지의 높이
                              child: selectedImage != null
                                  ? FittedBox(
                                      fit: BoxFit.cover,
                                      child: Image.file(
                                        selectedImage!, // File 타입 이미지를 Image 위젯으로 변환
                                        fit: BoxFit.cover, // 이미지가 공간을 꽉 채우도록 설정
                                      ),
                                    )
                                  : const Placeholder(),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await widget.postService.createPost(
                      context,
                      _titleController.text.trim(),
                      _contentController.text.trim(),
                      tag: selectedTag,
                      image: selectedImage, // 이미지 전달
                      type: type, // 거래 유형 전달
                      roomType: title, // 타입 선택 전달
                      location: roomLocation, //위치 전달
                    );
                    /*
                    // 게시글 작성 시 자동으로 작성자 정보와 게시물 정보 저장
                    final userId = FirebaseAuth.instance.currentUser?.uid;
                    if (userId != null) {
                      final userData = {
                        'nickname': nickname ?? '알 수 없음',
                        'job': job ?? '직업 없음',
                      };
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .set(userData, SetOptions(merge: true)); // 기존 데이터와 병합
                    }
                    */
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('작성하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 이미지 선택 메서드
  Future<void> _selectImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      // 이미지가 선택되지 않은 경우
      if (pickedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 선택하지 않았습니다.')),
        );
        return; // 함수 종료
      }

      // 이미지 선택 시, 파일을 읽어서 상태를 갱신합니다.
      setState(() {
        selectedImage = File(pickedFile.path); // 이미지를 선택한 후 상태 갱신
      });

      // 선택된 이미지로 작업을 추가적으로 할 경우 필요한 코드
      final bytes = await pickedFile.readAsBytes();
      print("선택한 이미지의 바이트 크기: ${bytes.length}"); // 디버깅용 출력
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
