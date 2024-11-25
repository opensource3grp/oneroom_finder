import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'post_service.dart';

class PostCreateScreen extends StatefulWidget {
  final PostService postService; // PostService 인스턴스

  const PostCreateScreen({super.key, required this.postService});

  @override
  // ignore: library_private_types_in_public_api
  _PostCreateScreenState createState() => _PostCreateScreenState();
}

class _PostCreateScreenState extends State<PostCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  String selectedTag = '삽니다';
  final List<String> tags = ['삽니다', '팝니다'];

  String selectedRoomType = '원룸';
  final List<String> roomTypes = ['원룸', '투룸', '쓰리룸'];

  String selectedDealType = '월세';
  final List<String> dealTypes = ['월세', '전세'];

  File? selectedImage;
  final ImagePicker picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게시글 작성'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
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
            const Text(
              '타입 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: selectedRoomType,
              items: roomTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRoomType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              '거래 유형 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: selectedDealType,
              items: dealTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDealType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            _buildTextField('제목', _titleController),
            const SizedBox(height: 16),
            _buildTextField('위치', _locationController),
            const SizedBox(height: 16),
            _buildTextField('가격', _priceController, TextInputType.number),
            const SizedBox(height: 16),
            TextField(
              controller: _detailController,
              decoration: const InputDecoration(
                labelText: '상세 내용',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final pickedFile =
                    await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    selectedImage = File(pickedFile.path);
                  });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('사진 추가'),
            ),
            if (selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.file(selectedImage!),
              ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final title = _titleController.text.trim();
                  final location = _locationController.text.trim();
                  final price = _priceController.text.trim();
                  final detail = _detailController.text.trim();

                  if (title.isEmpty ||
                      location.isEmpty ||
                      price.isEmpty ||
                      detail.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('모든 필드를 입력해주세요.')),
                    );
                    return;
                  }

                  await widget.postService.createPost(
                    title,
                    detail,
                    tag: selectedTag,
                    location: location,
                    price: price,
                    roomType: selectedRoomType,
                    dealType: selectedDealType,
                    image: selectedImage,
                  );

                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('게시글이 작성되었습니다.')),
                  );

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
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      [TextInputType keyboardType = TextInputType.text]) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _detailController.dispose();
    super.dispose();
  }
}
