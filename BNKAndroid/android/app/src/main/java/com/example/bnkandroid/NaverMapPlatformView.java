package com.example.bnkandroid;

import android.content.Context;
import android.view.View;

import io.flutter.plugin.platform.PlatformView;

import com.naver.maps.map.MapView;
import com.naver.maps.map.NaverMapOptions;

public class NaverMapPlatformView implements PlatformView {

    private final MapView mapView;

    public NaverMapPlatformView(Context context) {
        mapView = new MapView(context, new NaverMapOptions());
        mapView.onCreate(null);
        mapView.onResume();
    }

    @Override
    public View getView() {
        return mapView;
    }

    @Override
    public void dispose() {
        mapView.onDestroy();
    }
}
