/*
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_naver_map/flutter_naver_map.dart';

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
  Future<void> _initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await NaverMapSdk.instance.initialize(
      clientId: 'ipsrpo93iw',
      onAuthFailed: (e) => log("네이버앱 인증 오류 : $e", name: "onAuthFailed")
    );
    super.initState();
    _loadHtmlFromAssets();
  }

  Future<void> _loadHtmlFromAssets() async {
    try {
      // assets에서 HTML 파일을 로드
      htmlData = await rootBundle.loadString('assets/naver_map.html');
      setState(() {});
    } catch (e) {
      print('Error loading HTML file: $e');
    }
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
          url: WebUri.uri(Uri.parse(
              "file:///oneroom_finder/assets/oneroom_finder/assets/naver_map.html")),
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
*/
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MapService extends StatefulWidget {
  const MapService({Key? key}) : super(key: key);

  @override
  _MapService createState() => _MapService();
}

class _MapService extends State<MapService> {
  // 지도 초기화 함수
  Future<void> _initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await NaverMapSdk.instance.initialize(
        clientId: 'ipsrpo93iw', // 네이버 클라이언트 ID
        onAuthFailed: (e) => log("네이버맵 인증 오류 : $e", name: "onAuthFailed"));
  }

  @override
  void initState() {
    super.initState();
    // 초기화 작업을 initState에서 호출
    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    final Completer<NaverMapController> mapControllerCompleter = Completer();

    return MaterialApp(
      home: Scaffold(
        body: NaverMap(
          options: const NaverMapViewOptions(
            indoorEnable: true, // 실내 맵 사용 가능 여부 설정
            locationButtonEnable: false, // 위치 버튼 표시 여부 설정
            consumeSymbolTapEvents: false, // 심볼 탭 이벤트 소비 여부 설정
          ),
          onMapReady: (controller) async {
            mapControllerCompleter.complete(controller);
            log("onMapReady", name: "onMapReady");
          },
        ),
      ),
    );
  }
}
