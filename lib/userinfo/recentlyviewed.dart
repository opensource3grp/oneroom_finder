import 'package:shared_preferences/shared_preferences.dart';

class RecentlyViewedManager {
  static const String key = 'recentlyViewedPosts';

  // 게시글 ID 추가
  static Future<void> addPost(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentPosts = prefs.getStringList(key) ?? [];

    if (!currentPosts.contains(postId)) {
      currentPosts.insert(0, postId); // 최신 항목을 앞에 추가
      if (currentPosts.length > 10) {
        currentPosts.removeLast(); // 10개 초과 시 마지막 항목 제거
      }
      await prefs.setStringList(key, currentPosts);
    }
  }

  // 최근 본 게시글 목록 가져오기
  static Future<List<String>> getPosts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }
}
