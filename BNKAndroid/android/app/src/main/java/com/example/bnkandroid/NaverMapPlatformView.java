package com.example.bnkandroid;

import android.content.Context;
import android.util.Log;
import android.view.View;

import com.naver.maps.geometry.LatLng;
import com.naver.maps.map.CameraAnimation;
import com.naver.maps.map.CameraUpdate;
import com.naver.maps.map.MapView;
import com.naver.maps.map.NaverMap;
import com.naver.maps.map.NaverMapOptions;
import com.naver.maps.map.OnMapReadyCallback;
import com.naver.maps.map.overlay.Marker;

import java.util.List;
import java.util.Map;

import io.flutter.plugin.platform.PlatformView;


public class NaverMapPlatformView implements PlatformView {

    private final MapView mapView;

    public NaverMapPlatformView(Context context) {
        mapView = new MapView(context, new NaverMapOptions());
        mapView.onCreate(null);
        mapView.onResume();

        mapView.getMapAsync(new OnMapReadyCallback() {
            @Override
            public void onMapReady(NaverMap naverMap) {
                LatLng busan = new LatLng(35.1796, 129.0756);
                CameraUpdate cameraUpdate = CameraUpdate.scrollAndZoomTo(busan, 14.0)
                        .animate(CameraAnimation.Fly);
                naverMap.moveCamera(cameraUpdate);

                // ✅ MainActivity에서 전달받은 마커 데이터를 표시
                List<Map<String, Object>> markerDataList = MainActivity.getMarkerDataList();

                if (markerDataList == null) {
                    Log.e("NaverMapView", "markerDataList is null");
                } else {
                    Log.d("NaverMapView", "Loaded marker list: " + markerDataList.size());
                }

                for (Map<String, Object> data : markerDataList) {
                    double lat = (double) data.get("latitude");
                    double lng = (double) data.get("longitude");
                    String branchName = (String) data.get("branchName");

                    Marker marker = new Marker();
                    marker.setPosition(new LatLng(lat, lng));
                    marker.setCaptionText(branchName);
                    marker.setMap(naverMap);
                }
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
