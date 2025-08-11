package com.example.bnkandroid;

import android.content.Context;
import android.util.Log;
import android.view.View;

import androidx.annotation.NonNull;

import com.naver.maps.geometry.LatLng;
import com.naver.maps.geometry.LatLngBounds;
import com.naver.maps.map.CameraAnimation;
import com.naver.maps.map.CameraUpdate;
import com.naver.maps.map.MapView;
import com.naver.maps.map.NaverMap;
import com.naver.maps.map.NaverMapOptions;
import com.naver.maps.map.OnMapReadyCallback;
import com.naver.maps.map.overlay.Marker;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class NaverMapPlatformView implements PlatformView, MethodChannel.MethodCallHandler, OnMapReadyCallback {

    private static final String CHANNEL = "com.example.bnkandroid/naver_map";

    private final MapView mapView;
    private final MethodChannel channel;
    private NaverMap naverMap;

    // onMapReady 전에 들어온 데이터 임시 저장
    private final List<Map<String, Object>> pendingMarkers = new ArrayList<>();

    // ✅ 팩토리에서 호출하는 생성자와 정확히 맞춤!
    public NaverMapPlatformView(Context context, BinaryMessenger messenger, int id) {
        mapView = new MapView(context, new NaverMapOptions());
        mapView.onCreate(null);
        mapView.onStart();
        mapView.onResume();
        mapView.getMapAsync(this);

        channel = new MethodChannel(messenger, CHANNEL);
        channel.setMethodCallHandler(this);
    }

    @Override
    public View getView() { return mapView; }

    @Override
    public void dispose() {
        channel.setMethodCallHandler(null);
        mapView.onPause();
        mapView.onStop();
        mapView.onDestroy();
    }

    @Override
    public void onMapReady(@NonNull NaverMap map) {
        this.naverMap = map;
        Log.d("NaverMapView", "✅ onMapReady called");

        LatLng busan = new LatLng(35.1796, 129.0756);
        naverMap.moveCamera(CameraUpdate.scrollAndZoomTo(busan, 14.0));

        // ★ 하드코딩 마커
        Marker test = new Marker();
        test.setPosition(busan);
        test.setCaptionText("TEST");
        test.setMap(naverMap);
        Log.d("NaverMapView", "✅ hardcoded marker set, map? " + (test.getMap() != null));
    }

    @Override
    public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if ("setMarkers".equals(call.method)) {
            Map<String, Object> args = (Map<String, Object>) call.arguments;

            List<Map<String, Object>> incoming =
                    (List<Map<String, Object>>) args.get("markers");
            if (incoming == null) {
                incoming = (List<Map<String, Object>>) args.get("branches");
            }

            if (incoming == null) {
                result.error("NO_MARKERS", "markers/branches not found", null);
                return;
            }

            if (naverMap == null) {
                pendingMarkers.clear();
                pendingMarkers.addAll(incoming);
            } else {
                applyMarkers(incoming);
            }
            result.success(null);
        } else {
            result.notImplemented();
        }
    }

    private void applyMarkers(List<Map<String, Object>> markers) {
        if (naverMap == null || markers == null || markers.isEmpty()) return;

        LatLngBounds.Builder bounds = new LatLngBounds.Builder();
        int placed = 0;

        for (Map<String, Object> data : markers) {
            Double lat = toDouble(data.get("lat"));
            if (lat == null) lat = toDouble(data.get("latitude"));
            Double lng = toDouble(data.get("lng"));
            if (lng == null) lng = toDouble(data.get("longitude"));

            if (lat == null || lng == null) {
                Log.w("NaverMapView", "Skipping (no lat/lng): " + data);
                continue;
            }

            String name = "";
            if (data.get("name") != null) name = String.valueOf(data.get("name"));
            else if (data.get("branchName") != null) name = String.valueOf(data.get("branchName"));

            LatLng pos = new LatLng(lat, lng);
            Marker marker = new Marker();
            marker.setPosition(pos);
            marker.setCaptionText(name);
            marker.setMap(naverMap);

            bounds.include(pos);
            placed++;
        }

        if (placed == 0) return;

        if (placed == 1) {
            naverMap.moveCamera(CameraUpdate.scrollTo(bounds.build().getCenter()));
        } else {
            try {
                naverMap.moveCamera(
                        CameraUpdate.fitBounds(bounds.build()).animate(CameraAnimation.Easing)
                );
            } catch (IllegalStateException e) {
                naverMap.moveCamera(CameraUpdate.scrollTo(bounds.build().getCenter()));
            }
        }
    }

    private Double toDouble(Object v) {
        if (v == null) return null;
        if (v instanceof Number) return ((Number) v).doubleValue();
        if (v instanceof String) {
            try { return Double.parseDouble((String) v); } catch (NumberFormatException ignore) {}
        }
        return null;
    }
}
