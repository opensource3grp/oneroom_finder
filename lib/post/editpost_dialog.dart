import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditPostDialog extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> post;

  const EditPostDialog({Key? key, required this.postId, required this.post})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController =
        TextEditingController(text: post['title'] ?? '');
    final TextEditingController contentController =
        TextEditingController(text: post['content'] ?? '');
    String? type = post['type'] ?? '월세';
    String? roomType = post['roomType'] ?? '원룸';
    String? currentImageUrl = post['imageUrl'];
    File? newImage;
    final String authorId = post['authorId'] ?? ''; // 게시글 작성자 ID
    final String? currentUserId =
        FirebaseAuth.instance.currentUser?.uid; // 현재 사용자 ID

    return StatefulBuilder(
      builder: (context, setState) {
        final bool isAuthor = currentUserId == authorId;

        return AlertDialog(
          title: const Text('게시글 수정'),
          content: isAuthor
              ? SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: '제목'),
                      ),
                      const SizedBox(height: 8.0),
                      TextField(
                        controller: contentController,
                        decoration: const InputDecoration(labelText: '내용'),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 8.0),
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
                      const SizedBox(height: 8.0),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '타입 선택',
                          border: OutlineInputBorder(),
                        ),
                        value: roomType,
                        items: ['원룸', '투룸', '쓰리룸']
                            .map((item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            roomType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8.0),
                      TextButton(
                        onPressed: () async {
                          final pickedFile = await ImagePicker()
                              .pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setState(() {
                              newImage = File(pickedFile.path);
                            });
                          }
                        },
                        child: const Text('사진 변경'),
                      ),
                      if (newImage != null)
                        Image.file(newImage!, height: 100)
                      else if (currentImageUrl != null)
                        Image.network(currentImageUrl, height: 100),
                    ],
                  ),
                )
              : const Text('이 게시글을 수정할 권한이 없습니다.'),
          actions: isAuthor
              ? [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final newTitle = titleController.text;
                      final newContent = contentController.text;

                      if (newTitle.isNotEmpty && newContent.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection('posts')
                            .doc(postId)
                            .update({
                          'title': newTitle,
                          'content': newContent,
                          'type': type,
                          'roomType': roomType,
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('게시글이 수정되었습니다.')),
                        );
                        Navigator.of(context).pop(); // 다이얼로그 닫기
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
                        );
                      }
                    },
                    child: const Text('수정'),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('확인'),
                  ),
                ],
        );
      },
    );
  }
}
