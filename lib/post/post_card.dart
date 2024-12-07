import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:oneroom_finder/post/post_service.dart';
import 'room_details_screen.dart';

class PostCard extends StatefulWidget {
  final QueryDocumentSnapshot post;
  final String title;
  final String content;
  final String location;
  final String price;
  final String author;
  final String image;
  final int review;
  final String postId;
  final String tag;
  final String status;

  const PostCard({
    super.key,
    required this.post,
    required this.title,
    required this.content,
    required this.location,
    required this.price,
    required this.author,
    required this.image,
    required this.review,
    required this.postId,
    required this.tag,
    required this.status,
  });

  @override
  // ignore: library_private_types_in_public_api
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12.0),
        onTap: () async {
          final updatedData = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomDetailsScreen(
                postId: widget.postId,
              ),
            ),
          );
          // 상세 화면에서 반환된 데이터로 상태 업데이트
          if (updatedData != null) {
            // 좋아요 기능이 제거되어 관련 데이터를 업데이트하지 않습니다.
          }
        },
        leading: widget.image.isNotEmpty
            ? Image.network(
                widget.image,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              )
            : const SizedBox(
                width: 100,
                height: 100,
                child: Icon(Icons.image, color: Colors.grey),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.tag.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  widget.tag,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 4),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.location,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.content,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            // 거래 상태 표시
            Text(
              '상태: ${widget.status == '거래 완료' ? '거래 완료' : widget.status}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.status == '거래 완료' ? Colors.red : Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '후기 ${widget.review}개',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
