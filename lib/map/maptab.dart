import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/services.dart' show rootBundle;

class MapService extends StatefulWidget {
  const MapService({super.key});

  @override
  _MapServiceState createState() => _MapServiceState();
}

class _MapServiceState extends State<MapService> {
  final Map<String, dynamic> postCounts = {
    "신평": {"count": 198, "lat": 36.1194, "lng": 128.3445},
    "학교앞": {"count": 81, "lat": 36.1224, "lng": 128.3491},
    "옥계": {"count": 71, "lat": 36.1147, "lng": 128.3578},
  };

  late InAppWebViewController webViewController;
  String htmlData = "";

  @override
  void initState() {
    super.initState();
    _loadHtmlFromAssets();
  }

  Future<void> _loadHtmlFromAssets() async {
    // assets에서 HTML 파일을 로드
    htmlData = await rootBundle.loadString('assets/naver_map.html');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (htmlData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("게시글 지도 시각화"),
        backgroundColor: Colors.orange,
      ),
      body: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: htmlData,
          mimeType: 'text/html',
        ),
        initialUrlRequest: URLRequest(
          url: Uri.parse("file:///oneroom_finder/assets/naver_map.html"),
        ),
        onWebViewCreated: (controller) {
          webViewController = controller;
        },
        onLoadStop: (controller, url) {
          // Dart 데이터를 JS 함수로 전달
          final postCountsJson = jsonEncode(postCounts.entries.map((entry) {
            return {
              "name": entry.key,
              "count": entry.value['count'],
              "lat": entry.value['lat'],
              "lng": entry.value['lng']
            };
          }).toList());

          // JS 함수 initMap에 데이터 전달
          controller.evaluateJavascript(
            source: "initMap($postCountsJson);",
          );
        },
      ),
    );
  }
}
