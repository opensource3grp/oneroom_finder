import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;

  // 게시글 작성 기능
  Future<void> createPost(
    BuildContext context,
    String roominfo,
    String content, {
    required String tag,
    File? image,
    String? type, // 거래 유형
    String? roomType, // 타입 선택 (원룸, 투룸, 쓰리룸)
  }) async {
    if (roominfo.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
      );
      return;
    }

    String? imageUrl;

    // 이미지가 있을 경우 Firebase Storage에 업로드
    if (image != null) {
      try {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = storage.ref('post_images/$fileName');
        await ref.putFile(image); // 이미지 업로드
        imageUrl = await ref.getDownloadURL(); // 업로드된 이미지의 URL 가져오기
      } catch (e) {
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('이미지 업로드 실패'),
            content: Text('오류 메시지: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), // 팝업 닫기
                child: const Text('확인'),
              ),
            ],
          ),
        );
        imageUrl = null; // 이미지 업로드 실패 시 null 처리
      }
    }

    // Firestore에 게시글 저장
    try {
      await firestore.collection('posts').add({
        'tag': tag,
        'title': roominfo,
        'content': content,
        'likes': 0,
        'review': 0,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'createAt': FieldValue.serverTimestamp(),
        'image': imageUrl, // 이미지 URL 저장
        'type': type, // 거래 유형 저장
        'roomType': roomType, // 타입 저장
      });

      // 성공적으로 게시글 작성 후 UI 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 작성되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 작성 중 오류 발생: $e')),
      );
    }
  }

  // 게시글 조회 기능
  Stream<QuerySnapshot> getPosts() {
    return firestore
        .collection('posts')
        .orderBy('createAt', descending: true)
        .snapshots();
  }

  // 게시글 수정 기능
  Future<void> updatePost(String postId, String title, String content,
      String? type, String? roomType, dynamic image) async {
    try {
      DocumentReference postRef = firestore.collection('posts').doc(postId);

      // 해당 postId가 있는지 확인
      DocumentSnapshot postSnapshot = await postRef.get();
      if (!postSnapshot.exists) {
        throw '게시글이 존재하지 않습니다.';
      }
      String? imageUrl;
      if (image != null) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = storage.ref('post_images/$fileName');

        if (image is File) {
          // 모바일에서 File 객체로 업로드
          await ref.putFile(image);
        } else if (image is Uint8List) {
          // 웹에서 Uint8List로 업로드
          await ref.putData(image);
        }

        imageUrl = await ref.getDownloadURL();
      }

      // 게시글 업데이트
      final updateData = {
        'title': title,
        'content': content,
        'updateAt': FieldValue.serverTimestamp(),
        'type': type,
        'roomType': roomType,
      };
      if (imageUrl != null) {
        updateData['image'] = imageUrl; // 새 이미지 URL 추가
      }

      await postRef.update(updateData);
    } catch (e) {
      throw '게시글 수정 중 오류 발생: $e';
    }
  }

  // 게시글 삭제 기능
  Future<void> deletePost(String postId) async {
    await firestore.collection('posts').doc(postId).delete();
  }

  incrementReviewCount(String postId) {}
  //북마크
  /*
  Future<void> likePost(String postId) async {
    final prefs = await DocumentReference.getInstance()
  }
  */
}
