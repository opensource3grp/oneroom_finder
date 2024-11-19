import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostService {
  //게시글 작성 기능
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  Future<void> createPost(String title, String content,
      {required String tag}) async {
    //JSON형태로도 전달 가능하다.
    await firestore.collection('posts').add({
      'title': title,
      'content': content,
      'likes': 0,
      'review': 0,
      'userId': FirebaseAuth.instance.currentUser?.uid,
      'createAt': FieldValue.serverTimestamp(),
    });
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
