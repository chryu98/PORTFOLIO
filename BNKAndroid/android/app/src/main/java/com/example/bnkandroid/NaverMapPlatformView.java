package com.example.bnkandroid;

import android.content.Context;
import android.view.View;

import io.flutter.plugin.platform.PlatformView;

import com.naver.maps.geometry.LatLng;
import com.naver.maps.map.CameraUpdate;
import com.naver.maps.map.CameraAnimation;
import com.naver.maps.map.MapView;
import com.naver.maps.map.NaverMap;
import com.naver.maps.map.NaverMapOptions;
import com.naver.maps.map.OnMapReadyCallback;

public class NaverMapPlatformView implements PlatformView {

    private final MapView mapView;

    public NaverMapPlatformView(Context context) {
        mapView = new MapView(context, new NaverMapOptions());
        mapView.onCreate(null);
        mapView.onResume();

        // ✅ 지도 로드 완료 시 부산으로 카메라 이동
        mapView.getMapAsync(new OnMapReadyCallback() {
            @Override
            public void onMapReady(NaverMap naverMap) {
                LatLng busan = new LatLng(35.1796, 129.0756);
                CameraUpdate cameraUpdate = CameraUpdate.scrollAndZoomTo(busan, 14.0)
                        .animate(CameraAnimation.Fly);
                naverMap.moveCamera(cameraUpdate);
            }
        });
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
