import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:oneroom_finder/home_screen.dart';
import 'package:oneroom_finder/post/room_details_screen.dart';
import 'package:oneroom_finder/user_service/auth_service.dart';

class PostService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final AuthService authService = AuthService(); // AuthService 인스턴스 생성

  // Firestore에서 좋아요 추가
  Future<int> likePost(
      String postId, String userId, BuildContext context) async {
    final postRef = firestore.collection('posts').doc(postId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) {
        throw Exception("게시물이 존재하지 않습니다.");
      }

      final data = snapshot.data()!;
      final likes = data['likes'] ?? 0;
      final likedUsers = List<String>.from(data['likedUsers'] ?? []);

      if (!likedUsers.contains(userId)) {
        likedUsers.add(userId);
        transaction.update(postRef, {
          'likes': likes + 1,
          'likedUsers': likedUsers,
        });
      }
    });

    final updatedPost = await postRef.get();
    return updatedPost.data()?['likes'] ?? 0;
  }

  // Firestore에서 좋아요 취소
  Future<int> unlikePost(
      String postId, String userId, BuildContext context) async {
    final postRef = firestore.collection('posts').doc(postId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(postRef);
      if (!snapshot.exists) {
        throw Exception("게시물이 존재하지 않습니다.");
      }

      final data = snapshot.data()!;
      final likes = data['likes'] ?? 0;
      final likedUsers = List<String>.from(data['likedUsers'] ?? []);

      if (likedUsers.contains(userId)) {
        likedUsers.remove(userId);
        transaction.update(postRef, {
          'likes': likes - 1,
          'likedUsers': likedUsers,
        });
      }
    });

    final updatedPost = await postRef.get();
    return updatedPost.data()?['likes'] ?? 0;
  }

  Future<void> updatePostLikes(String postId, int updatedLikes) async {
    try {
      final postRef = firestore.collection('posts').doc(postId);
      await postRef.update({
        'likes': updatedLikes,
      });
    } catch (e) {
      throw Exception('게시글 좋아요 업데이트 중 오류 발생: $e');
    }
  }

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
      final authorId = postData['authorId']; // authorId 포함
      final createAt = postData['createAt'] ??
          Timestamp.now(); // Firestore에서 createAt 값 가져오기, 없으면 현재 시간 사용

      // 반환할 데이터에 authorId 포함
      return {
        'title': postData['title'],
        'content': postData['content'],
        'likes': postData['likes'] ?? 0, // 기본값 설정
        'review': postData['review'] ?? 0, // 기본값 설정
        'authorId': authorId, // authorId 추가
        'image': postData['image'],
        'type': postData['type'],
        'roomType': postData['roomType'],
        'location': postData['location'],
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

      // 데이터를 가져온 후 RoomDetailsScreen으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomDetailsScreen(postId: postId),
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
  Future<void> updatePost(String postId, String title, String content,
      String? type, String? roomType, dynamic image, String? location) async {
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
        'location': location,
      };
      if (imageUrl != null) {
        updateData['image'] = imageUrl; // 새 이미지 URL 추가
      }

      await postRef.update(updateData);
    } catch (e) {
      throw '게시글 수정 중 오류 발생: $e';
    }
  }

  Future<void> deletePost(BuildContext context, String postId) async {
    try {
      // 현재 로그인한 사용자 확인
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('로그인 상태를 확인해주세요.');
      }

      // 삭제할 게시글 가져오기
      final postDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (!postDoc.exists) {
        throw Exception('게시글이 존재하지 않습니다.');
      }

      // 게시글 작성자 확인
      final postUserId = postDoc['userId'] as String? ?? '';
      if (currentUser.uid != postUserId) {
        throw Exception('삭제 권한이 없습니다.');
      }

      // Firestore에서 게시글 삭제
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();

      // 로그 및 사용자 피드백
      developer.log('게시글 삭제 성공: $postId');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글이 성공적으로 삭제되었습니다.')),
      );

      // 이전 화면으로 돌아가기
      if (context.mounted) {
        Navigator.pop(context); // 이전 화면으로 돌아감
      }
    } catch (e) {
      // 에러 로그 및 사용자 피드백
      developer.log('게시글 삭제 실패: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시글 삭제 중 오류 발생: $e')),
      );
    }
  }

  // 좋아요 기능
  Future<void> incrementLikes(String postId) async {
    try {
      final postRef = firestore.collection('posts').doc(postId);

      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(postRef);

        if (!snapshot.exists) return;

        final currentLikes = snapshot.data()?['likes'] ?? 0;
        transaction.update(postRef, {'likes': currentLikes + 1});
      });
    } catch (e) {
      debugPrint('Error updating likes: $e');
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

  // 좋아요 토글 (계정당 1번 제한)
  Future<int> toggleLike(
      String postId, String userId, BuildContext context) async {
    try {
      final postRef =
          FirebaseFirestore.instance.collection('posts').doc(postId);

      // Firestore 트랜잭션으로 좋아요 상태를 안전하게 변경
      final newLikes =
          await FirebaseFirestore.instance.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);

        if (!postSnapshot.exists) {
          throw Exception('게시물이 존재하지 않습니다.');
        }

        final postData = postSnapshot.data() as Map<String, dynamic>;
        final likesCount = postData['likesCount'] ?? 0;
        final likedBy = List<String>.from(postData['likedBy'] ?? []);

        if (likedBy.contains(userId)) {
          // 좋아요 취소
          likedBy.remove(userId);
          transaction.update(postRef, {
            'likesCount': likesCount - 1,
            'likedBy': likedBy,
          });
          return likesCount - 1;
        } else {
          // 좋아요 추가
          likedBy.add(userId);
          transaction.update(postRef, {
            'likesCount': likesCount + 1,
            'likedBy': likedBy,
          });
          return likesCount + 1;
        }
      });

      return newLikes;
    } catch (e) {
      throw Exception('좋아요 처리 중 오류 발생: $e');
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
