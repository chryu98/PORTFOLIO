package com.example.bnkandroid;

import android.content.Context;
import android.graphics.PointF;
import android.view.View;

import androidx.annotation.NonNull;

import com.naver.maps.geometry.LatLng;
import com.naver.maps.geometry.LatLngBounds;
import com.naver.maps.map.CameraAnimation;
import com.naver.maps.map.CameraUpdate;
import com.naver.maps.map.MapView;
import com.naver.maps.map.NaverMap;
import com.naver.maps.map.NaverMapOptions;
import com.naver.maps.map.overlay.Marker;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class NaverMapPlatformView implements PlatformView, MethodChannel.MethodCallHandler {

    private static final String CHANNEL_NAME = "naver_map_channel";

    private final MapView mapView;
    private final MethodChannel channel;
    private NaverMap naverMap;

    private final List<Marker> currentMarkers = new ArrayList<>();
    private final List<Map<String, Object>> pendingMarkers = new ArrayList<>();

    public NaverMapPlatformView(Context context, BinaryMessenger messenger) {
        mapView = new MapView(context, new NaverMapOptions());
        mapView.onCreate(null);
        mapView.onResume();

        channel = new MethodChannel(messenger, CHANNEL_NAME);
        channel.setMethodCallHandler(this);

        mapView.getMapAsync(map -> {
            naverMap = map;
            // ✅ Flutter에 지도 준비 완료 이벤트 송신
            channel.invokeMethod("onMapReady", null);

            // 지도 준비 전에 들어온 setMarkers 요청이 있으면 여기서 반영
            if (!pendingMarkers.isEmpty()) {
                setMarkersInternal(pendingMarkers);
                pendingMarkers.clear();
            }
        });
    }

    @NonNull @Override
    public View getView() {
        return mapView;
    }

    @Override
    public void dispose() {
        channel.setMethodCallHandler(null);
        for (Marker m : currentMarkers) m.setMap(null);
        currentMarkers.clear();
        mapView.onPause();
        mapView.onDestroy();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        android.util.Log.d(TAG, "onMethodCall: " + call.method);
        switch (call.method) {
            case "setMarkers": {
                // args: { "markers": [ {"lat":..,"lng":..,"title":..,"snippet":..}, ... ] }
                @SuppressWarnings("unchecked")
                Map<String, Object> args = (Map<String, Object>) call.arguments;
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> markers = (List<Map<String, Object>>) args.get("markers");

                if (markers == null) {
                    result.success(null);
                    return;
                }

                if (naverMap == null) {
                    // 지도 준비 전: 대기 큐에 저장
                    pendingMarkers.clear();
                    pendingMarkers.addAll(markers);
                    result.success(null);
                    return;
                }

                setMarkersInternal(markers);
                result.success(null);
                break;
            }
            case "moveCamera": {
                if (naverMap == null) {
                    result.error("MAP_NOT_READY", "NaverMap not ready", null);
                    return;
                }
                @SuppressWarnings("unchecked")
                Map<String, Object> args = (Map<String, Object>) call.arguments;
                double lat = toDouble(args.get("lat"), 0);
                double lng = toDouble(args.get("lng"), 0);
                float zoom = args.get("zoom") != null ? ((Number) args.get("zoom")).floatValue() : 16f;
                boolean animate = args.get("animate") != null && (boolean) args.get("animate");

                CameraUpdate cu = CameraUpdate.zoomTo(zoom)
                        .animate(animate ? CameraAnimation.Easing : CameraAnimation.None)
                        .pivot(new PointF(0.5f, 0.5f))
                        .scrollTo(new LatLng(lat, lng));
                naverMap.moveCamera(cu);

                result.success(null);
                break;
            }
            case "fitBounds": {
                if (naverMap == null) {
                    result.error("MAP_NOT_READY", "NaverMap not ready", null);
                    return;
                }
                @SuppressWarnings("unchecked")
                Map<String, Object> args = (Map<String, Object>) call.arguments;
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> points = (List<Map<String, Object>>) args.get("points");
                int padding = args.get("padding") != null ? ((Number) args.get("padding")).intValue() : 80;

                if (points == null || points.isEmpty()) {
                    result.success(null);
                    return;
                }

                LatLngBounds.Builder b = new LatLngBounds.Builder();
                for (Map<String, Object> p : points) {
                    double lat = toDouble(p.get("lat"), toDouble(p.get("latitude"), 0));
                    double lng = toDouble(p.get("lng"), toDouble(p.get("longitude"), 0));
                    b.include(new LatLng(lat, lng));
                }
                CameraUpdate cu = CameraUpdate.fitBounds(b.build(), padding);
                naverMap.moveCamera(cu);

                result.success(null);
                break;
            }
            default:
                result.notImplemented();
        }
    }

    private void setMarkersInternal(List<Map<String, Object>> markers) {
        // 기존 마커 제거
        for (Marker m : currentMarkers) m.setMap(null);
        currentMarkers.clear();

        for (Map<String, Object> item : markers) {
            // ✅ 키 호환: lat/lng 또는 latitude/longitude 모두 지원
            double lat = toDouble(item.get("lat"), toDouble(item.get("latitude"), 0));
            double lng = toDouble(item.get("lng"), toDouble(item.get("longitude"), 0));
            String title = getString(item.get("title"), getString(item.get("branchName"), ""));
            String snippet = getString(item.get("snippet"), "");

            Marker mk = new Marker();
            mk.setPosition(new LatLng(lat, lng));
            mk.setCaptionText(title != null ? title : "");
            mk.setSubCaptionText(snippet != null ? snippet : "");
            mk.setMap(naverMap);
            currentMarkers.add(mk);
        }
        android.util.Log.d(TAG, "markers applied=" + currentMarkers.size());
    }

    private static double toDouble(Object v, double def) {
        if (v == null) return def;
        if (v instanceof Number) return ((Number) v).doubleValue();
        try { return Double.parseDouble(String.valueOf(v)); } catch (Exception ignored) { return def; }
    }

    private static String getString(Object v, String def) {
        return v == null ? def : String.valueOf(v);
    }
}
