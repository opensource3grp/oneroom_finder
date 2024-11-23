import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PostService {
  //게시글 작성 기능
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  // 수정된 createPost
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
        final ref = storage.ref().child('post_images').child(fileName);
        await ref.putFile(image); // 이미지 업로드
        imageUrl = await ref.getDownloadURL(); // 업로드된 이미지의 URL 가져오기
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드 실패: $e')),
        );
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

      // 게시글 작성 후 화면 닫기
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 작성 중 오류 발생: $e')),
      );
    }
  }

  //게시글 조회 기능
  Stream<QuerySnapshot> getPosts() {
    return firestore
        .collection('posts')
        .orderBy('createAt', descending: true)
        .snapshots();
  }

  //수정
  Future<void> updatePost(String postId, String title, String content) async {
    //해당 postid가 일치한것이 있는가?
    DocumentReference postRef = firestore.collection('posts').doc(postId);

    // 해당 postId가 있는지 확인
    DocumentSnapshot postSnapshot = await postRef.get();
    if (postSnapshot.exists) {
      // postId가 일치하는 문서가 있으면 업데이트
      await postRef.update({
        'title': title,
        'content': content,
      });
    } else {
      // 일치하는 postId가 없을 경우의 처리
      print("Error: 해당 postId의 게시글이 없습니다.");
    }
  }

  //삭제
  Future<void> deletePost(String postId) async {
    await firestore.collection('posts').doc(postId).delete();
  }
  //북마크
  /*
  Future<void> likePost(String postId) async {
    final prefs = await DocumentReference.getInstance()
  }
  */
}
