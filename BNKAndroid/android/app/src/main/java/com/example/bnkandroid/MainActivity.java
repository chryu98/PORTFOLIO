package com.example.bnkandroid;

import android.util.Log;
import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.bnkandroid/naver_map";
    private static List<Map<String, Object>> markerDataList = new ArrayList<>();

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        flutterEngine.getPlatformViewsController()
                .getRegistry()
                .registerViewFactory("naver_map_view", new NaverMapFactory());

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("setMarkers")) {
                        List<Map<String, Object>> branches = call.argument("branches");

                        // ✅ 로그 추가
                        Log.d("MainActivity", "Received branches from Flutter: " + branches);


                        markerDataList.clear();
                        markerDataList.addAll(branches);
                        result.success(null);
                    } else {
                        result.notImplemented();
                    }
                });
    }

    public static List<Map<String, Object>> getMarkerDataList() {
        return markerDataList;
    }
}
