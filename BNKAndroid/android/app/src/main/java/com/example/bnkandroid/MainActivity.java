package com.example.bnkandroid;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterFragmentActivity; // ← 변경 포인트
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterFragmentActivity {

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        super.configureFlutterEngine(flutterEngine);

        // ✅ PlatformView 팩토리만 등록하고, 채널/마커 데이터 관리는 전부 플랫폼뷰에서 수행
        flutterEngine
                .getPlatformViewsController()
                .getRegistry()
                .registerViewFactory(
                        "bnk_naver_map_view",
                        new NaverMapFactory(flutterEngine.getDartExecutor().getBinaryMessenger())
                );
    }
}
