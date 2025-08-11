package com.example.bnkandroid;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterActivity {
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        flutterEngine
                .getPlatformViewsController()
                .getRegistry()
                .registerViewFactory(
                        "naver_map_view", // Flutter의 AndroidView(viewType)와 동일
                        new NaverMapFactory(
                                this,
                                flutterEngine.getDartExecutor().getBinaryMessenger()
                        )
                );

        // MethodChannel은 NaverMapPlatformView에서 직접 받습니다.
    }
}
