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

    private static final String CHANNEL_NAME = "bnk_naver_map_channel";
    private static final String TAG = "NaverMapPlatformView";

    private final MapView mapView;
    private final MethodChannel channel;
    private NaverMap naverMap;

    private final List<Marker> currentMarkers = new ArrayList<>();

    // 지도 준비 전 보관용
    private final List<Map<String, Object>> pendingMarkers = new ArrayList<>();
    private boolean pendingFitBounds = false;
    private int pendingPadding = 60;

    public NaverMapPlatformView(Context context, BinaryMessenger messenger) {
        mapView = new MapView(context, new NaverMapOptions());
        mapView.onCreate(null);
        mapView.onResume();

        channel = new MethodChannel(messenger, CHANNEL_NAME);
        channel.setMethodCallHandler(this);

        mapView.getMapAsync(map -> {
            naverMap = map;

            // ① 강한 증거: 토스트
            android.widget.Toast.makeText(mapView.getContext(), "NaverMapPlatformView onMapReady()", android.widget.Toast.LENGTH_LONG).show();



            // ✅ Flutter에 지도 준비 완료 이벤트 송신
            channel.invokeMethod("onMapReady", null);

            // 지도 준비 전에 들어온 setMarkers 요청 반영
            if (!pendingMarkers.isEmpty()) {
                setMarkersInternal(pendingMarkers, pendingFitBounds, pendingPadding);
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
        android.widget.Toast.makeText(mapView.getContext(), "call="+call.method, android.widget.Toast.LENGTH_SHORT).show();

        switch (call.method) {
            case "setMarkers": {
                @SuppressWarnings("unchecked")
                Map<String, Object> args = (Map<String, Object>) call.arguments;
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> markers = (List<Map<String, Object>>) args.get("markers");

                boolean fitBounds = args.get("fitBounds") != null && (boolean) args.get("fitBounds");
                int padding = 60;
                if (args.get("padding") instanceof Number) {
                    padding = ((Number) args.get("padding")).intValue();
                }

                if (markers == null) { result.success(null); return; }

                if (naverMap == null) {
                    // 지도 준비 전이면 보관
                    pendingMarkers.clear();
                    if (markers != null) pendingMarkers.addAll(markers);
                    pendingFitBounds = fitBounds;
                    pendingPadding = padding;
                    result.success(null);
                    return;
                }

                setMarkersInternal(markers, fitBounds, padding);
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
                double lat = toDouble(args.get("lat"), Double.NaN);
                double lng = toDouble(args.get("lng"), Double.NaN);
                float zoom = args.get("zoom") != null ? ((Number) args.get("zoom")).floatValue() : 16f;
                boolean animate = args.get("animate") != null && (boolean) args.get("animate");

                if (!isValidCoord(lat, lng)) {
                    result.success(null);
                    return;
                }

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
                int included = 0;
                for (Map<String, Object> p : points) {
                    double lat = toDouble(p.get("lat"), toDouble(p.get("latitude"), Double.NaN));
                    double lng = toDouble(p.get("lng"), toDouble(p.get("longitude"), Double.NaN));
                    if (!isValidCoord(lat, lng)) continue;
                    b.include(new LatLng(lat, lng));
                    included++;
                }
                if (included > 0) {
                    CameraUpdate cu = CameraUpdate.fitBounds(b.build(), padding);
                    naverMap.moveCamera(cu);
                }

                result.success(null);
                break;
            }

            default:
                result.notImplemented();
        }
    }

    // 마커 생성 + (옵션) 전체 보기
    private void setMarkersInternal(List<Map<String, Object>> markers, boolean fitBounds, int padding) {
        // 기존 마커 제거
        for (Marker m : currentMarkers) m.setMap(null);
        currentMarkers.clear();

        if (markers == null || markers.isEmpty()) {
            android.util.Log.d(TAG, "markers applied=0");
            return;
        }

        LatLngBounds.Builder bounds = new LatLngBounds.Builder();
        int count = 0;

        for (Map<String, Object> item : markers) {
            double lat = toDouble(item.get("lat"), toDouble(item.get("latitude"), Double.NaN));
            double lng = toDouble(item.get("lng"), toDouble(item.get("longitude"), Double.NaN));
            if (!isValidCoord(lat, lng)) continue;

            Marker mk = new Marker();
            mk.setPosition(new LatLng(lat, lng));
            mk.setCaptionText(getString(item.get("title"), getString(item.get("branchName"), "")));
            mk.setSubCaptionText(getString(item.get("snippet"), ""));
            mk.setMap(naverMap);
            currentMarkers.add(mk);

            if (fitBounds) bounds.include(new LatLng(lat, lng));
            count++;
        }

        // ✅ 하드코딩 테스트 마커 추가
        Marker testMk = new Marker();
        testMk.setPosition(new LatLng(36.1796, 129.0756)); // 부산 시청 근처
        testMk.setCaptionText("테스트 마커");
        testMk.setSubCaptionText("하드코딩 예시");
        testMk.setMap(naverMap);
        currentMarkers.add(testMk);
        if (fitBounds) bounds.include(new LatLng(36.1796, 129.0756));
        count++;


        android.util.Log.d(TAG, "markers applied=" + count);

        if (fitBounds && count > 0) {
            CameraUpdate cu = CameraUpdate.fitBounds(bounds.build(), padding);
            naverMap.moveCamera(cu);
        }
    }

    // ───────────────────────────
    // 유틸
    // ───────────────────────────
    private static boolean isValidCoord(double lat, double lng) {
        if (Double.isNaN(lat) || Double.isNaN(lng)) return false;
        if (lat == 0.0 && lng == 0.0) return false; // (0,0) 방지
        if (lat < -90 || lat > 90) return false;
        if (lng < -180 || lng > 180) return false;
        return true;
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
