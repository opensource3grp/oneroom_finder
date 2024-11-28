import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 이미지 선택
//import 'dart:io'; // 이미지 파일 관련
import 'post_service.dart'; // PostService import

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
  final List<String> tags = ['삽니다', '팝니다'];
  Uint8List? selectedImage; // 선택된 이미지 파일

  final ImagePicker _picker = ImagePicker();

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
                              child: Image.memory(
                                selectedImage!,
                                fit: BoxFit.cover, // 이미지가 공간을 꽉 채우도록 설정
                              ),
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
                    );

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
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          selectedImage = bytes;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미지를 선택하지 않았습니다.')),
        );
      }
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
