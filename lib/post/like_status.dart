import 'package:flutter/material.dart';
import 'package:oneroom_finder/post/post_service.dart';

class LikeStatus with ChangeNotifier {
  int _likes = 0;
  bool _isLiked = false;

  int get likes => _likes;
  bool get isLiked => _isLiked;

  // 초기 값 설정
  void setInitialStatus(int initialLikes, bool initialIsLiked) {
    _likes = initialLikes;
    _isLiked = initialIsLiked;
    notifyListeners();
  }

  // 좋아요 상태를 설정하는 메서드
  void setLikeStatus(int likes, bool isLiked) {
    _likes = likes;
    _isLiked = isLiked;
    notifyListeners(); // 상태 변경을 UI에 알려줌
  }

// 좋아요 토글
  Future<int> toggleLike(
      String postId, String userId, BuildContext context) async {
    try {
      // Firestore에서 좋아요 토글
      final postService = PostService();

      // 현재 좋아요 상태에 따라 Firestore를 업데이트
      if (_isLiked) {
        // 좋아요 취소
        final newLikes = await postService.unlikePost(postId, userId, context);
        _isLiked = false; // 상태 변경
        _likes = newLikes; // 좋아요 수 업데이트
      } else {
        // 좋아요 추가
        final newLikes = await postService.likePost(postId, userId, context);
        _isLiked = true; // 상태 변경
        _likes = newLikes; // 좋아요 수 업데이트
      }

      notifyListeners(); // 상태 변경 알림
      return _likes; // 새 좋아요 수 반환
    } catch (e) {
      // 에러 처리
      throw Exception('좋아요 처리 실패: $e');
    }
  }

  // 좋아요 수 업데이트
  void updateLikes(int newLikes) {
    _likes = newLikes;
    notifyListeners();
  }
}
