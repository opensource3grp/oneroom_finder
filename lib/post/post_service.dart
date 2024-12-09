import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:oneroom_finder/post/room_details_screen.dart';
import 'package:oneroom_finder/post/user_service/auth_service.dart';

//import 'package:oneroom_finder/post/option_icons.dart';

class PostService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final AuthService authService = AuthService(); // AuthService 인스턴스 생성

  Future<String> createPost(
    BuildContext context,
    String roominfo,
    String content, {
    required String tag,
    File? image,
    String? type, // 거래 유형
    String? roomType, // 타입 선택 (원룸, 투룸, 쓰리룸)
    String? location,
    required bool parkingAvailable, // 주차 여부를 bool로 변경
    required bool moveInDate, // 입주 가능 여부를 bool로 변경
    required String floor, //층수
    required String maintenanceFee, // 관리비
    required List<Map<String, dynamic>>? options, // 옵션 리스트
  }) async {
    if (roominfo.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목과 내용을 입력해주세요.')),
      );
      return '';
    }

    String? imageUrl = '';
    final currentUser = await authService.isUserLoggedIn();
    if (!currentUser) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인된 사용자가 없습니다.')),
      );
      return '';
    }
    final String authorId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (authorId.isEmpty) {
      // UID가 null일 때 처리
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 ID를 찾을 수 없습니다.')),
      );
      return '';
    }

    final optionsToSave = options ?? [];

    // 이미지가 선택되었으면 Firebase Storage에 업로드
    if (image != null) {
      try {
        // 이미지를 Firebase Storage에 업로드할 파일 경로 지정
        final storageRef = storage
            .ref()
            .child('post_images/${DateTime.now().millisecondsSinceEpoch}');
        final uploadTask = storageRef.putFile(image);
        await uploadTask.whenComplete(() async {
          imageUrl = await storageRef.getDownloadURL();
          print('이미지 업로드 완료: $imageUrl');
        });
      } catch (e) {
        // 이미지 업로드 중 오류 처리
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 업로드 중 오류 발생: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지가 선택되지 않았습니다.')),
      );
    }

    // Firestore에 게시글 저장
    try {
      final postRef = await firestore.collection('posts').add({
        'tag': tag,
        'title': roominfo,
        'content': content,
        'review': 0,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'authorId': authorId, // authorId 추가
        'createdAt': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl, // 이미지 URL 저장 (이미지가 없으면 null)
        'type': type, // 거래 유형 저장
        'roomType': roomType, // 타입 저장
        'location': location,
        'floor': floor, // 층수
        'maintenanceFee': maintenanceFee, // 관리비
        'parkingAvailable': parkingAvailable, // 수정된 변수 이름
        'moveInDate': moveInDate, // 입주 가능 여부
        'options': optionsToSave,
        'createAt': Timestamp.now(), // createAt이 없으면 현재 시간으로 설정
      });
      // postId 반환
      // 성공적으로 게시글 작성 후 UI 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 작성되었습니다.')),
      );
      return postRef.id;
    } catch (e) {
      // 예외가 발생하면 로그를 출력하거나 적절한 처리 후 기본 값을 반환
      print("게시물 생성 중 오류 발생: $e");
      throw Exception("게시물 생성 실패"); // 예외 처리 또는 사용자에게 알림
      // 혹은, 예외 발생 시 null을 반환하거나, 빈 문자열을 반환할 수도 있음.
      // return ''; // 예를 들어 빈 문자열 반환
    }
  }

  // 게시글 조회 기능
  Stream<QuerySnapshot> getPosts() {
    try {
      return firestore
          .collection('posts')
          .orderBy('createAt', descending: true)
          .snapshots();
    } catch (e) {
      print('Firestore 데이터 스트림 오류: $e');
      return const Stream.empty(); // 오류 발생 시 빈 스트림 반환
    }
  }

  // 게시글 상세 조회 기능
  Future<Map<String, dynamic>?> fetchPostDetails(String postId) async {
    try {
      final postDoc = await firestore.collection('posts').doc(postId).get();

      if (!postDoc.exists) {
        throw Exception('게시글을 찾을 수 없습니다.');
      }

      final postData = postDoc.data() as Map<String, dynamic>;
      final authorId = postData['authorId'] ?? ''; // // authorId 포함
      final createAt = postData['createAt'] ??
          Timestamp.now(); // Firestore에서 createAt 값 가져오기, 없으면 현재 시간 사용

      final options = postData['options'] ?? [];

      // 반환할 데이터에 authorId 포함
      return {
        'title': postData['title'],
        'content': postData['content'],
        'review': postData['review'] ?? 0, // 기본값 설정
        'authorId': authorId,
        'image': postData['image'] ?? '',
        'type': postData['type'] ?? '',
        'roomType': postData['roomType'] ?? '',
        'location': postData['location'] ?? '',
        'floor': postData['floor'] ?? 'N/A', // 기본값 설정
        'maintenanceFee': postData['maintenanceFee'] ?? '0', // 기본값 설정
        'parkingAvailable': postData['parkingAvailable'] ?? false, // bool로 반환
        'moveInDate': postData['moveInDate'] ?? false, // bool로 반환
        'options': options,
        // ignore: equal_keys_in_map
        'createAt': createAt, // createAt 필드 추가
      };
    } catch (e) {
      throw Exception('게시글 상세 조회 중 오류 발생: $e');
    }
  }

  Future<void> fetchAndNavigateToRoomDetails(
      BuildContext context, String postId) async {
    try {
      // 게시글 데이터를 가져옴
      final postDetails = await fetchPostDetails(postId);

      if (postDetails == null) {
        throw Exception('게시글 데이터를 불러오지 못했습니다.');
      }

      // postDetails에서 options를 가져옵니다.
      List<String> selectedOptions = List<String>.from(postDetails['options']
          .map((option) => option['option'])); // 'name'을 옵션 이름으로 가정

      final parkingAvailable = postDetails['parkingAvailable']; // 주차 가능 여부
      final moveInDate = postDetails['moveInDate']; // 입주 가능 여부

      // 데이터를 가져온 후 RoomDetailsScreen으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomDetailsScreen(
            postId: postId,
            selectedOptions: selectedOptions.toList(),
            parkingAvailable: parkingAvailable, // 전달
            moveInDate: moveInDate, // 전달
            //optionIcons: optionIcons,
          ),
        ),
      );
    } catch (e) {
      // 오류 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 상세 조회 중 오류 발생: $e')),
      );
    }
  }

  // 게시글 수정 기능
  Future<void> updatePost(
    String postId,
    String title,
    String content,
    String? type,
    String? roomType,
    dynamic image,
    String? location, {
    required String floor,
    required String maintenanceFee,
    required bool parkingAvailable,
    required bool moveInDate,
    required List<String> options,
  }) async {
    try {
      final postRef = firestore.collection('posts').doc(postId);

      final postSnapshot = await postRef.get();
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
        'location': location,
        'floor': floor, // 새 필드 추가
        'maintenanceFee': maintenanceFee, // 새 필드 추가
        'parkingAvailable': parkingAvailable, // 새 필드 추가
        'moveInDate': moveInDate, // 새 필드 추가
        'options': options, // 새 필드 추가
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
  Future<void> deletePost(BuildContext context, String postId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('로그인 상태를 확인해주세요.');
      }

      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (!postDoc.exists) {
        throw Exception('게시글이 존재하지 않습니다.');
      }

      final postUserId = postDoc['userId'] as String? ?? '';

      if (currentUser.uid != postUserId) {
        throw Exception('삭제 권한이 없습니다.');
      }

      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 삭제 중 오류 발생: $e')),
      );
    }
  }

  //댓글 횟수
  Future<void> incrementComments(String postId) async {
    try {
      final postRef = firestore.collection('posts').doc(postId);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(postRef);

        if (!snapshot.exists) return;

        final currentComments = snapshot.data()?['review'] ?? 0;
        transaction.update(postRef, {'review': currentComments + 1});
      });
    } catch (e) {
      debugPrint('Error updating comments: $e');
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('오류'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // Firestore의 posts 컬렉션에서 특정 게시글의 상태를 변경하는 메서드
  static Future<void> setStatus(String postId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update({'status': newStatus});
    } catch (e) {
      throw Exception('게시글 상태 변경 중 오류 발생: $e');
    }
  }
}
