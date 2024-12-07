package com.example.oneroom_finder

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugins.GeneratedPluginRegistrant

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 플러그인 자동 등록
        GeneratedPluginRegistrant.registerWith(this)
    }
}
